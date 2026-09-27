import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../workout/data/workout_repository.dart' show noRetry;
import 'history_models.dart';

/// Reads the history of FINISHED workouts and makes the few edits the
/// workout feature doesn't offer (rename, delete, tidy up). Set edits of a
/// past workout go through `WorkoutRepository` (same writes as the active
/// workout). Every write guards `status = finished`: the active workout is
/// never touched from here.
class HistoryRepository {
  HistoryRepository(this.db);

  final AppDatabase db;

  /// All finished workouts with their completed sets. Re-emits when any
  /// workout table changes, but only if the finished data actually changed
  /// (ticking sets in the active workout doesn't rebuild the history).
  Stream<HistoryData> watchHistory() => db
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
      .map((rows) => [for (final r in rows) r.data])
      .distinct(_sameRows)
      .map(_build);

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

  /// After editing: a finished workout keeps only logged sets (✓ and reps > 0)
  /// and exercises that still have one, the same shape `finish()` leaves.
  Future<void> tidy(String workoutId) => db.transaction(() async {
        if (await finishedWorkout(workoutId) == null) return;
        final entryIds = [
          for (final e in await (db.select(db.workoutExercises)..where((e) => e.workoutId.equals(workoutId))).get())
            e.id,
        ];
        if (entryIds.isEmpty) return;
        await (db.delete(db.workoutSets)
              ..where((s) => s.workoutExerciseId.isIn(entryIds) & (s.completedAt.isNull() | s.reps.isSmallerOrEqualValue(0))))
            .go();
        final withSets = (await (db.selectOnly(db.workoutSets, distinct: true)
                  ..addColumns([db.workoutSets.workoutExerciseId])
                  ..where(db.workoutSets.workoutExerciseId.isIn(entryIds)))
                .get())
            .map((r) => r.read(db.workoutSets.workoutExerciseId)!)
            .toSet();
        await (db.delete(db.workoutExercises)
              ..where((e) => e.workoutId.equals(workoutId) & e.id.isNotIn(withSets)))
            .go();
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

/// Catalog rows of every exercise in the history (names, thumbnails).
final historyExercisesProvider = FutureProvider<Map<String, Exercise>>((ref) async {
  final data = await ref.watch(historyProvider.future);
  final ids = {for (final w in data.workouts) ...w.exercises.map((e) => e.exerciseId)};
  return ref.watch(historyRepositoryProvider).exercises(ids);
}, retry: noRetry);
