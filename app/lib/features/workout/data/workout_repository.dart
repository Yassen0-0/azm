import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';
import '../../settings/data/training_settings.dart';
import 'workout_models.dart';

/// All workout reads/writes. Every mutation hits the DB immediately; the UI
/// only renders what [watchDetail] / [watchActive] emit (docs/ARCHITECTURE.md).
class WorkoutRepository {
  WorkoutRepository(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  DateTime _now() => _clock().toUtc();

  // ---- Active workout ------------------------------------------------------

  SimpleSelectStatement<$WorkoutsTable, Workout> _activeQuery() =>
      db.select(db.workouts)..where((w) => w.status.equalsValue(WorkoutStatus.active));

  /// The one active workout (or null). The DB allows at most one.
  Stream<Workout?> watchActive() => _activeQuery().watchSingleOrNull();

  Future<Workout?> active() => _activeQuery().getSingleOrNull();

  /// Starts an empty workout and returns its id. If a workout is already
  /// active, returns that one instead (at most one active workout).
  Future<String> startEmpty(String name) => db.transaction(() async {
        final existing = await active();
        if (existing != null) return existing.id;
        final id = newUuid();
        await db.into(db.workouts).insert(
              WorkoutsCompanion.insert(id: Value(id), name: name, startedAt: Value(_now())),
            );
        return id;
      });

  /// Appends catalog exercises (in the given order). Each gets as many sets as
  /// it had last time (same types), or one normal set if it is new.
  Future<void> addExercises(String workoutId, List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return;
    await db.transaction(() async {
      final w = await _workout(workoutId);
      if (w == null) return;
      final previous = await previousSets(exerciseIds, before: w.startedAt, excludeWorkoutId: w.id);
      var sort = await _nextExerciseSort(workoutId);
      for (final exId in exerciseIds) {
        final weId = newUuid();
        await db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
              id: Value(weId),
              workoutId: workoutId,
              exerciseId: exId,
              sort: Value(sort++),
            ));
        final prev = previous[exId] ?? const <WorkoutSet>[];
        final types = prev.isEmpty ? [SetType.normal] : [for (final s in prev) s.type];
        for (var i = 0; i < types.length; i++) {
          await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                workoutExerciseId: weId,
                sort: Value(i),
                type: Value(types[i]),
              ));
        }
      }
    });
  }

  /// Adds a set at the end of an exercise, copying the last set's weight and
  /// reps (not its ✓) so the next set is one tap away.
  Future<void> addSet(String workoutExerciseId) => db.transaction(() async {
        final last = await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.equals(workoutExerciseId))
              ..orderBy([(s) => OrderingTerm.desc(s.sort)])
              ..limit(1))
            .getSingleOrNull();
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              sort: Value((last?.sort ?? -1) + 1),
              weightKg: Value(last?.weightKg ?? 0),
              reps: Value(last?.reps ?? 0),
            ));
      });

  Future<void> updateSet(String setId, {double? weightKg, int? reps, SetType? type}) =>
      (db.update(db.workoutSets)..where((s) => s.id.equals(setId))).write(WorkoutSetsCompanion(
        weightKg: weightKg == null ? const Value.absent() : Value(weightKg < 0 ? 0 : weightKg),
        reps: reps == null ? const Value.absent() : Value(reps < 0 ? 0 : reps),
        type: type == null ? const Value.absent() : Value(type),
      ));

  /// ✓ / un-✓ a set. Completing may also fill weight + reps (from "previous").
  Future<void> setCompleted(String setId, bool completed, {double? weightKg, int? reps}) =>
      (db.update(db.workoutSets)..where((s) => s.id.equals(setId))).write(WorkoutSetsCompanion(
        completedAt: Value(completed ? _now() : null),
        weightKg: weightKg == null ? const Value.absent() : Value(weightKg),
        reps: reps == null ? const Value.absent() : Value(reps),
      ));

  /// Deletes a set for good: from here on no total, PR, "previous" or
  /// history reads it (they all read the DB). Undo = [restoreSet].
  Future<void> deleteSet(String setId) =>
      (db.delete(db.workoutSets)..where((s) => s.id.equals(setId))).go();

  /// Undo of [deleteSet]: puts the exact row back (same id, position,
  /// values, ✓), shifting later sets down if a new set took its place.
  /// Returns false and changes nothing when its exercise is gone, or when the
  /// workout's status is no longer [status] (e.g. the active workout was
  /// finished or discarded before the user tapped Undo).
  Future<bool> restoreSet(WorkoutSet set, {WorkoutStatus? status}) => db.transaction(() async {
        final row = await (db.select(db.workoutExercises).join([
          innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutExercises.workoutId)),
        ])
              ..where(db.workoutExercises.id.equals(set.workoutExerciseId)))
            .getSingleOrNull();
        if (row == null) return false;
        if (status != null && row.readTable(db.workouts).status != status) return false;
        final siblings = await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.equals(set.workoutExerciseId)))
            .get();
        if (siblings.any((s) => s.id == set.id)) return false;
        if (siblings.any((s) => s.sort == set.sort)) {
          for (final s in siblings.where((s) => s.sort >= set.sort)) {
            await (db.update(db.workoutSets)..where((x) => x.id.equals(s.id)))
                .write(WorkoutSetsCompanion(sort: Value(s.sort + 1)));
          }
        }
        await db.into(db.workoutSets).insert(set);
        return true;
      });

  Future<void> removeExercise(String workoutExerciseId) =>
      (db.delete(db.workoutExercises)..where((e) => e.id.equals(workoutExerciseId))).go();

  /// Persists a new exercise order ([workoutExerciseIds] in display order).
  Future<void> reorderExercises(List<String> workoutExerciseIds) => db.transaction(() async {
        for (var i = 0; i < workoutExerciseIds.length; i++) {
          await (db.update(db.workoutExercises)..where((e) => e.id.equals(workoutExerciseIds[i])))
              .write(WorkoutExercisesCompanion(sort: Value(i)));
        }
      });

  /// Finishes the workout: the sets in [complete] are ✓'d first ("Mark all
  /// done"), then sets without ✓ are dropped, exercises left empty are
  /// dropped, status → finished. Returns false (and changes nothing) when
  /// there is no completed set at all.
  Future<bool> finish(String workoutId, {List<SetCompletion> complete = const []}) => db.transaction(() async {
        final weIds = await _exerciseIds(workoutId);
        final now = _now();
        for (final c in complete) {
          await (db.update(db.workoutSets)
                ..where((s) => s.id.equals(c.setId) & s.workoutExerciseId.isIn(weIds)))
              .write(WorkoutSetsCompanion(
            completedAt: Value(now),
            weightKg: Value(c.weightKg),
            reps: Value(c.reps),
          ));
        }
        final done = await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.isIn(weIds) & s.completedAt.isNotNull()))
            .get();
        if (done.isEmpty) return false;
        await (db.delete(db.workoutSets)
              ..where((s) => s.workoutExerciseId.isIn(weIds) & s.completedAt.isNull()))
            .go();
        final withSets = done.map((s) => s.workoutExerciseId).toSet();
        await (db.delete(db.workoutExercises)
              ..where((e) => e.workoutId.equals(workoutId) & e.id.isNotIn(withSets)))
            .go();
        await (db.update(db.workouts)..where((w) => w.id.equals(workoutId))).write(WorkoutsCompanion(
          status: const Value(WorkoutStatus.finished),
          endedAt: Value(_now()),
        ));
        return true;
      });

  /// Deletes the workout and everything in it (FK cascade).
  Future<void> discard(String workoutId) =>
      (db.delete(db.workouts)..where((w) => w.id.equals(workoutId))).go();

  // ---- Detail ----------------------------------------------------------------

  /// Re-emits the full detail whenever any workout table changes. The watched
  /// query reads this workout's real rows (CLAUDE.md → Drift watch queries);
  /// Drift re-runs it on any write to a table in `readsFrom`, which also
  /// covers the other workouts that "previous" and PR bests come from. Unit
  /// and default rest are settings, watched by `workoutDetailProvider`.
  Stream<WorkoutDetail?> watchDetail(String workoutId) => db
      .customSelect(
        '''
        SELECT w.id, w.name, w.status, w.ended_at, e.id AS entry_id, e.sort AS entry_sort,
               s.id AS set_id, s.sort AS set_sort, s.type, s.weight_kg, s.reps, s.completed_at
        FROM workouts w
        LEFT JOIN workout_exercises e ON e.workout_id = w.id
        LEFT JOIN workout_sets s ON s.workout_exercise_id = e.id
        WHERE w.id = ?
        ''',
        variables: [Variable.withString(workoutId)],
        readsFrom: {db.workouts, db.workoutExercises, db.workoutSets},
      )
      .watch()
      .asyncMap((_) => loadDetail(workoutId));

  Future<WorkoutDetail?> loadDetail(String workoutId) async {
    final w = await _workout(workoutId);
    if (w == null) return null;
    final entries = await (db.select(db.workoutExercises)
          ..where((e) => e.workoutId.equals(workoutId))
          ..orderBy([(e) => OrderingTerm(expression: e.sort)]))
        .get();
    final sets = entries.isEmpty
        ? const <WorkoutSet>[]
        : await (db.select(db.workoutSets)
              ..where((s) => s.workoutExerciseId.isIn(entries.map((e) => e.id)))
              ..orderBy([(s) => OrderingTerm(expression: s.sort)]))
            .get();
    final exIds = entries.map((e) => e.exerciseId).toSet().toList();
    final catalog = {
      for (final e in await (db.select(db.exercises)..where((e) => e.id.isIn(exIds))).get()) e.id: e,
    };
    final previous = await previousSets(exIds, before: w.startedAt, excludeWorkoutId: w.id);
    final bests = await prBests(exIds, before: w.startedAt, excludeWorkoutId: w.id);
    final rest = await _restSeconds(w, exIds);

    return WorkoutDetail(
      workout: w,
      unit: await weightUnit(),
      exercises: [
        for (final e in entries)
          () {
            final mine = sets.where((s) => s.workoutExerciseId == e.id).toList();
            return WorkoutExerciseDetail(
              entry: e,
              exercise: catalog[e.exerciseId],
              sets: mine,
              previous: previous[e.exerciseId] ?? const [],
              prs: detectPrs(mine.map(setStatsOf).toList(), bests[e.exerciseId] ?? PrBests.none),
              restSeconds: rest[e.exerciseId] ?? kDefaultRestSeconds,
            );
          }(),
      ],
    );
  }

  /// "Previous" per exercise: the sets (in order) of that exercise in the most
  /// recent finished workout started before [before]. First occurrence wins
  /// if an exercise appears twice in that workout.
  Future<Map<String, List<WorkoutSet>>> previousSets(
    List<String> exerciseIds, {
    required DateTime before,
    String? excludeWorkoutId,
  }) async {
    if (exerciseIds.isEmpty) return const {};
    final q = db.select(db.workoutExercises).join([
      innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutExercises.workoutId)),
    ])
      ..where(db.workouts.status.equalsValue(WorkoutStatus.finished) &
          db.workoutExercises.exerciseId.isIn(exerciseIds) &
          db.workouts.startedAt.isSmallerThanValue(before) &
          (excludeWorkoutId == null
              ? const Constant(true)
              : db.workouts.id.equals(excludeWorkoutId).not()))
      ..orderBy([
        OrderingTerm.desc(db.workouts.startedAt),
        OrderingTerm.asc(db.workoutExercises.sort),
      ]);
    final latest = <String, String>{}; // exerciseId → workoutExerciseId
    for (final row in await q.get()) {
      final we = row.readTable(db.workoutExercises);
      latest.putIfAbsent(we.exerciseId, () => we.id);
    }
    if (latest.isEmpty) return const {};
    final sets = await (db.select(db.workoutSets)
          ..where((s) => s.workoutExerciseId.isIn(latest.values))
          ..orderBy([(s) => OrderingTerm(expression: s.sort)]))
        .get();
    return {
      for (final entry in latest.entries)
        entry.key: sets.where((s) => s.workoutExerciseId == entry.value).toList(),
    };
  }

  /// PR bests per exercise over completed sets of finished workouts started
  /// before [before] (warm-ups ignored by [PrBests.fromSets]).
  Future<Map<String, PrBests>> prBests(
    List<String> exerciseIds, {
    required DateTime before,
    String? excludeWorkoutId,
  }) async {
    if (exerciseIds.isEmpty) return const {};
    final q = db.select(db.workoutSets).join([
      innerJoin(db.workoutExercises, db.workoutExercises.id.equalsExp(db.workoutSets.workoutExerciseId)),
      innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutExercises.workoutId)),
    ])
      ..where(db.workouts.status.equalsValue(WorkoutStatus.finished) &
          db.workoutExercises.exerciseId.isIn(exerciseIds) &
          db.workoutSets.completedAt.isNotNull() &
          db.workouts.startedAt.isSmallerThanValue(before) &
          (excludeWorkoutId == null
              ? const Constant(true)
              : db.workouts.id.equals(excludeWorkoutId).not()));
    final byExercise = <String, List<SetStats>>{};
    for (final row in await q.get()) {
      final exId = row.readTable(db.workoutExercises).exerciseId;
      (byExercise[exId] ??= []).add(setStatsOf(row.readTable(db.workoutSets)));
    }
    return {for (final e in byExercise.entries) e.key: PrBests.fromSets(e.value)};
  }

  // ---- Settings the workout reads ------------------------------------------

  Future<WeightUnit> weightUnit() async => parseWeightUnit(await db.readSetting(TrainingSettingsKeys.unit));

  Future<int> defaultRestSeconds() async =>
      parseDefaultRestSeconds(await db.readSetting(TrainingSettingsKeys.defaultRestSeconds));

  // ---- Helpers -------------------------------------------------------------

  Future<Workout?> _workout(String id) =>
      (db.select(db.workouts)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<List<String>> _exerciseIds(String workoutId) async => [
        for (final e in await (db.select(db.workoutExercises)..where((e) => e.workoutId.equals(workoutId))).get())
          e.id,
      ];

  Future<int> _nextExerciseSort(String workoutId) async {
    final max = db.workoutExercises.sort.max();
    final row = await (db.selectOnly(db.workoutExercises)
          ..addColumns([max])
          ..where(db.workoutExercises.workoutId.equals(workoutId)))
        .getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  /// Rest per exercise: routine exercise override → settings default → 90 s.
  Future<Map<String, int>> _restSeconds(Workout w, List<String> exerciseIds) async {
    final fallback = await defaultRestSeconds();
    final out = {for (final id in exerciseIds) id: fallback};
    final routineId = w.routineId;
    if (routineId == null || exerciseIds.isEmpty) return out;
    final rows = await (db.select(db.routineExercises)
          ..where((r) => r.routineId.equals(routineId) & r.exerciseId.isIn(exerciseIds)))
        .get();
    for (final r in rows) {
      final s = r.restSeconds;
      if (s != null && s > 0) out[r.exerciseId] = s;
    }
    return out;
  }
}

/// Wall clock (overridden in tests).
final workoutClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(appDatabaseProvider), clock: ref.watch(workoutClockProvider)),
);

/// Never auto-retry: a failing DB provider (e.g. widget tests without a DB)
/// should just show nothing, without background retry timers.
Duration? noRetry(int _, Object _) => null;

/// The active workout, or null.
final activeWorkoutProvider = StreamProvider<Workout?>(
  (ref) => ref.watch(workoutRepositoryProvider).watchActive(),
  retry: noRetry,
);

/// Full detail of one workout (active screen, summary). Reloads when the
/// unit or the default rest changes in settings.
final workoutDetailProvider = StreamProvider.family<WorkoutDetail?, String>(
  (ref, id) {
    ref.watch(weightUnitProvider.select((u) => u.value));
    ref.watch(defaultRestSecondsProvider.select((r) => r.value));
    return ref.watch(workoutRepositoryProvider).watchDetail(id);
  },
  retry: noRetry,
);
