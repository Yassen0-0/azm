import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/history/data/history_repository.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/settings/data/backup/backup_codec.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

/// UI overhaul (PLAN §14), data side: schema v3 (per-workout rest incl. OFF,
/// pre-filled set values), notes, editable start / end times, backup v2.
void main() {
  late AppDatabase db;
  late WorkoutRepository repo;
  late TestClock clock;

  setUp(() async {
    db = openTestDb();
    clock = TestClock(DateTime.utc(2026, 9, 26, 18));
    repo = WorkoutRepository(db, clock: clock.call);
    await insertCatalog(db, testCatalog);
  });
  tearDown(() => db.close());

  Future<WorkoutDetail> detail(String id) async => (await repo.loadDetail(id))!;

  test('schema v2 → v3 adds rest_seconds + prefilled and keeps rows', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE exercises (id TEXT NOT NULL PRIMARY KEY, hidden INTEGER NOT NULL DEFAULT 0)');
      raw.execute('CREATE TABLE workout_exercises (id TEXT NOT NULL PRIMARY KEY, workout_id TEXT NOT NULL, '
          'exercise_id TEXT NOT NULL, sort INTEGER NOT NULL DEFAULT 0, notes TEXT)');
      raw.execute('CREATE TABLE workout_sets (id TEXT NOT NULL PRIMARY KEY, workout_exercise_id TEXT NOT NULL, '
          "sort INTEGER NOT NULL DEFAULT 0, type TEXT NOT NULL DEFAULT 'normal', weight_kg REAL NOT NULL DEFAULT 0, "
          'reps INTEGER NOT NULL DEFAULT 0, completed_at TEXT)');
      raw.execute("INSERT INTO workout_exercises (id, workout_id, exercise_id) VALUES ('e', 'w', '0025')");
      raw.execute("INSERT INTO workout_sets (id, workout_exercise_id, weight_kg, reps) VALUES ('s', 'e', 60, 8)");
      raw.userVersion = 2;
    }));
    addTearDown(old.close);
    final e = await old.select(old.workoutExercises).getSingle();
    final s = await old.select(old.workoutSets).getSingle();
    expect(e.restSeconds, isNull);
    expect((s.weightKg, s.reps, s.prefilled), (60.0, 8, false));
  });

  group('routine start', () {
    test('copies the rest override; targets are pre-filled (muted) until edited', () async {
      final routines = RoutineRepository(db, clock: clock.call);
      final rid = await routines.create(name: 'Upper');
      await routines.addExercises(rid, ['0025', '0043']);
      final r = (await routines.loadDetail(rid))!;
      await routines.setRestSeconds(r.exercises[0].entry.id, 120);
      await routines.updateSet(r.exercises[0].sets[0].id, targetReps: 8, targetWeightKg: 15);

      final start = await routines.start(rid, fallbackName: 'x');
      final d = await detail(start.workoutId);
      expect(d.exercises[0].restSeconds, 120);
      expect(d.exercises[0].restIsOverride, isTrue);
      final s = d.exercises[0].sets[0];
      expect((s.weightKg, s.reps, s.prefilled), (15.0, 8, true));
      // Sets without any target start empty (not pre-filled: the hint shows).
      expect(d.exercises[1].sets[0].prefilled, isFalse);

      await repo.updateSet(s.id, reps: 10);
      expect((await detail(start.workoutId)).exercises[0].sets[0].prefilled, isFalse);
      final s2 = d.exercises[0].sets.last;
      await repo.updateSet(s2.id, weightKg: 20);
      await repo.addSet(d.exercises[0].entry.id);
      final after = (await detail(start.workoutId)).exercises[0].sets;
      expect(after.last.weightKg, 20);
      expect(after.last.prefilled, isTrue, reason: '"Add set" copies are suggestions');
    });
  });

  group('per-exercise rest + notes', () {
    test('override wins over the default; 0 = OFF; null = back to default', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      var e = (await detail(id)).exercises.single;
      expect((e.restSeconds, e.restIsOverride, e.restOff), (90, false, false));

      await repo.setExerciseRest(e.entry.id, 0);
      e = (await detail(id)).exercises.single;
      expect((e.restSeconds, e.restIsOverride, e.restOff), (0, true, true));

      await repo.setExerciseRest(e.entry.id, 45);
      expect((await detail(id)).exercises.single.restSeconds, 45);

      await repo.setExerciseRest(e.entry.id, null);
      expect((await detail(id)).exercises.single.restIsOverride, isFalse);
    });

    test('notes are saved per exercise; blank clears them', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      final we = (await detail(id)).exercises.single.entry.id;
      await repo.setExerciseNotes(we, 'seat 4');
      expect((await detail(id)).exercises.single.entry.notes, 'seat 4');
      await repo.setExerciseNotes(we, '   ');
      expect((await detail(id)).exercises.single.entry.notes, isNull);
    });
  });

  group('editable times', () {
    test('active: start moves back, never into the future', () async {
      final id = await repo.startEmpty('W');
      await repo.setStartedAt(id, clock.now.subtract(const Duration(minutes: 50)));
      expect((await detail(id)).workout.startedAt, DateTime.utc(2026, 9, 26, 17, 10));
      await repo.setStartedAt(id, clock.now.add(const Duration(hours: 2)));
      expect((await detail(id)).workout.startedAt, clock.now);
    });

    test('finished: start < end ≤ now, else nothing changes', () async {
      final wid = await insertFinishedWorkout(db,
          startedAt: DateTime.utc(2026, 9, 20, 18), exerciseId: '0025', sets: [(60, 8, SetType.normal)]);
      final s = DateTime.utc(2026, 9, 20, 17);
      expect(await repo.setTimes(wid, start: s, end: s.add(const Duration(minutes: 75))), isTrue);
      var w = (await detail(wid)).workout;
      expect((w.startedAt, w.endedAt), (s, DateTime.utc(2026, 9, 20, 18, 15)));

      expect(await repo.setTimes(wid, start: s, end: s), isFalse, reason: 'end must be after start');
      expect(await repo.setTimes(wid, start: s, end: clock.now.add(const Duration(minutes: 1))), isFalse,
          reason: 'end in the future');
      w = (await detail(wid)).workout;
      expect(w.endedAt, DateTime.utc(2026, 9, 20, 18, 15));

      // History reads the new duration.
      final history = await HistoryRepository(db).watchHistory().first;
      expect(history.workouts.single.duration, const Duration(minutes: 75));
    });

    test('validation helpers', () {
      final now = DateTime.utc(2026, 9, 26, 18);
      expect(workoutTimesValid(start: now, now: now), isTrue);
      expect(workoutTimesValid(start: now.add(const Duration(seconds: 1)), now: now), isFalse);
      expect(workoutTimesValid(start: now.subtract(const Duration(hours: 1)), end: now, now: now), isTrue);
      final c = clampWorkoutTimes(start: now, end: now.subtract(const Duration(hours: 1)), now: now);
      expect(c.start, now.subtract(const Duration(hours: 1, minutes: 1)));
    });
  });

  group('backup v2', () {
    test('rest_seconds + prefilled round-trip; v1 files still import', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      final e = (await detail(id)).exercises.single;
      await repo.setExerciseRest(e.entry.id, 0);
      await (db.update(db.workoutSets)..where((s) => s.id.equals(e.sets.single.id)))
          .write(const WorkoutSetsCompanion(prefilled: Value(true)));

      final contents = BackupContents(
        exportedAt: clock.now,
        appVersion: 't',
        settings: const {},
        routines: const [],
        routineExercises: const [],
        routineSets: const [],
        workouts: await db.select(db.workouts).get(),
        workoutExercises: await db.select(db.workoutExercises).get(),
        workoutSets: await db.select(db.workoutSets).get(),
      );
      final text = encodeBackup(contents);
      final back = decodeBackup(text);
      expect(back.workoutExercises.single.restSeconds, 0);
      expect(back.workoutSets.single.prefilled, isTrue);

      // The same file as a v1 build wrote it (no new columns).
      final json = jsonDecode(text) as Map<String, dynamic>;
      json['version'] = 1;
      for (final r in json['workout_exercises'] as List) {
        (r as Map).remove('rest_seconds');
      }
      for (final r in json['workout_sets'] as List) {
        (r as Map).remove('prefilled');
      }
      final v1 = decodeBackup(jsonEncode(json));
      expect(v1.workoutExercises.single.restSeconds, isNull);
      expect(v1.workoutSets.single.prefilled, isFalse);

      // A v2 file missing a new column is damaged.
      json['version'] = 2;
      expect(() => decodeBackup(jsonEncode(json)), throwsA(isA<BackupException>()));
    });
  });
}
