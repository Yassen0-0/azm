import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../settings/data/training_settings.dart';
import '../../workout/data/workout_models.dart';
import '../../workout/data/workout_repository.dart';
import 'history_models.dart';

/// Reads the history of FINISHED workouts and makes the few edits the
/// workout feature doesn't offer (rename, delete, log added sets). Set edits of a
/// past workout go through `WorkoutRepository` (same writes as the active
/// workout). Every write guards `status = finished`: the active workout is
/// never touched from here.
class HistoryRepository {
  HistoryRepository(this.db);

  final AppDatabase db;

  /// All finished workouts with their completed sets. Re-emits when any
  /// workout table changes, but only if the finished data actually changed
  /// (ticking sets in the active workout doesn't rebuild the history).
  Stream<HistoryData> watchHistory() => _combineLatest(
        _watchRows().distinct(_sameRows).map(_build),
        _watchCatalog(),
        (HistoryData data, Map<String, Exercise> catalog) => data.withExercises(catalog),
      );

  Stream<List<Map<String, Object?>>> _watchRows() => db
      .customSelect(
        '''
        SELECT w.id AS wid, w.name AS wname, w.started_at AS ws, w.ended_at AS we,
               e.id AS eid, e.exercise_id AS xid,
               s.id AS sid, s.sort AS ssort, s.type AS stype, s.weight_kg AS kg, s.reps AS reps,
               s.completed_at AS sdone
        FROM workouts w
        LEFT JOIN workout_exercises e ON e.workout_id = w.id
        LEFT JOIN workout_sets s ON s.workout_exercise_id = e.id AND s.completed_at IS NOT NULL
        WHERE w.status = 'finished'
        ORDER BY w.started_at, w.id, e.sort, e.id, s.sort
        ''',
        readsFrom: {db.workouts, db.workoutExercises, db.workoutSets},
      )
      .watch()
      .map((rows) => [for (final r in rows) r.data]);

  /// Catalog rows of every exercise used in a workout, as its OWN watched
  /// query. (A follow-up query issued in reaction to the history stream hung
  /// on device after a write transaction; two independent DB streams don't.)
  Stream<Map<String, Exercise>> _watchCatalog() => db
      .customSelect(
        'SELECT x.* FROM exercises x WHERE x.id IN (SELECT DISTINCT exercise_id FROM workout_exercises)',
        readsFrom: {db.exercises, db.workoutExercises},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('id'): db.exercises.map(r.data)})
      .distinct((a, b) => a.length == b.length && a.keys.every(b.containsKey));

  HistoryData _build(List<Map<String, Object?>> rows) {
    final raw = <RawWorkout>[];
    final entries = <String, ({String exerciseId, List<WorkoutSet> sets})>{};
    final dates = db.typeMapping;
    DateTime? date(Object? v) => dates.read(DriftSqlType.dateTime, v);

    for (final r in rows) {
      final wid = r['wid']! as String;
      if (raw.isEmpty || raw.last.id != wid) {
        entries.clear();
        raw.add((
          id: wid,
          name: r['wname']! as String,
          startedAt: date(r['ws'])!,
          endedAt: date(r['we']),
          entries: [],
        ));
      }
      final eid = r['eid'] as String?;
      if (eid == null) continue;
      final entry = entries.putIfAbsent(eid, () {
        final e = (exerciseId: r['xid']! as String, sets: <WorkoutSet>[]);
        raw.last.entries.add(e);
        return e;
      });
      final sid = r['sid'] as String?;
      if (sid == null) continue;
      entry.sets.add(WorkoutSet(
        id: sid,
        prefilled: false,
        workoutExerciseId: eid,
        sort: r['ssort']! as int,
        type: $WorkoutSetsTable.$convertertype.fromSql(r['stype']! as String),
        weightKg: (r['kg']! as num).toDouble(),
        reps: r['reps']! as int,
        completedAt: date(r['sdone']),
      ));
    }
    return computeHistory(raw);
  }

  /// Catalog rows for [ids] (missing ids = exercises that left the catalog).
  Future<Map<String, Exercise>> exercises(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return const {};
    return {for (final e in await (db.select(db.exercises)..where((e) => e.id.isIn(list))).get()) e.id: e};
  }

  Expression<bool> _finished(String workoutId) =>
      db.workouts.id.equals(workoutId) & db.workouts.status.equalsValue(WorkoutStatus.finished);

  Future<Workout?> finishedWorkout(String id) =>
      (db.select(db.workouts)..where((w) => _finished(id))).getSingleOrNull();

  /// Renames a finished workout (blank names are ignored).
  Future<void> rename(String workoutId, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await (db.update(db.workouts)..where((w) => _finished(workoutId))).write(WorkoutsCompanion(name: Value(n)));
  }

  /// Deletes a finished workout and everything in it (FK cascade).
  Future<void> delete(String workoutId) => (db.delete(db.workouts)..where((w) => _finished(workoutId))).go();

  /// Every set of a finished workout is done: sets without ✓ (exercises just
  /// added through the picker, or left by an interrupted edit) are logged at
  /// the workout's end, with empty weight/reps taken from the same set of the
  /// workout before (the ✓ rule, `completionValues`). Nothing is ever removed
  /// here: deleting a set is the user's swipe. Returns the ids it logged.
  Future<List<String>> logUnticked(String workoutId) => db.transaction(() async {
        final w = await finishedWorkout(workoutId);
        if (w == null) return const <String>[];
        final entries = await (db.select(db.workoutExercises)..where((e) => e.workoutId.equals(workoutId))).get();
        if (entries.isEmpty) return const <String>[];
        final unticked = await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.isIn([for (final e in entries) e.id]) & s.completedAt.isNull())
              ..orderBy([(s) => OrderingTerm.asc(s.sort)]))
            .get();
        if (unticked.isEmpty) return const <String>[];
        final exerciseOf = {for (final e in entries) e.id: e.exerciseId};
        final previous = await WorkoutRepository(db)
            .previousSets(exerciseOf.values.toSet().toList(), before: w.startedAt, excludeWorkoutId: w.id);
        final all = await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.isIn([for (final e in entries) e.id]))
              ..orderBy([(s) => OrderingTerm.asc(s.sort)]))
            .get();
        final at = w.endedAt ?? w.startedAt;
        for (final s in unticked) {
          final index = all.where((x) => x.workoutExerciseId == s.workoutExerciseId).toList().indexWhere((x) => x.id == s.id);
          final prev = previous[exerciseOf[s.workoutExerciseId]] ?? const <WorkoutSet>[];
          final v = completionValues(s, index >= 0 && index < prev.length ? prev[index] : null);
          await (db.update(db.workoutSets)..where((x) => x.id.equals(s.id))).write(WorkoutSetsCompanion(
                weightKg: Value(v.weightKg),
                reps: Value(v.reps),
                completedAt: Value(at),
              ));
        }
        return [for (final s in unticked) s.id];
      });

  /// Adds a set to an exercise of a past workout, already ✓ (a finished
  /// workout only holds logged sets), copying the last set's values and type.
  Future<void> addLoggedSet(String workoutExerciseId, DateTime at) => db.transaction(() async {
        final last = await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.equals(workoutExerciseId))
              ..orderBy([(s) => OrderingTerm.desc(s.sort)])
              ..limit(1))
            .getSingleOrNull();
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              sort: Value((last?.sort ?? -1) + 1),
              type: Value(last?.type == SetType.warmup ? SetType.normal : (last?.type ?? SetType.normal)),
              weightKg: Value(last?.weightKg ?? 0),
              reps: Value(last?.reps ?? 0),
              completedAt: Value(at),
            ));
      });
}

/// Emits [combine] of the latest values once both streams have emitted.
Stream<R> _combineLatest<A, B, R>(Stream<A> a, Stream<B> b, R Function(A, B) combine) {
  late StreamController<R> out;
  StreamSubscription<A>? sa;
  StreamSubscription<B>? sb;
  A? va;
  B? vb;
  var hasA = false, hasB = false;
  void emit() {
    if (hasA && hasB) out.add(combine(va as A, vb as B));
  }

  out = StreamController<R>(
    onListen: () {
      sa = a.listen((v) {
        va = v;
        hasA = true;
        emit();
      }, onError: out.addError);
      sb = b.listen((v) {
        vb = v;
        hasB = true;
        emit();
      }, onError: out.addError);
    },
    onPause: () {
      sa?.pause();
      sb?.pause();
    },
    onResume: () {
      sa?.resume();
      sb?.resume();
    },
    onCancel: () async {
      await sa?.cancel();
      await sb?.cancel();
    },
  );
  return out.stream;
}

bool _sameRows(List<Map<String, Object?>> a, List<Map<String, Object?>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!mapEquals(a[i], b[i])) return false;
  }
  return true;
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(appDatabaseProvider)),
);

/// Every finished workout + totals + records.
final historyProvider = StreamProvider<HistoryData>(
  (ref) => ref.watch(historyRepositoryProvider).watchHistory(),
  retry: noRetry,
);


/// Full detail of one past workout (same data as the live workout: previous
/// sets, PRs versus earlier workouts). Unlike the workout feature's
/// `workoutDetailProvider` it is disposed when the screen closes, so opening
/// many past workouts doesn't leave live DB streams behind.
final pastWorkoutDetailProvider = StreamProvider.autoDispose.family<WorkoutDetail?, String>(
  (ref, id) {
    ref.watch(weightUnitProvider.select((u) => u.value));
    return ref.watch(workoutRepositoryProvider).watchDetail(id);
  },
  retry: noRetry,
);
