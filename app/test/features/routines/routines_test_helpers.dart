import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// In-memory DB (same schema + one-active-workout index as on device).
AppDatabase openRoutinesTestDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

const routinesTestCatalog = {
  '0025': (en: 'Barbell Bench Press', ar: 'ضغط بار مستوي'),
  '0043': (en: 'Barbell Full Squat', ar: 'سكوات'),
  '0292': (en: 'Dumbbell One Arm Bent-over Row', ar: 'منشار'),
};

/// A small two-day program in the programs.json format (docs/DATA.md).
final testProgramJson = <String, dynamic>{
  'id': 'test_ab',
  'name': {'ar': 'برنامج تجربة', 'en': 'Test A/B'},
  'description': {'ar': 'يومين', 'en': 'Two days'},
  'days_per_week': 2,
  'level': 'beginner',
  'routines': [
    {
      'id': 'test_a',
      'name': {'ar': 'يوم أ', 'en': 'Day A'},
      'exercises': [
        {'exercise_id': '0025', 'sets': 4, 'reps': [6, 8], 'rest_seconds': 150},
        {'exercise_id': '0292', 'sets': 3, 'reps': [8, 12], 'rest_seconds': 90},
      ],
    },
    {
      'id': 'test_b',
      'name': {'ar': 'يوم ب', 'en': 'Day B'},
      'exercises': [
        {'exercise_id': '0043', 'sets': 3, 'reps': [5, 5], 'rest_seconds': 180},
      ],
    },
  ],
};

/// Catalog exercises + the test program (catalog tables, test setup only).
Future<void> seedRoutinesCatalog(AppDatabase db) async {
  await db.batch((b) {
    for (final e in routinesTestCatalog.entries) {
      b.insert(
        db.exercises,
        ExercisesCompanion.insert(
          id: e.key,
          nameEn: e.value.en,
          nameAr: Value(e.value.ar),
          bodyPart: 'chest',
          target: 'pectorals',
          equipment: 'barbell',
          instructionsEn: '["step"]',
          mediaId: 'm${e.key}',
          searchNorm: e.value.en.toLowerCase(),
        ),
      );
    }
    b.insert(db.catalogPrograms, CatalogProgramsCompanion.insert(id: 'test_ab', sort: 0, data: jsonEncode(testProgramJson)));
  });
}

/// A finished workout with [exerciseId] and (weight, reps) sets.
Future<String> insertFinished(
  AppDatabase db, {
  required DateTime startedAt,
  required String exerciseId,
  required List<(double, int)> sets,
}) async {
  final wId = newUuid();
  final weId = newUuid();
  await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        id: Value(wId),
        name: 'Past',
        startedAt: Value(startedAt),
        endedAt: Value(startedAt.add(const Duration(hours: 1))),
        status: const Value(WorkoutStatus.finished),
      ));
  await db.into(db.workoutExercises).insert(
        WorkoutExercisesCompanion.insert(id: Value(weId), workoutId: wId, exerciseId: exerciseId),
      );
  for (var i = 0; i < sets.length; i++) {
    await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
          workoutExerciseId: weId,
          sort: Value(i),
          weightKg: Value(sets[i].$1),
          reps: Value(sets[i].$2),
          completedAt: Value(startedAt.add(Duration(minutes: i + 1))),
        ));
  }
  return wId;
}
