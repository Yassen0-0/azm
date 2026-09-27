import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/routines/data/ready_programs.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'routines_test_helpers.dart';

void main() {
  late AppDatabase db;
  late RoutineRepository repo;

  setUp(() async {
    db = openRoutinesTestDb();
    repo = RoutineRepository(db);
    await seedRoutinesCatalog(db);
  });
  tearDown(() => db.close());

  Future<RoutineDetail> detail(String id) async => (await repo.loadDetail(id))!;

  group('routine CRUD', () {
    test('create → rename → notes → list order', () async {
      final a = await repo.create();
      final b = await repo.create(name: 'Legs');
      await repo.rename(a, 'Push');
      await repo.setNotes(a, 'heavy week');
      final list = await repo.loadRoutines();
      expect([for (final r in list) r.routine.name], ['Push', 'Legs']);
      expect(list.first.routine.notes, 'heavy week');
      await repo.setNotes(a, '   ');
      expect((await detail(a)).routine.notes, isNull);
      expect(b, isNot(a));
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(a), isTrue); // uuid v4 text
    });

    test('add exercises (selection order, 3 empty sets each), add/update/delete sets', () async {
      final id = await repo.create(name: 'Push');
      await repo.addExercises(id, ['0292', '0025']);
      var d = await detail(id);
      expect([for (final e in d.exercises) e.entry.exerciseId], ['0292', '0025']);
      expect(d.exercises.first.sets, hasLength(kNewRoutineExerciseSets));
      expect(d.exercises.first.sets.every((s) => s.targetReps == null && s.targetWeightKg == null), isTrue);
      expect(d.exercises.first.exercise?.nameEn, 'Dumbbell One Arm Bent-over Row');

      final first = d.exercises.first.sets.first;
      await repo.updateSet(first.id, targetReps: 10, targetWeightKg: 22.5, type: SetType.warmup);
      final last = d.exercises.first.sets.last;
      await repo.updateSet(last.id, targetReps: 8, targetWeightKg: 30);
      await repo.addSet(d.exercises.first.entry.id); // copies the last set's targets
      d = await detail(id);
      final sets = d.exercises.first.sets;
      expect(sets, hasLength(4));
      expect((sets[0].type, sets[0].targetReps, sets[0].targetWeightKg), (SetType.warmup, 10, 22.5));
      expect((sets[3].type, sets[3].targetReps, sets[3].targetWeightKg), (SetType.normal, 8, 30.0));

      await repo.updateSet(sets[0].id, clearWeight: true);
      await repo.updateSet(sets[0].id, targetReps: 0); // 0 → no target
      await repo.deleteSet(sets[1].id);
      d = await detail(id);
      expect(d.exercises.first.sets, hasLength(3));
      expect((d.exercises.first.sets[0].targetReps, d.exercises.first.sets[0].targetWeightKg), (null, null));
    });

    test('reorder, rest override and remove are persisted', () async {
      final id = await repo.create(name: 'Push');
      await repo.addExercises(id, ['0025', '0043', '0292']);
      var d = await detail(id);
      final ids = [for (final e in d.exercises) e.entry.id];
      await repo.reorderExercises([ids[2], ids[0], ids[1]]);
      await repo.setRestSeconds(ids[0], 150);
      d = await RoutineRepository(db).loadDetail(id).then((v) => v!); // fresh read from the DB
      expect([for (final e in d.exercises) e.entry.exerciseId], ['0292', '0025', '0043']);
      expect(d.exercises[1].entry.restSeconds, 150);
      await repo.setRestSeconds(ids[0], null);
      await repo.removeExercise(ids[1]);
      d = await detail(id);
      expect([for (final e in d.exercises) e.entry.exerciseId], ['0292', '0025']);
      expect(d.exercises[1].entry.restSeconds, isNull);
      expect(await db.select(db.routineSets).get(), hasLength(6));
    });

    test('delete cascades to exercises and sets; blank detection', () async {
      final id = await repo.create();
      expect(await repo.isBlank(id), isTrue);
      await repo.addExercises(id, ['0025']);
      expect(await repo.isBlank(id), isFalse);
      await repo.delete(id);
      expect(await repo.loadDetail(id), isNull);
      expect(await db.select(db.routineExercises).get(), isEmpty);
      expect(await db.select(db.routineSets).get(), isEmpty);
    });

    test('watching routines never starves the workout detail stream (distinct SQL)', () async {
      final workouts = WorkoutRepository(db);
      final routinesSub = repo.watchRoutines().listen((_) {});
      final id = await workouts.startEmpty('Evening');
      final counts = <int>[];
      final sub = workouts.watchDetail(id).listen((d) => counts.add(d?.exercises.length ?? -1));
      await pumpEventQueue();
      await workouts.addExercises(id, ['0025']);
      await pumpEventQueue();
      await sub.cancel();
      await routinesSub.cancel();
      expect(counts.last, 1);
    });

    test('watchRoutines re-emits on edits', () async {
      final events = <int>[];
      final sub = repo.watchRoutines().listen((l) => events.add(l.length));
      await pumpEventQueue();
      await repo.create(name: 'A');
      await pumpEventQueue();
      await sub.cancel();
      expect(events.first, 0);
      expect(events.last, 1);
    });
  });

  group('ready programs', () {
    test('copy: one routine per day, names per language, target_reps = range max, rest', () async {
      final program = ReadyProgram.fromJson(testProgramJson);
      final ar = await repo.copyProgram(program, languageCode: 'ar');
      expect(ar, hasLength(2));
      var list = await repo.loadRoutines();
      expect([for (final r in list) r.routine.name], ['يوم أ', 'يوم ب']);
      final a = await detail(ar.first);
      expect([for (final e in a.exercises) e.entry.exerciseId], ['0025', '0292']);
      expect(a.exercises[0].sets, hasLength(4));
      expect(a.exercises[0].sets.every((s) => s.targetReps == 8 && s.type == SetType.normal), isTrue);
      expect(a.exercises[1].sets.every((s) => s.targetReps == 12), isTrue);
      expect(a.exercises[0].entry.restSeconds, 150);
      expect((await detail(ar.last)).exercises.single.sets.every((s) => s.targetReps == 5), isTrue);

      // English, and twice: independent copies.
      final en = await repo.copyProgram(program, languageCode: 'en');
      list = await repo.loadRoutines();
      expect([for (final r in list) r.routine.name], ['يوم أ', 'يوم ب', 'Day A', 'Day B']);
      expect(en.toSet().intersection(ar.toSet()), isEmpty);
      await repo.rename(en.first, 'Mine');
      await repo.deleteSet((await detail(en.first)).exercises.first.sets.first.id);
      expect((await detail(ar.first)).routine.name, 'يوم أ');
      expect((await detail(ar.first)).exercises.first.sets, hasLength(4));
    });

    test('programs parse from the catalog table', () async {
      final raw = await db.select(db.catalogPrograms).get();
      expect(raw, hasLength(1));
      final p = ReadyProgram.fromJson(testProgramJson);
      expect(p.days.first.exercises.first.repsMin, 6);
      expect(p.name.of('ar'), 'برنامج تجربة');
      expect(p.name.of('en'), 'Test A/B');
      expect(p.exerciseIds, {'0025', '0292', '0043'});
    });
  });

  group('start from a routine', () {
    test('prefills sets from targets, sets routine_id, weights fall back to last time', () async {
      await insertFinished(
        db,
        startedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        exerciseId: '0025',
        sets: [(60, 8), (62.5, 6)],
      );
      final id = await repo.create(name: 'Push');
      await repo.addExercises(id, ['0025', '0043']);
      var d = await detail(id);
      final bench = d.exercises[0].sets;
      await repo.updateSet(bench[0].id, type: SetType.warmup, targetReps: 12, targetWeightKg: 40);
      await repo.updateSet(bench[1].id, targetReps: 8);
      await repo.updateSet(bench[2].id, targetReps: 8);
      await repo.setRestSeconds(d.exercises[0].entry.id, 150);
      d = await detail(id);

      final start = await repo.start(id, fallbackName: 'Untitled');
      expect(start.resumed, isFalse);
      final workouts = WorkoutRepository(db);
      final w = (await workouts.active())!;
      expect((w.id, w.routineId, w.name), (start.workoutId, id, 'Push'));
      final wd = (await workouts.loadDetail(w.id))!;
      expect([for (final e in wd.exercises) e.entry.exerciseId], ['0025', '0043']);
      final ws = wd.exercises[0].sets;
      expect([for (final s in ws) (s.type, s.weightKg, s.reps, s.completedAt)], [
        (SetType.warmup, 40.0, 12, null), // targets
        (SetType.normal, 62.5, 8, null), // weight from set 2 last time
        (SetType.normal, 0.0, 8, null), // no set 3 last time
      ]);
      expect(wd.exercises[1].sets.every((s) => s.reps == 0 && s.weightKg == 0), isTrue);
      // "previous" is still computed by the workout feature, and the routine rest applies.
      expect(wd.exercises[0].previous, hasLength(2));
      expect(wd.exercises[0].restSeconds, 150);
    });

    test('one active workout: starting again resumes it', () async {
      final id = await repo.create(name: 'Push');
      await repo.addExercises(id, ['0025']);
      final emptyId = await WorkoutRepository(db).startEmpty('Evening');
      final again = await repo.start(id, fallbackName: 'x');
      expect(again, (workoutId: emptyId, resumed: true));
      expect(await db.select(db.workouts).get(), hasLength(1));
      expect(await db.select(db.workoutExercises).get(), isEmpty);
    });

    test('an unnamed routine uses the fallback name', () async {
      final id = await repo.create();
      await repo.addExercises(id, ['0025']);
      await repo.start(id, fallbackName: 'Untitled routine');
      expect((await WorkoutRepository(db).active())!.name, 'Untitled routine');
    });
  });
}
