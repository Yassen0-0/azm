import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/settings/data/backup/backup_codec.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Every user row + every settings row, for "identical" comparisons.
Future<Map<String, List<Object>>> dumpUserData(AppDatabase db) async => {
      'routines': await db.select(db.routines).get(),
      'routine_exercises': await db.select(db.routineExercises).get(),
      'routine_sets': await db.select(db.routineSets).get(),
      'workouts': await db.select(db.workouts).get(),
      'workout_exercises': await db.select(db.workoutExercises).get(),
      'workout_sets': await db.select(db.workoutSets).get(),
      'settings': await db.select(db.settings).get(),
    };

/// Sorted by primary key so dumps compare independently of row order.
Map<String, List<String>> normalized(Map<String, List<Object>> dump) => {
      for (final e in dump.entries) e.key: (e.value.map((r) => r.toString()).toList()..sort()),
    };

DateTime t(int day, [int hour = 10, int minute = 0, int ms = 0]) =>
    DateTime.utc(2026, 9, day, hour, minute, 0, ms);

/// A realistic data set touching every column, nulls included.
Future<void> seedEverything(AppDatabase db, {bool activeWorkout = false}) async {
  await db.batch((b) {
    b.insertAll(db.routines, [
      Routine(id: 'a1111111-1111-4111-8111-111111111111', name: 'دفع', notes: 'صدر + تراي', sort: 0, createdAt: t(1), updatedAt: t(2, 11, 5, 123)),
      Routine(id: 'a2222222-2222-4222-8222-222222222222', name: 'Pull', sort: 1, createdAt: t(3), updatedAt: t(3)),
    ]);
    b.insertAll(db.routineExercises, [
      const RoutineExercise(id: 'b1111111-1111-4111-8111-111111111111', routineId: 'a1111111-1111-4111-8111-111111111111', exerciseId: '0025', sort: 0, restSeconds: 150, notes: 'slow'),
      const RoutineExercise(id: 'b2222222-2222-4222-8222-222222222222', routineId: 'a1111111-1111-4111-8111-111111111111', exerciseId: '0314', sort: 1),
      const RoutineExercise(id: 'b3333333-3333-4333-8333-333333333333', routineId: 'a2222222-2222-4222-8222-222222222222', exerciseId: '0027', sort: 0),
    ]);
    b.insertAll(db.routineSets, [
      const RoutineSet(id: 'c1111111-1111-4111-8111-111111111111', routineExerciseId: 'b1111111-1111-4111-8111-111111111111', sort: 0, type: SetType.warmup, targetReps: 12, targetWeightKg: 20),
      const RoutineSet(id: 'c2222222-2222-4222-8222-222222222222', routineExerciseId: 'b1111111-1111-4111-8111-111111111111', sort: 1, type: SetType.normal, targetReps: 8, targetWeightKg: 62.5),
      const RoutineSet(id: 'c3333333-3333-4333-8333-333333333333', routineExerciseId: 'b2222222-2222-4222-8222-222222222222', sort: 0, type: SetType.failure),
      const RoutineSet(id: 'c4444444-4444-4444-8444-444444444444', routineExerciseId: 'b3333333-3333-4333-8333-333333333333', sort: 0, type: SetType.drop, targetReps: 10),
    ]);
    b.insertAll(db.workouts, [
      Workout(id: 'd1111111-1111-4111-8111-111111111111', routineId: 'a1111111-1111-4111-8111-111111111111', name: 'دفع', startedAt: t(5, 18), endedAt: t(5, 19, 12, 456), status: WorkoutStatus.finished, notes: 'PR!'),
      // Routine since deleted: routine_id points nowhere (no FK by design).
      Workout(id: 'd2222222-2222-4222-8222-222222222222', routineId: 'a9999999-9999-4999-8999-999999999999', name: 'Legs', startedAt: t(6, 7), endedAt: t(6, 8), status: WorkoutStatus.finished),
      if (activeWorkout)
        Workout(id: 'd3333333-3333-4333-8333-333333333333', name: 'Now', startedAt: t(7, 9), status: WorkoutStatus.active),
    ]);
    b.insertAll(db.workoutExercises, [
      const WorkoutExercise(id: 'e1111111-1111-4111-8111-111111111111', workoutId: 'd1111111-1111-4111-8111-111111111111', exerciseId: '0025', sort: 0, notes: 'grip'),
      const WorkoutExercise(id: 'e2222222-2222-4222-8222-222222222222', workoutId: 'd2222222-2222-4222-8222-222222222222', exerciseId: '9999', sort: 0),
    ]);
    b.insertAll(db.workoutSets, [
      WorkoutSet(id: 'f1111111-1111-4111-8111-111111111111', workoutExerciseId: 'e1111111-1111-4111-8111-111111111111', sort: 0, type: SetType.warmup, weightKg: 20, reps: 12, completedAt: t(5, 18, 5)),
      WorkoutSet(id: 'f2222222-2222-4222-8222-222222222222', workoutExerciseId: 'e1111111-1111-4111-8111-111111111111', sort: 1, type: SetType.normal, weightKg: 83.91457, reps: 5, completedAt: t(5, 18, 9, 1)),
      const WorkoutSet(id: 'f3333333-3333-4333-8333-333333333333', workoutExerciseId: 'e1111111-1111-4111-8111-111111111111', sort: 2, type: SetType.drop, weightKg: 0, reps: 0),
      WorkoutSet(id: 'f4444444-4444-4444-8444-444444444444', workoutExerciseId: 'e2222222-2222-4222-8222-222222222222', sort: 0, type: SetType.failure, weightKg: 140, reps: 1, completedAt: t(6, 7, 30)),
    ]);
  });
  await db.writeSetting('locale', '"ar"');
  await db.writeSetting('theme', '"light"');
  await db.writeSetting('unit', '"lb"');
  await db.writeSetting('default_rest_seconds', '120');
  // Device state: never exported, never overwritten.
  await db.writeSetting('onboarding_done', 'true');
  await db.writeSetting('workout_notifications_asked', 'true');
}

/// Deletes every user row and every setting (a "fresh install").
Future<void> wipe(AppDatabase db) async {
  await db.delete(db.workoutSets).go();
  await db.delete(db.workoutExercises).go();
  await db.delete(db.workouts).go();
  await db.delete(db.routineSets).go();
  await db.delete(db.routineExercises).go();
  await db.delete(db.routines).go();
  await db.delete(db.settings).go();
}

/// A valid backup text built from [seedEverything].
Future<String> validBackupText() async {
  final db = memoryDb();
  await seedEverything(db);
  final rows = await dumpUserData(db);
  final settings = {
    for (final s in rows['settings']!.cast<SettingRow>())
      if (kBackupSettingsKeys.contains(s.key)) s.key: s.value,
  };
  final text = encodeBackup(BackupContents(
    exportedAt: t(8),
    appVersion: 'test',
    settings: settings,
    routines: rows['routines']!.cast(),
    routineExercises: rows['routine_exercises']!.cast(),
    routineSets: rows['routine_sets']!.cast(),
    workouts: rows['workouts']!.cast(),
    workoutExercises: rows['workout_exercises']!.cast(),
    workoutSets: rows['workout_sets']!.cast(),
  ));
  await db.close();
  return text;
}
