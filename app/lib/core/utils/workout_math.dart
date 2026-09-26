/// Pure workout math: Lifted, estimated 1RM, PR detection, Lifted comparison.
/// No Flutter / DB imports — unit-tested in test/core/utils/.
/// Rules: docs/SPEC.md → "History & PRs" and "Lifted".
library;

/// Set types (stored as their [name] in the DB).
enum SetType { normal, warmup, drop, failure }

/// Minimal view of a set for calculations. [weightKg] is the ADDED weight for
/// bodyweight exercises (0 if none).
class SetStats {
  const SetStats({
    required this.weightKg,
    required this.reps,
    required this.completed,
    this.type = SetType.normal,
  });

  final double weightKg;
  final int reps;
  final bool completed;
  final SetType type;
}

/// Lifted (شِلت): Σ weight × reps over COMPLETED sets, warm-ups INCLUDED.
double liftedKg(Iterable<SetStats> sets) {
  var total = 0.0;
  for (final s in sets) {
    if (!s.completed || s.reps <= 0 || s.weightKg <= 0) continue;
    total += s.weightKg * s.reps;
  }
  return total;
}

/// Epley estimated 1RM: w × (1 + reps / 30); exactly w for a single rep.
/// Returns 0 for invalid sets.
double epley1Rm(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) return 0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

/// The three PR types.
enum PrType { heaviestWeight, best1Rm, bestSetVolume }

/// Best values per exercise from all EARLIER workouts (zeros if none).
class PrBests {
  const PrBests({this.heaviestKg = 0, this.best1RmKg = 0, this.bestVolumeKg = 0});

  static const PrBests none = PrBests();

  final double heaviestKg;
  final double best1RmKg;
  final double bestVolumeKg;

  double of(PrType t) => switch (t) {
        PrType.heaviestWeight => heaviestKg,
        PrType.best1Rm => best1RmKg,
        PrType.bestSetVolume => bestVolumeKg,
      };

  /// Bests over [sets] (completed, non-warm-up, valid).
  factory PrBests.fromSets(Iterable<SetStats> sets) {
    var h = 0.0, e = 0.0, v = 0.0;
    for (final s in sets) {
      if (!_eligible(s)) continue;
      if (s.weightKg > h) h = s.weightKg;
      final e1 = epley1Rm(s.weightKg, s.reps);
      if (e1 > e) e = e1;
      final vol = s.weightKg * s.reps;
      if (vol > v) v = vol;
    }
    return PrBests(heaviestKg: h, best1RmKg: e, bestVolumeKg: v);
  }
}

bool _eligible(SetStats s) =>
    s.completed && s.type != SetType.warmup && s.weightKg > 0 && s.reps > 0;

double _value(PrType t, SetStats s) => switch (t) {
      PrType.heaviestWeight => s.weightKg,
      PrType.best1Rm => epley1Rm(s.weightKg, s.reps),
      PrType.bestSetVolume => s.weightKg * s.reps,
    };

/// PRs of one exercise in one workout.
///
/// For each PR type, the single best eligible set of [workoutSets] (first one
/// on ties) is a PR if it STRICTLY beats [previous]. Warm-ups never count.
/// Returns set index (in [workoutSets]) → PR types it holds.
Map<int, Set<PrType>> detectPrs(List<SetStats> workoutSets, PrBests previous) {
  final result = <int, Set<PrType>>{};
  for (final type in PrType.values) {
    var bestIndex = -1;
    var bestValue = 0.0;
    for (var i = 0; i < workoutSets.length; i++) {
      final s = workoutSets[i];
      if (!_eligible(s)) continue;
      final v = _value(type, s);
      if (v > bestValue) {
        bestValue = v;
        bestIndex = i;
      }
    }
    if (bestIndex >= 0 && bestValue > previous.of(type)) {
      (result[bestIndex] ??= <PrType>{}).add(type);
    }
  }
  return result;
}

/// Objects for the post-workout "you lifted N cars" line.
enum LiftedObject {
  car(1400),
  pyramidBlock(2500),
  elephant(6000);

  const LiftedObject(this.kg);
  final double kg;
}

/// Result of [liftedComparison]: e.g. (car, 6) → "6 cars".
typedef LiftedComparison = ({LiftedObject object, int count});

/// Picks the SMALLEST object whose rounded count is 1–20 (8,450 kg → 6 cars,
/// as in the brief). Above 20 elephants uses elephants anyway; below ~700 kg
/// (not even 1 car) returns null.
LiftedComparison? liftedComparison(double liftedKg) {
  if (liftedKg <= 0) return null;
  for (final o in LiftedObject.values) {
    final n = (liftedKg / o.kg).round();
    if (n >= 1 && n <= 20) return (object: o, count: n);
  }
  final elephants = (liftedKg / LiftedObject.elephant.kg).round();
  if (elephants > 20) return (object: LiftedObject.elephant, count: elephants);
  return null;
}
