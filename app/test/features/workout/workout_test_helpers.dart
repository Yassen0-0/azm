import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// In-memory DB (same schema + partial unique index as on device).
AppDatabase openTestDb() {
  // Tests open many short-lived databases on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Minimal catalog rows so names/thumbnails resolve.
Future<void> insertCatalog(AppDatabase db, Map<String, ({String en, String? ar})> rows) async {
  await db.batch((b) {
    for (final e in rows.entries) {
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
  });
}

const testCatalog = {
  '0025': (en: 'Barbell Bench Press', ar: 'ضغط بار مستوي'),
  '0043': (en: 'Barbell Full Squat', ar: 'سكوات'),
  '0292': (en: 'Dumbbell One Arm Bent-over Row', ar: 'منشار'),
};

/// Mutable wall clock for tests.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

/// Records every call the rest timer makes to the OS.
class FakeRestAlarm implements RestAlarm {
  final scheduled = <int, DateTime>{};
  final cancelled = <int>[];
  final shown = <int>[];
  var permissionRequests = 0;
  var exactAlarmRequests = 0;
  bool late = false;
  bool enabled = true;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> schedule({required int id, required DateTime at, required RestAlarmText text}) async {
    scheduled[id] = at;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> showNow({required int id, required RestAlarmText text}) async => shown.add(id);

  @override
  Future<bool> mayBeLate() async => late;

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<void> requestExactAlarms() async => exactAlarmRequests++;
}

/// A finished workout with one exercise and the given (weight, reps, type) sets.
Future<String> insertFinishedWorkout(
  AppDatabase db, {
  required DateTime startedAt,
  required String exerciseId,
  required List<(double, int, SetType)> sets,
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
          type: Value(sets[i].$3),
          completedAt: Value(startedAt.add(Duration(minutes: i + 1))),
        ));
  }
  return wId;
}
