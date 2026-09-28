import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'ready_programs.dart';

/// Sets a newly added routine exercise starts with.
const int kNewRoutineExerciseSets = 3;

/// A routine in the "My routines" list.
@immutable
class RoutineSummary {
  const RoutineSummary({required this.routine, required this.exerciseIds});

  final Routine routine;

  /// Catalog ids in routine order.
  final List<String> exerciseIds;
}

/// One exercise of a routine with its target sets.
@immutable
class RoutineExerciseDetail {
  const RoutineExerciseDetail({required this.entry, required this.exercise, required this.sets});

  final RoutineExercise entry;

  /// Catalog row, or null when the exercise left the catalog.
  final Exercise? exercise;

  /// Target sets in order.
  final List<RoutineSet> sets;
}

/// A routine with everything the editor shows. Always rebuilt from the DB.
@immutable
class RoutineDetail {
  const RoutineDetail({required this.routine, required this.exercises});

  final Routine routine;
  final List<RoutineExerciseDetail> exercises;

  Iterable<RoutineSet> get allSets => exercises.expand((e) => e.sets);
}

/// Result of starting a routine: the workout id, and whether an already
/// active workout was resumed instead of starting a new one.
typedef RoutineStart = ({String workoutId, bool resumed});

/// All routine reads/writes. Every mutation hits the DB immediately; screens
/// render what the watch streams emit (docs/ARCHITECTURE.md).
class RoutineRepository {
  RoutineRepository(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  DateTime _now() => _clock().toUtc();

  // ---- Routines --------------------------------------------------------------

  /// "My routines" in display order, with their exercise ids. The watched
  /// query reads the real routine rows (CLAUDE.md → Drift watch queries).
  Stream<List<RoutineSummary>> watchRoutines() => db
      .customSelect(
        '''
        SELECT r.id, r.name, r.sort, e.id AS entry_id, e.exercise_id, e.sort AS entry_sort
        FROM routines r
        LEFT JOIN routine_exercises e ON e.routine_id = r.id
        ORDER BY r.sort, r.created_at, e.sort
        ''',
        readsFrom: {db.routines, db.routineExercises},
      )
      .watch()
      .asyncMap((_) => loadRoutines());

  Future<List<RoutineSummary>> loadRoutines() async {
    final routines = await (db.select(db.routines)
          ..orderBy([(r) => OrderingTerm(expression: r.sort), (r) => OrderingTerm(expression: r.createdAt)]))
        .get();
    final entries = await (db.select(db.routineExercises)..orderBy([(e) => OrderingTerm(expression: e.sort)])).get();
    return [
      for (final r in routines)
        RoutineSummary(
          routine: r,
          exerciseIds: [for (final e in entries) if (e.routineId == r.id) e.exerciseId],
        ),
    ];
  }

  /// Creates a routine at the end of the list and returns its id.
  Future<String> create({String name = '', String? notes}) => db.transaction(() async {
        final id = newUuid();
        final now = _now();
        await db.into(db.routines).insert(RoutinesCompanion.insert(
              id: Value(id),
              name: name,
              notes: Value(notes),
              sort: Value(await _nextRoutineSort()),
              createdAt: Value(now),
              updatedAt: Value(now),
            ));
        return id;
      });

  Future<void> rename(String routineId, String name) =>
      _touch(routineId, RoutinesCompanion(name: Value(name)));

  Future<void> setNotes(String routineId, String notes) =>
      _touch(routineId, RoutinesCompanion(notes: Value(notes.trim().isEmpty ? null : notes)));

  /// Deletes the routine with its exercises and sets (FK cascade). Workouts
  /// started from it keep their `routine_id` (no FK, DATA.md).
  Future<void> delete(String routineId) => (db.delete(db.routines)..where((r) => r.id.equals(routineId))).go();

  /// True when the routine has no name, no notes and no exercises (a "New
  /// routine" opened and left untouched).
  Future<bool> isBlank(String routineId) async {
    final r = await _routine(routineId);
    if (r == null) return false;
    if (r.name.trim().isNotEmpty || (r.notes ?? '').trim().isNotEmpty) return false;
    final any = await (db.select(db.routineExercises)
          ..where((e) => e.routineId.equals(routineId))
          ..limit(1))
        .getSingleOrNull();
    return any == null;
  }

  // ---- Detail ----------------------------------------------------------------

  /// Re-emits whenever any routine table changes. Null once deleted. The
  /// watched query reads this routine's real rows.
  Stream<RoutineDetail?> watchDetail(String routineId) => db
      .customSelect(
        '''
        SELECT r.id, r.name, r.notes, e.id AS entry_id, e.sort AS entry_sort, e.rest_seconds,
               s.id AS set_id, s.sort AS set_sort, s.type, s.target_reps, s.target_weight_kg
        FROM routines r
        LEFT JOIN routine_exercises e ON e.routine_id = r.id
        LEFT JOIN routine_sets s ON s.routine_exercise_id = e.id
        WHERE r.id = ?
        ''',
        variables: [Variable.withString(routineId)],
        readsFrom: {db.routines, db.routineExercises, db.routineSets},
      )
      .watch()
      .asyncMap((_) => loadDetail(routineId));

  Future<RoutineDetail?> loadDetail(String routineId) async {
    final r = await _routine(routineId);
    if (r == null) return null;
    final entries = await (db.select(db.routineExercises)
          ..where((e) => e.routineId.equals(routineId))
          ..orderBy([(e) => OrderingTerm(expression: e.sort)]))
        .get();
    final sets = entries.isEmpty
        ? const <RoutineSet>[]
        : await (db.select(db.routineSets)
              ..where((s) => s.routineExerciseId.isIn(entries.map((e) => e.id)))
              ..orderBy([(s) => OrderingTerm(expression: s.sort)]))
            .get();
    final exIds = entries.map((e) => e.exerciseId).toSet().toList();
    final catalog = {
      for (final e in await (db.select(db.exercises)..where((e) => e.id.isIn(exIds))).get()) e.id: e,
    };
    return RoutineDetail(
      routine: r,
      exercises: [
        for (final e in entries)
          RoutineExerciseDetail(
            entry: e,
            exercise: catalog[e.exerciseId],
            sets: [for (final s in sets) if (s.routineExerciseId == e.id) s],
          ),
      ],
    );
  }

  // ---- Exercises -------------------------------------------------------------

  /// Appends catalog exercises in the given order, each with
  /// [kNewRoutineExerciseSets] normal sets without targets.
  Future<void> addExercises(String routineId, List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return;
    await db.transaction(() async {
      var sort = await _nextExerciseSort(routineId);
      for (final exId in exerciseIds) {
        final reId = newUuid();
        await db.into(db.routineExercises).insert(RoutineExercisesCompanion.insert(
              id: Value(reId),
              routineId: routineId,
              exerciseId: exId,
              sort: Value(sort++),
            ));
        for (var i = 0; i < kNewRoutineExerciseSets; i++) {
          await db.into(db.routineSets).insert(RoutineSetsCompanion.insert(routineExerciseId: reId, sort: Value(i)));
        }
      }
      await _touch(routineId);
    });
  }

  Future<void> removeExercise(String routineExerciseId) => db.transaction(() async {
        final routineId = await _routineOfExercise(routineExerciseId);
        await (db.delete(db.routineExercises)..where((e) => e.id.equals(routineExerciseId))).go();
        if (routineId != null) await _touch(routineId);
      });

  /// Persists a new exercise order ([routineExerciseIds] in display order).
  Future<void> reorderExercises(List<String> routineExerciseIds) => db.transaction(() async {
        for (var i = 0; i < routineExerciseIds.length; i++) {
          await (db.update(db.routineExercises)..where((e) => e.id.equals(routineExerciseIds[i])))
              .write(RoutineExercisesCompanion(sort: Value(i)));
        }
        if (routineExerciseIds.isNotEmpty) {
          final routineId = await _routineOfExercise(routineExerciseIds.first);
          if (routineId != null) await _touch(routineId);
        }
      });

  /// Per-exercise rest override; null → the default from settings.
  Future<void> setRestSeconds(String routineExerciseId, int? seconds) => db.transaction(() async {
        await (db.update(db.routineExercises)..where((e) => e.id.equals(routineExerciseId)))
            .write(RoutineExercisesCompanion(restSeconds: Value(seconds != null && seconds > 0 ? seconds : null)));
        final routineId = await _routineOfExercise(routineExerciseId);
        if (routineId != null) await _touch(routineId);
      });

  // ---- Sets ------------------------------------------------------------------

  /// Adds a set at the end, copying the last set's targets (as a normal set).
  Future<void> addSet(String routineExerciseId) => db.transaction(() async {
        final last = await (db.select(db.routineSets)
              ..where((s) => s.routineExerciseId.equals(routineExerciseId))
              ..orderBy([(s) => OrderingTerm.desc(s.sort)])
              ..limit(1))
            .getSingleOrNull();
        await db.into(db.routineSets).insert(RoutineSetsCompanion.insert(
              routineExerciseId: routineExerciseId,
              sort: Value((last?.sort ?? -1) + 1),
              targetReps: Value(last?.targetReps),
              targetWeightKg: Value(last?.targetWeightKg),
            ));
        final routineId = await _routineOfExercise(routineExerciseId);
        if (routineId != null) await _touch(routineId);
      });

  /// Updates a target set. `clearReps` / `clearWeight` store null (no target).
  Future<void> updateSet(
    String setId, {
    SetType? type,
    int? targetReps,
    double? targetWeightKg,
    bool clearReps = false,
    bool clearWeight = false,
  }) =>
      db.transaction(() async {
        await (db.update(db.routineSets)..where((s) => s.id.equals(setId))).write(RoutineSetsCompanion(
          type: type == null ? const Value.absent() : Value(type),
          targetReps: clearReps || (targetReps != null && targetReps <= 0)
              ? const Value(null)
              : (targetReps == null ? const Value.absent() : Value(targetReps)),
          targetWeightKg: clearWeight || (targetWeightKg != null && targetWeightKg <= 0)
              ? const Value(null)
              : (targetWeightKg == null ? const Value.absent() : Value(targetWeightKg)),
        ));
        await _touchBySet(setId);
      });

  Future<void> deleteSet(String setId) => db.transaction(() async {
        await _touchBySet(setId);
        await (db.delete(db.routineSets)..where((s) => s.id.equals(setId))).go();
      });

  /// Undo of [deleteSet]: puts the exact target set back (same id, position,
  /// type, targets), shifting later sets down if a new set took its place.
  /// Returns false when its routine exercise is gone.
  Future<bool> restoreSet(RoutineSet set) => db.transaction(() async {
        final routineId = await _routineOfExercise(set.routineExerciseId);
        if (routineId == null) return false;
        final siblings = await (db.select(db.routineSets)
              ..where((s) => s.routineExerciseId.equals(set.routineExerciseId)))
            .get();
        if (siblings.any((s) => s.id == set.id)) return false;
        if (siblings.any((s) => s.sort == set.sort)) {
          for (final s in siblings.where((s) => s.sort >= set.sort)) {
            await (db.update(db.routineSets)..where((x) => x.id.equals(s.id)))
                .write(RoutineSetsCompanion(sort: Value(s.sort + 1)));
          }
        }
        await db.into(db.routineSets).insert(set);
        await _touch(routineId);
        return true;
      });

  // ---- Start ------------------------------------------------------------------

  /// Starts a workout from the routine (docs/SPEC.md → Routines): the
  /// workout gets `routine_id`, the routine's name and one workout set per
  /// target set (type, reps = target reps, weight = target weight, else the
  /// weight of the same set last time). If a workout is already active it is
  /// returned untouched (at most one active workout).
  Future<RoutineStart> start(String routineId, {required String fallbackName}) => db.transaction(() async {
        final existing = await (db.select(db.workouts)
              ..where((w) => w.status.equalsValue(WorkoutStatus.active)))
            .getSingleOrNull();
        if (existing != null) return (workoutId: existing.id, resumed: true);

        final detail = await loadDetail(routineId);
        final name = (detail?.routine.name.trim().isNotEmpty ?? false) ? detail!.routine.name.trim() : fallbackName;
        final now = _now();
        final workoutId = newUuid();
        await db.into(db.workouts).insert(WorkoutsCompanion.insert(
              id: Value(workoutId),
              routineId: Value(detail == null ? null : routineId),
              name: name,
              startedAt: Value(now),
            ));
        if (detail == null) return (workoutId: workoutId, resumed: false);

        final previous = await _previousWeights(detail.exercises.map((e) => e.entry.exerciseId).toSet(), before: now);
        for (var i = 0; i < detail.exercises.length; i++) {
          final e = detail.exercises[i];
          final weId = newUuid();
          await db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
                id: Value(weId),
                workoutId: workoutId,
                exerciseId: e.entry.exerciseId,
                sort: Value(i),
                notes: Value(e.entry.notes),
              ));
          final last = previous[e.entry.exerciseId] ?? const <double>[];
          for (var j = 0; j < e.sets.length; j++) {
            final s = e.sets[j];
            await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                  workoutExerciseId: weId,
                  sort: Value(j),
                  type: Value(s.type),
                  reps: Value(s.targetReps ?? 0),
                  weightKg: Value(s.targetWeightKg ?? (j < last.length ? last[j] : 0)),
                ));
          }
        }
        return (workoutId: workoutId, resumed: false);
      });

  // ---- Ready programs ----------------------------------------------------------

  /// Copies every day of [program] into "My routines" (appended, in program
  /// order) and returns the new routine ids. Names are in [languageCode];
  /// each set's `target_reps` = the range max (docs/DATA.md). Copying twice
  /// creates independent copies.
  Future<List<String>> copyProgram(ReadyProgram program, {required String languageCode}) => db.transaction(() async {
        final ids = <String>[];
        var sort = await _nextRoutineSort();
        final now = _now();
        for (final day in program.days) {
          final routineId = newUuid();
          await db.into(db.routines).insert(RoutinesCompanion.insert(
                id: Value(routineId),
                name: day.name.of(languageCode),
                sort: Value(sort++),
                createdAt: Value(now),
                updatedAt: Value(now),
              ));
          for (var i = 0; i < day.exercises.length; i++) {
            final pe = day.exercises[i];
            final reId = newUuid();
            await db.into(db.routineExercises).insert(RoutineExercisesCompanion.insert(
                  id: Value(reId),
                  routineId: routineId,
                  exerciseId: pe.exerciseId,
                  sort: Value(i),
                  restSeconds: Value(pe.restSeconds),
                ));
            for (var j = 0; j < pe.sets; j++) {
              await db.into(db.routineSets).insert(RoutineSetsCompanion.insert(
                    routineExerciseId: reId,
                    sort: Value(j),
                    targetReps: Value(pe.repsMax),
                  ));
            }
          }
          ids.add(routineId);
        }
        return ids;
      });

  // ---- Helpers -------------------------------------------------------------

  Future<Routine?> _routine(String id) => (db.select(db.routines)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> _touch(String routineId, [RoutinesCompanion changes = const RoutinesCompanion()]) =>
      (db.update(db.routines)..where((r) => r.id.equals(routineId))).write(changes.copyWith(updatedAt: Value(_now())));

  Future<String?> _routineOfExercise(String routineExerciseId) async => (await (db.select(db.routineExercises)
            ..where((e) => e.id.equals(routineExerciseId)))
          .getSingleOrNull())
      ?.routineId;

  Future<void> _touchBySet(String setId) async {
    final s = await (db.select(db.routineSets)..where((s) => s.id.equals(setId))).getSingleOrNull();
    if (s == null) return;
    final routineId = await _routineOfExercise(s.routineExerciseId);
    if (routineId != null) await _touch(routineId);
  }

  Future<int> _nextRoutineSort() async {
    final max = db.routines.sort.max();
    final row = await (db.selectOnly(db.routines)..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<int> _nextExerciseSort(String routineId) async {
    final max = db.routineExercises.sort.max();
    final row = await (db.selectOnly(db.routineExercises)
          ..addColumns([max])
          ..where(db.routineExercises.routineId.equals(routineId)))
        .getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  /// Per exercise: the set weights (in order) of the most recent finished
  /// workout started before [before] that contains it. Same rule as the
  /// workout's "previous" column.
  Future<Map<String, List<double>>> _previousWeights(Set<String> exerciseIds, {required DateTime before}) async {
    if (exerciseIds.isEmpty) return const {};
    final q = db.select(db.workoutExercises).join([
      innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutExercises.workoutId)),
    ])
      ..where(db.workouts.status.equalsValue(WorkoutStatus.finished) &
          db.workoutExercises.exerciseId.isIn(exerciseIds) &
          db.workouts.startedAt.isSmallerThanValue(before))
      ..orderBy([OrderingTerm.desc(db.workouts.startedAt), OrderingTerm.asc(db.workoutExercises.sort)]);
    final latest = <String, String>{};
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
      for (final e in latest.entries)
        e.key: [for (final s in sets) if (s.workoutExerciseId == e.value) s.weightKg],
    };
  }
}

/// Wall clock (overridden in tests).
final routineClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(ref.watch(appDatabaseProvider), clock: ref.watch(routineClockProvider)),
);

Duration? _noRetry(int _, Object _) => null;

/// "My routines" list.
final routinesProvider = StreamProvider<List<RoutineSummary>>(
  (ref) => ref.watch(routineRepositoryProvider).watchRoutines(),
  retry: _noRetry,
);

/// One routine for the editor (null once deleted).
final routineDetailProvider = StreamProvider.family<RoutineDetail?, String>(
  (ref, id) => ref.watch(routineRepositoryProvider).watchDetail(id),
  retry: _noRetry,
);

/// Catalog rows by id (program previews, routine cards).
final catalogExercisesProvider = FutureProvider.family<Map<String, Exercise>, String>(
  (ref, idsKey) async {
    final ids = idsKey.isEmpty ? const <String>[] : idsKey.split(',');
    final db = ref.watch(appDatabaseProvider);
    return {for (final e in await (db.select(db.exercises)..where((e) => e.id.isIn(ids))).get()) e.id: e};
  },
  retry: _noRetry,
);
