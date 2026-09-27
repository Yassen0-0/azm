import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/exercises/data/exercise_history.dart';
import 'package:azm/features/history/data/history_exercise_source.dart';
import 'package:azm/features/history/data/history_models.dart';
import 'package:azm/features/history/data/history_repository.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'history_test_helpers.dart';

const bench = '0025';
const squat = '0043';

void main() {
  late AppDatabase db;
  late HistoryRepository history;
  late WorkoutRepository sets;

  final t0 = DateTime.utc(2026, 9, 1, 17);
  DateTime day(int d) => t0.add(Duration(days: d));

  setUp(() async {
    db = openTestDb();
    history = HistoryRepository(db);
    sets = WorkoutRepository(db, clock: () => DateTime.utc(2026, 9, 27));
    await insertCatalog(db, testCatalog);
  });
  tearDown(() => db.close());

  Future<HistoryData> load() => history.watchHistory().first;
  HistoryWorkout byId(HistoryData d, String id) => d.workouts.firstWhere((w) => w.id == id);

  group('Lifted', () {
    test('all-time total = Σ weight × reps of completed sets, warm-ups included', () async {
      await seedWorkout(db, startedAt: day(0), exercises: {
        bench: [warm(40, 10), n(60, 8)], // 400 + 480
        squat: [n(100, 5)], // 500
      });
      await seedWorkout(db, startedAt: day(2), exercises: {
        bench: [n(62.5, 8), n(0, 12)], // 500 + bodyweight 0
      });
      final d = await load();
      expect(d.liftedKg, 1880);
      expect(d.workouts.map((w) => w.liftedKg), [500, 1380]); // newest first
      expect(d.setCount, 5);
    });

    test('the active workout and unticked sets never count', () async {
      await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      final active = await sets.startEmpty('Now');
      await sets.addExercises(active, [bench]);
      final id = (await sets.loadDetail(active))!.exercises.first.sets.first.id;
      await sets.setCompleted(id, true, weightKg: 200, reps: 10);
      final d = await load();
      expect(d.workouts, hasLength(1));
      expect(d.liftedKg, 480);
    });
  });

  group('PRs', () {
    test('counted per workout versus every EARLIER workout; best set per exercise', () async {
      final a = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8), n(60, 6)]});
      final b = await seedWorkout(db, startedAt: day(2), exercises: {bench: [n(65, 5), n(55, 12)]});
      final d = await load();
      // First workout: every eligible best is a PR (one set holds all three).
      expect(byId(d, a).prCount, 1);
      // 65×5: heaviest + e1RM (75.8 > 76? no: 65×(1+5/30)=75.8 < 76) → heaviest only;
      // 55×12: volume 660 > 480 and e1RM 77 > 76 → one more PR set.
      expect(byId(d, b).prCount, 2);
      expect(byId(d, b).exercises.single.best!.weightKg, 55); // highest e1RM
    });

    test('editing an OLD workout recomputes the PRs of later workouts', () async {
      final old = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      final later = await seedWorkout(db, startedAt: day(3), exercises: {bench: [n(70, 8)]});
      expect(byId(await load(), later).prCount, 1);

      // Fix a typo in the old workout: it was 80 kg, not 60.
      final setId = (await setIds(db, old, bench)).single;
      await sets.updateSet(setId, weightKg: 80);
      final d = await load();
      expect(byId(d, later).prCount, 0);
      expect(byId(d, old).prCount, 1);
      expect(d.records.single.bests.heaviestKg, 80);
    });

    test('workouts with the same start time do not count against each other', () async {
      final a = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      final b = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(50, 8)]});
      final d = await load();
      expect(byId(d, a).prCount, 1);
      expect(byId(d, b).prCount, 1);
    });

    test('warm-ups never count as PRs; records sorted by last use', () async {
      await seedWorkout(db, startedAt: day(0), exercises: {squat: [n(100, 5)]});
      final w = await seedWorkout(db, startedAt: day(1), exercises: {bench: [warm(100, 10)]});
      final d = await load();
      expect(byId(d, w).prCount, 0);
      expect(d.records.map((r) => r.exerciseId), [squat]); // bench has only a warm-up
    });
  });

  group('edits of past workouts', () {
    test('set edits are persisted and the history stream re-emits', () async {
      final w = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      final seen = <double>[];
      final sub = history.watchHistory().listen((d) => seen.add(d.liftedKg));
      await pumpEventQueue();
      final id = (await setIds(db, w, bench)).single;
      await sets.updateSet(id, reps: 10);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [480, 600]);
      final row = await (db.select(db.workoutSets)..where((s) => s.id.equals(id))).getSingle();
      expect(row.reps, 10);
    });

    test('writes made in a transaction (like finish()) re-emit, with names', () async {
      final seen = <HistoryData>[];
      final sub = history.watchHistory().listen(seen.add);
      await pumpEventQueue();
      await db.transaction(() => seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]}));
      for (var i = 0; i < 50 && (seen.isEmpty || seen.last.isEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await sub.cancel();
      expect(seen.last.workouts, hasLength(1));
      expect(seen.last.exercises[bench]?.nameEn, 'Barbell Bench Press');
    });

    test('ticking sets in the active workout does not re-emit the history', () async {
      await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      var emits = 0;
      final sub = history.watchHistory().listen((_) => emits++);
      await pumpEventQueue();
      final active = await sets.startEmpty('Now');
      await sets.addExercises(active, [bench]);
      await pumpEventQueue();
      await sub.cancel();
      expect(emits, 1);
    });

    test('rename / delete touch finished workouts only', () async {
      final done = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      final active = await sets.startEmpty('Live');
      await history.rename(done, '  Chest day ');
      await history.rename(active, 'Hacked');
      await history.rename(done, '   '); // ignored
      await history.delete(active);
      final rows = {for (final w in await db.select(db.workouts).get()) w.id: w.name};
      expect(rows, {done: 'Chest day', active: 'Live'});

      await history.delete(done);
      expect((await db.select(db.workouts).get()).map((w) => w.id), [active]);
      expect(await db.select(db.workoutSets).get(), isEmpty); // cascade
    });

    test('added sets are logged; nothing is ever removed automatically', () async {
      final w = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)], squat: [n(100, 5)]});
      final benchEntry = (await sets.loadDetail(w))!.exercises.first.entry.id;
      await history.addLoggedSet(benchEntry, day(0));
      final bench0 = (await sets.loadDetail(w))!.exercises.first.sets;
      expect(bench0.map((s) => (s.weightKg, s.reps, s.completedAt != null)), [(60.0, 8, true), (60.0, 8, true)]);

      await sets.updateSet(bench0[0].id, reps: 0); // emptied: stays, the user swipes it away if wanted
      await sets.addExercises(w, [squat]); // a second squat entry, unticked
      final logged = await history.logUnticked(w);
      expect(logged, hasLength(1));
      final d = (await sets.loadDetail(w))!;
      expect(d.exercises.map((e) => e.entry.exerciseId), [bench, squat, squat]);
      expect(d.allSets.every((s) => s.completedAt != null), isTrue);
      expect(d.exercises.first.sets.map((s) => s.reps), [0, 8]);
      // No earlier workout with squat: the new set is logged empty (0 × 0).
      expect(d.exercises.last.sets.map((s) => (s.weightKg, s.reps)), [(0.0, 0)]);
      expect(await history.logUnticked(w), isEmpty);
    });

    test('logUnticked fills a new exercise from the workout before and never touches the active one', () async {
      await seedWorkout(db, startedAt: day(0), exercises: {squat: [n(100, 5), n(110, 3)]});
      final w = await seedWorkout(db, startedAt: day(2), exercises: {bench: [n(60, 8)]});
      final active = await sets.startEmpty('Now');
      await sets.addExercises(active, [bench]);
      await sets.addExercises(w, [squat]);
      await history.logUnticked(w);
      final squatSets = (await sets.loadDetail(w))!.exercises.last.sets;
      expect(squatSets.map((s) => (s.weightKg, s.reps, s.completedAt != null)), [(100.0, 5, true), (110.0, 3, true)]);
      expect(await history.logUnticked(active), isEmpty);
      expect((await sets.loadDetail(active))!.allSets.every((s) => s.completedAt == null), isTrue);
    });
  });

  group('exercise history hook', () {
    test('createExerciseHistorySource is the history source with the default rules', () async {
      final source = createExerciseHistorySource(db);
      expect(source, isA<HistoryExerciseSource>());
      final w = await seedWorkout(db, startedAt: day(0), exercises: {bench: [warm(40, 10), n(60, 8)]});
      await seedWorkout(db, startedAt: day(2), exercises: {bench: [n(62.5, 6)]});
      final mine = await source.watchExercise(bench).first;
      final def = await DbExerciseHistorySource(db).watchExercise(bench).first;
      expect(sameExerciseHistory(mine, def), isTrue);
      expect(mine.sessions.map((s) => s.sets.length), [1, 2]);

      // A set emptied while editing a past workout isn't history.
      await sets.updateSet((await setIds(db, w, bench)).last, reps: 0);
      final after = await source.watchExercise(bench).first;
      expect(after.sessions.last.sets.map((s) => s.type), [SetType.warmup]);
      expect(sameRecords(await source.watchRecords().first, await DbExerciseHistorySource(db).watchRecords().first), isTrue);
    });

    test('emits edits of past workouts, skips unchanged re-emits', () async {
      final w = await seedWorkout(db, startedAt: day(0), exercises: {bench: [n(60, 8)]});
      final source = createExerciseHistorySource(db);
      final records = <double>[];
      final sub = source.watchExercise(bench).listen((h) => records.add(h.records.heaviestKg));
      await pumpEventQueue();
      final active = await sets.startEmpty('Now'); // unrelated change
      await sets.addExercises(active, [squat]);
      await pumpEventQueue();
      await sets.updateSet((await setIds(db, w, bench)).single, weightKg: 70);
      await pumpEventQueue();
      await sub.cancel();
      expect(records, [60, 70]);
    });
  });
}
