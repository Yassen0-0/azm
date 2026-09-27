import 'package:flutter/widgets.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/exercise_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';

/// Display helpers for the workout feature (Western digits everywhere).
extension WorkoutFormat on AppLocalizations {
  /// e.g. `62.5 kg`.
  String weightWithUnit(double kg, WeightUnit unit) =>
      workoutWeightUnit(setWeightNumber(kg, unit), weightUnitLabel(unit));

  /// e.g. `60 × 8` (weight in the display unit, no unit). Kept left-to-right
  /// in Arabic too, so it never reorders into `8 × 60`.
  String setValue(WorkoutSet s, WeightUnit unit) =>
      ltrIsolate(workoutSetValue(setWeightNumber(s.weightKg, unit), '${s.reps}'));

  /// e.g. `60 kg × 8` (left-to-right in both languages).
  String setValueWithUnit(WorkoutSet s, WeightUnit unit) =>
      ltrIsolate(workoutSetValue(weightWithUnit(s.weightKg, unit), '${s.reps}'));

  String prTypeName(PrType t) => switch (t) {
        PrType.heaviestWeight => workoutPrHeaviest,
        PrType.best1Rm => workoutPr1Rm,
        PrType.bestSetVolume => workoutPrVolume,
      };

  /// Default name from the local start hour.
  String defaultWorkoutName(DateTime local) {
    final h = local.hour;
    if (h >= 5 && h < 12) return workoutNameMorning;
    if (h >= 12 && h < 17) return workoutNameAfternoon;
    if (h >= 17 && h < 22) return workoutNameEvening;
    return workoutNameNight;
  }

  /// "the weight of 6 cars 🚗" (SPEC → Lifted), or null below ~700 kg.
  String? comparison(double liftedKg) {
    final c = liftedComparison(liftedKg);
    if (c == null) return null;
    final text = AzmNumbers.integer(c.count);
    return switch (c.object) {
      LiftedObject.car => workoutCompareCar(c.count, text),
      LiftedObject.pyramidBlock => workoutComparePyramid(c.count, text),
      LiftedObject.elephant => workoutCompareElephant(c.count, text),
    };
  }
}

/// Wraps a numeric expression (`60 kg × 8`, `−15`) in a Unicode
/// left-to-right isolate so the bidi algorithm can't reorder its parts inside
/// Arabic text. (A text-level fix: no hard-coded TextDirection.)
String ltrIsolate(String s) => '\u2066$s\u2069';

/// Primary/secondary names, or "Unknown exercise (id)".
ExerciseNames namesFor(BuildContext context, Exercise? e, String exerciseId) =>
    e == null ? (primary: context.l10n.workoutUnknownExercise(exerciseId), secondary: null) : context.namesOf(e);
