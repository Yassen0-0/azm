import 'package:azm/core/utils/workout_math.dart';
import 'package:flutter_test/flutter_test.dart';

SetStats s(double w, int r, {bool done = true, SetType type = SetType.normal}) =>
    SetStats(weightKg: w, reps: r, completed: done, type: type);

void main() {
  group('Lifted total', () {
    test('sums weight × reps of completed sets, warm-ups INCLUDED', () {
      final sets = [
        s(40, 10, type: SetType.warmup), // 400
        s(60, 8), // 480
        s(60, 8, type: SetType.failure), // 480
        s(50, 12, type: SetType.drop), // 600
        s(100, 5, done: false), // not ✓ → 0
      ];
      expect(liftedKg(sets), 1960);
    });

    test('bodyweight exercise counts only added weight', () {
      expect(liftedKg([s(0, 12), s(10, 8)]), 80);
    });

    test('empty / invalid sets → 0', () {
      expect(liftedKg(const []), 0);
      expect(liftedKg([s(-5, 10), s(50, 0)]), 0);
    });
  });

  group('Epley e1RM', () {
    test('w × (1 + reps/30), single rep = w', () {
      expect(epley1Rm(100, 1), 100);
      expect(epley1Rm(100, 10), closeTo(133.333, 1e-3));
      expect(epley1Rm(60, 30), 120);
      expect(epley1Rm(0, 10), 0);
    });
  });

  group('PR detection', () {
    test('first time doing an exercise: best set of each type is a PR', () {
      final prs = detectPrs([s(60, 10), s(80, 3), s(70, 8)], PrBests.none);
      // heaviest: 80×3 (idx 1); e1RM: 60×10=80, 80×3=88, 70×8≈88.67 → idx 2;
      // volume: 600, 240, 560 → idx 0.
      expect(prs, {
        0: {PrType.bestSetVolume},
        1: {PrType.heaviestWeight},
        2: {PrType.best1Rm},
      });
    });

    test('must STRICTLY beat previous bests', () {
      const prev = PrBests(heaviestKg: 100, best1RmKg: 120, bestVolumeKg: 800);
      expect(detectPrs([s(100, 5)], prev), isEmpty); // ties are not PRs
      expect(detectPrs([s(102.5, 1)], prev), {
        0: {PrType.heaviestWeight},
      });
    });

    test('warm-ups and incomplete sets never count', () {
      final prs = detectPrs([s(200, 10, type: SetType.warmup), s(200, 10, done: false)], PrBests.none);
      expect(prs, isEmpty);
    });

    test('only one set per type per workout (first on ties)', () {
      final prs = detectPrs([s(100, 5), s(100, 5)], PrBests.none);
      expect(prs.keys, [0]);
      expect(prs[0], PrType.values.toSet());
    });

    test('PrBests.fromSets ignores warm-ups', () {
      final b = PrBests.fromSets([s(200, 1, type: SetType.warmup), s(100, 10)]);
      expect(b.heaviestKg, 100);
      expect(b.bestVolumeKg, 1000);
      expect(b.best1RmKg, closeTo(133.333, 1e-3));
    });
  });

  group('Lifted comparison', () {
    test('smallest object with count 1–20 (brief example: 8,450 kg → 6 cars)', () {
      expect(liftedComparison(8450), (object: LiftedObject.car, count: 6));
    });

    test('moves to bigger objects when cars exceed 20', () {
      expect(liftedComparison(30000), (object: LiftedObject.pyramidBlock, count: 12));
      expect(liftedComparison(60000), (object: LiftedObject.elephant, count: 10));
    });

    test('above 20 elephants still uses elephants', () {
      expect(liftedComparison(300000), (object: LiftedObject.elephant, count: 50));
    });

    test('too little → none', () {
      expect(liftedComparison(600), isNull);
      expect(liftedComparison(0), isNull);
      expect(liftedComparison(700), (object: LiftedObject.car, count: 1));
    });
  });
}
