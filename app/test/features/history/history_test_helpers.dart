import 'package:azm/core/db/app_database.dart';
import 'package:drift/drift.dart';

export '../workout/workout_test_helpers.dart' show insertCatalog, openTestDb, testCatalog;

/// (weight kg, reps, type) of a completed set.
typedef S = (double, int, SetType);

S n(double w, int r) => (w, r, SetType.normal);
S warm(double w, int r) => (w, r, SetType.warmup);

/// Inserts a FINISHED workout: exercise id → completed sets (in order).
/// Returns the workout id.
Future<String> seedWorkout(
  AppDatabase db, {
  required DateTime startedAt,
  required Map<String, List<S>> exercises,
  String name = 'Workout',
  Duration duration = const Duration(minutes: 55),
  WorkoutStatus status = WorkoutStatus.finished,
}) async {
  final wId = newUuid();
  await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        id: Value(wId),
        name: name,
        startedAt: Value(startedAt),
        endedAt: Value(status == WorkoutStatus.finished ? startedAt.add(duration) : null),
        status: Value(status),
      ));
  var sort = 0;
  for (final e in exercises.entries) {
    final weId = newUuid();
    await db.into(db.workoutExercises).insert(
          WorkoutExercisesCompanion.insert(id: Value(weId), workoutId: wId, exerciseId: e.key, sort: Value(sort++)),
        );
    for (var i = 0; i < e.value.length; i++) {
      final s = e.value[i];
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            workoutExerciseId: weId,
            sort: Value(i),
            weightKg: Value(s.$1),
            reps: Value(s.$2),
            type: Value(s.$3),
            completedAt: Value(startedAt.add(Duration(minutes: i + 1))),
          ));
    }
  }
  return wId;
}

/// Set ids of one exercise of a workout, in order.
Future<List<String>> setIds(AppDatabase db, String workoutId, String exerciseId) async {
  final we = await (db.select(db.workoutExercises)
        ..where((e) => e.workoutId.equals(workoutId) & e.exerciseId.equals(exerciseId)))
      .getSingle();
  return [
    for (final s in await (db.select(db.workoutSets)
          ..where((s) => s.workoutExerciseId.equals(we.id))
          ..orderBy([(s) => OrderingTerm(expression: s.sort)]))
        .get())
      s.id,
  ];
}
