import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/utils/workout_math.dart';
import 'package:azm/features/exercises/data/exercise_history.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

void main() {
  late AppDatabase db;
  late DbExerciseHistorySource source;

  setUp(() {
    db = openEmptyDb();
    source = DbExerciseHistorySource(db);
  });
  tearDown(() => db.close());

  test('no history → empty, no records', () async {
    final h = await source.watchExercise('0025').first;
    expect(h.isEmpty, isTrue);
    expect(h.records.heaviestKg, 0);
    expect(await source.watchRecords().first, isEmpty);
  });

  test('only completed sets of finished workouts, newest first, in logged order', () async {
    await seedWorkout(
      db,
      exerciseId: '0025',
      name: 'Old',
      startedAt: DateTime.utc(2026, 9, 1),
      sets: [
        (SetType.warmup, 40, 10, true),
        (SetType.normal, 60, 8, true),
        (SetType.normal, 65, 6, false), // not ✓ → ignored
      ],
    );
    await seedWorkout(
      db,
      exerciseId: '0025',
      name: 'New',
      startedAt: DateTime.utc(2026, 9, 8),
      sets: [(SetType.normal, 70, 5, true), (SetType.failure, 60, 9, true)],
    );
    // Active workout and another exercise are ignored.
    await seedWorkout(
      db,
      exerciseId: '0025',
      status: WorkoutStatus.active,
      startedAt: DateTime.utc(2026, 9, 9),
      sets: [(SetType.normal, 200, 1, true)],
    );
    await seedWorkout(
      db,
      exerciseId: '0032',
      startedAt: DateTime.utc(2026, 9, 2),
      sets: [(SetType.normal, 100, 5, true)],
    );

    final h = await source.watchExercise('0025').first;
    expect([for (final s in h.sessions) s.workoutName], ['New', 'Old']);
    expect(
      [for (final s in h.sessions.last.sets) (s.type, s.weightKg, s.reps)],
      [(SetType.warmup, 40.0, 10), (SetType.normal, 60.0, 8)],
    );
    expect(h.records.heaviestKg, 70);
    expect(h.records.best1RmKg, closeTo(epley1Rm(70, 5), 1e-9)); // 81.7 beats 60×9 (78) and 60×8 (76)
    expect(h.records.bestVolumeKg, 540); // 60 × 9
    // Session volume counts warm-ups (like Lifted).
    expect(h.sessions.last.volumeKg, 40 * 10 + 60 * 8);
  });

  test('warm-ups never count toward records', () async {
    await seedWorkout(
      db,
      exerciseId: '0025',
      startedAt: DateTime.utc(2026, 9, 1),
      sets: [(SetType.warmup, 100, 10, true), (SetType.normal, 50, 5, true)],
    );
    final h = await source.watchExercise('0025').first;
    expect(h.records.heaviestKg, 50);
    final all = await source.watchRecords().first;
    expect(all['0025']!.heaviestKg, 50);
  });

  test('SQL records match PrBests.fromSets for every exercise', () async {
    await seedWorkout(
      db,
      exerciseId: '0025',
      startedAt: DateTime.utc(2026, 9, 1),
      sets: [(SetType.normal, 60, 8, true), (SetType.normal, 80, 1, true), (SetType.drop, 50, 12, true)],
    );
    await seedWorkout(
      db,
      exerciseId: '0032',
      startedAt: DateTime.utc(2026, 9, 3),
      sets: [
        (SetType.normal, 100, 5, true),
        (SetType.normal, 0, 12, true), // bodyweight, no added weight → not a record
      ],
    );
    final all = await source.watchRecords().first;
    expect(all.keys, unorderedEquals(['0025', '0032']));
    for (final id in all.keys) {
      final expected = (await source.watchExercise(id).first).records;
      expect(all[id]!.heaviestKg, closeTo(expected.heaviestKg, 1e-9));
      expect(all[id]!.best1RmKg, closeTo(expected.best1RmKg, 1e-9));
      expect(all[id]!.bestVolumeKg, closeTo(expected.bestVolumeKg, 1e-9));
    }
    expect(all['0025']!.best1RmKg, closeTo(80, 1e-9)); // 80×1 = 80 > 60×(1+8/30)=76
  });

  test('streams emit again when a workout is finished', () async {
    final stream = source.watchExercise('0025');
    final seen = <int>[];
    final sub = stream.listen((h) => seen.add(h.sessions.length));
    await pumpEventQueue();
    final id = await seedWorkout(
      db,
      exerciseId: '0025',
      status: WorkoutStatus.active,
      startedAt: DateTime.utc(2026, 9, 1),
      sets: [(SetType.normal, 60, 8, true)],
    );
    await pumpEventQueue();
    await (db.update(
      db.workouts,
    )..where((w) => w.id.equals(id))).write(const WorkoutsCompanion(status: Value(WorkoutStatus.finished)));
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });
}
