import 'dart:io';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/set_labels.dart';
import 'package:azm/core/utils/workout_math.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

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

  group('active workout', () {
    test('start creates ONE active workout; starting again returns it', () async {
      final a = await repo.startEmpty('Evening workout');
      final b = await repo.startEmpty('Another');
      expect(b, a);
      expect((await repo.active())!.name, 'Evening workout');
      final all = await db.select(db.workouts).get();
      expect(all, hasLength(1));
    });

    test('the DB itself rejects a second active workout', () async {
      await repo.startEmpty('A');
      expect(
        () => db.into(db.workouts).insert(WorkoutsCompanion.insert(name: 'B')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('previous-set lookup', () {
    test('same set index from the LAST finished workout with that exercise', () async {
      await insertFinishedWorkout(db,
          startedAt: DateTime.utc(2026, 9, 20), exerciseId: '0025', sets: [(50, 10, SetType.normal)]);
      await insertFinishedWorkout(db, startedAt: DateTime.utc(2026, 9, 24), exerciseId: '0025', sets: [
        (40, 12, SetType.warmup),
        (60, 8, SetType.normal),
        (62.5, 6, SetType.failure),
      ]);
      // A later workout WITHOUT the exercise must not hide it.
      await insertFinishedWorkout(db,
          startedAt: DateTime.utc(2026, 9, 25), exerciseId: '0043', sets: [(100, 5, SetType.normal)]);

      final prev = await repo.previousSets(['0025', '0292'], before: clock.now);
      expect(prev.keys, ['0025']);
      expect([for (final s in prev['0025']!) (s.weightKg, s.reps)], [(40.0, 12), (60.0, 8), (62.5, 6)]);
    });

    test('adding an exercise copies last time\'s set count and types; detail aligns previous by index', () async {
      await insertFinishedWorkout(db, startedAt: DateTime.utc(2026, 9, 24), exerciseId: '0025', sets: [
        (40, 12, SetType.warmup),
        (60, 8, SetType.normal),
      ]);
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025', '0292']);

      final d = (await repo.loadDetail(id))!;
      expect(d.exercises.map((e) => e.entry.exerciseId), ['0025', '0292']);
      final bench = d.exercises.first;
      expect(bench.sets.map((s) => s.type), [SetType.warmup, SetType.normal]);
      expect(bench.sets.every((s) => s.weightKg == 0 && s.reps == 0 && s.completedAt == null), isTrue);
      expect(bench.previousFor(1)!.weightKg, 60);
      expect(bench.previousFor(2), isNull);
      expect(d.exercises.last.sets, hasLength(1)); // new exercise → one normal set
      expect(d.exercises.last.previous, isEmpty);
      expect(bench.exercise!.nameAr, 'ضغط بار مستوي');
    });
  });

  group('logging', () {
    test('every edit is persisted immediately and read back by a fresh detail', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      var set = (await repo.loadDetail(id))!.exercises.first.sets.first;

      await repo.updateSet(set.id, weightKg: 60, reps: 8, type: SetType.drop);
      await repo.setCompleted(set.id, true);
      await repo.addSet(set.workoutExerciseId);

      final d = (await repo.loadDetail(id))!;
      set = d.exercises.first.sets.first;
      expect((set.weightKg, set.reps, set.type), (60.0, 8, SetType.drop));
      expect(set.completedAt, clock.now);
      // The added set copies weight + reps but not the ✓.
      final added = d.exercises.first.sets[1];
      expect((added.weightKg, added.reps, added.completedAt), (60.0, 8, null));
      expect(d.completedSets, 1);
      expect(d.liftedTotalKg, 480);
    });

    test('weights and reps never go negative', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      final set = (await repo.loadDetail(id))!.exercises.first.sets.first;
      await repo.updateSet(set.id, weightKg: -5, reps: -1);
      final s = (await repo.loadDetail(id))!.exercises.first.sets.first;
      expect((s.weightKg, s.reps), (0.0, 0));
    });

    test('delete set, remove exercise, reorder exercises', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025', '0043', '0292']);
      var d = (await repo.loadDetail(id))!;
      await repo.deleteSet(d.exercises.first.sets.first.id);
      await repo.removeExercise(d.exercises[1].entry.id);
      d = (await repo.loadDetail(id))!;
      expect(d.exercises.map((e) => e.entry.exerciseId), ['0025', '0292']);
      expect(d.exercises.first.sets, isEmpty);

      await repo.reorderExercises([d.exercises[1].entry.id, d.exercises[0].entry.id]);
      d = (await repo.loadDetail(id))!;
      expect(d.exercises.map((e) => e.entry.exerciseId), ['0292', '0025']);
    });
  });

  group('finish / discard', () {
    test('finish drops sets without ✓ and empty exercises, then marks finished', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025', '0043']);
      var d = (await repo.loadDetail(id))!;
      final bench = d.exercises.first;
      await repo.addSet(bench.entry.id);
      d = (await repo.loadDetail(id))!;
      await repo.setCompleted(d.exercises.first.sets.first.id, true, weightKg: 60, reps: 8);

      clock.advance(const Duration(minutes: 45));
      expect(await repo.finish(id), isTrue);

      d = (await repo.loadDetail(id))!;
      expect(d.workout.status, WorkoutStatus.finished);
      expect(d.workout.endedAt, clock.now);
      expect(d.exercises.map((e) => e.entry.exerciseId), ['0025']);
      expect(d.exercises.first.sets, hasLength(1));
      expect(await repo.active(), isNull);
    });

    test('finish with nothing completed changes nothing', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      expect(await repo.finish(id), isFalse);
      expect((await repo.active())!.id, id);
    });

    test('discard deletes the workout and cascades', () async {
      final id = await repo.startEmpty('W');
      await repo.addExercises(id, ['0025']);
      await repo.discard(id);
      expect(await db.select(db.workouts).get(), isEmpty);
      expect(await db.select(db.workoutExercises).get(), isEmpty);
      expect(await db.select(db.workoutSets).get(), isEmpty);
    });
  });

  test('PRs in the detail: strict improvement over EARLIER workouts; warm-ups never count', () async {
    await insertFinishedWorkout(db,
        startedAt: DateTime.utc(2026, 9, 24), exerciseId: '0025', sets: [(60, 8, SetType.normal)]);
    final id = await repo.startEmpty('W');
    await repo.addExercises(id, ['0025']);
    var d = (await repo.loadDetail(id))!;
    final ex = d.exercises.first;
    await repo.addSet(ex.entry.id);
    d = (await repo.loadDetail(id))!;
    final sets = d.exercises.first.sets;
    await repo.updateSet(sets[0].id, type: SetType.warmup);
    await repo.setCompleted(sets[0].id, true, weightKg: 100, reps: 5); // warm-up: no PR
    await repo.setCompleted(sets[1].id, true, weightKg: 62.5, reps: 8); // heavier + more volume

    d = (await repo.loadDetail(id))!;
    expect(d.exercises.first.prs, {
      1: {PrType.heaviestWeight, PrType.best1Rm, PrType.bestSetVolume},
    });
    expect(d.prCount, 3);
  });

  test('rest seconds: routine override → settings default → 90 s', () async {
    final id = await repo.startEmpty('W');
    await repo.addExercises(id, ['0025']);
    expect((await repo.loadDetail(id))!.exercises.first.restSeconds, kDefaultRestSeconds);

    await db.writeSetting(TrainingSettingsKeys.defaultRestSeconds, '120');
    expect((await repo.loadDetail(id))!.exercises.first.restSeconds, 120);

    await db.into(db.routines).insert(RoutinesCompanion.insert(id: const Value('r1'), name: 'Push'));
    await db.into(db.routineExercises).insert(RoutineExercisesCompanion.insert(
        routineId: 'r1', exerciseId: '0025', restSeconds: const Value(150)));
    await (db.update(db.workouts)..where((w) => w.id.equals(id)))
        .write(const WorkoutsCompanion(routineId: Value('r1')));
    expect((await repo.loadDetail(id))!.exercises.first.restSeconds, 150);
  });

  test('unit setting lb is read for display', () async {
    expect((await repo.weightUnit()).name, 'kg');
    await db.writeSetting(TrainingSettingsKeys.unit, '"lb"');
    final id = await repo.startEmpty('W');
    expect((await repo.loadDetail(id))!.unit.name, 'lb');
  });

  test('resume after app kill: a new DB connection on the same file sees everything', () async {
    final dir = await Directory.systemTemp.createTemp('azm_resume');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/azm.sqlite');

    final db1 = AppDatabase(NativeDatabase(file));
    final repo1 = WorkoutRepository(db1, clock: clock.call);
    await insertCatalog(db1, testCatalog);
    final id = await repo1.startEmpty('W');
    await repo1.addExercises(id, ['0025']);
    final set = (await repo1.loadDetail(id))!.exercises.first.sets.first;
    await repo1.setCompleted(set.id, true, weightKg: 70, reps: 6);
    await db1.close(); // "kill"

    final db2 = AppDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = WorkoutRepository(db2, clock: clock.call);
    final active = await repo2.active();
    expect(active!.id, id);
    final s = (await repo2.loadDetail(id))!.exercises.first.sets.first;
    expect((s.weightKg, s.reps, s.completedAt != null), (70.0, 6, true));
  });

  test('watchDetail re-emits on every change', () async {
    final id = await repo.startEmpty('W');
    final emissions = <int>[];
    final sub = repo.watchDetail(id).listen((d) => emissions.add(d!.exercises.length));
    await pumpEventQueue();
    await repo.addExercises(id, ['0025']);
    await pumpEventQueue();
    await sub.cancel();
    expect(emissions.first, 0);
    expect(emissions.last, 1);
  });

  test('normal set numbers skip other types; best set uses e1RM', () async {
    WorkoutSet s(SetType t, double w, int r, {bool done = true}) => WorkoutSet(prefilled: false, 
          id: newUuid(),
          workoutExerciseId: 'x',
          sort: 0,
          type: t,
          weightKg: w,
          reps: r,
          completedAt: done ? DateTime.utc(2026) : null,
        );
    final sets = [
      s(SetType.warmup, 40, 12),
      s(SetType.normal, 60, 8),
      s(SetType.drop, 50, 10),
      s(SetType.normal, 70, 3),
      s(SetType.normal, 90, 1, done: false),
    ];
    expect(normalSetNumbers(sets.map((s) => s.type)), [null, 1, null, 2, 3]);
    expect(bestSet(sets), sets[3]); // 70×3 → e1RM 77 beats 60×8 → 76; the unfinished 90×1 is ignored
  });
}
