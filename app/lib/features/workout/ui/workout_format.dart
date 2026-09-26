import 'package:flutter/widgets.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/exercise_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';
import '../../../core/widgets/set_row.dart';

/// Display helpers for the workout feature (Western digits everywhere).
extension WorkoutFormat on AppLocalizations {
  String unitLabel(WeightUnit unit) => unit == WeightUnit.kg ? workoutUnitKg : workoutUnitLb;

  /// e.g. `62.5 kg`.
  String weightWithUnit(double kg, WeightUnit unit) =>
      workoutWeightUnit(weightNumber(kg, unit), unitLabel(unit));

  /// e.g. `60 × 8` (weight in the display unit, no unit).
  String setValue(WorkoutSet s, WeightUnit unit) =>
      workoutSetValue(weightNumber(s.weightKg, unit), '${s.reps}');

  /// e.g. `60 kg × 8`.
  String setValueWithUnit(WorkoutSet s, WeightUnit unit) =>
      workoutSetValue(weightWithUnit(s.weightKg, unit), '${s.reps}');

  String setLabelFor(SetType type, int? number) => switch (type) {
        SetType.normal => '${number ?? ''}',
        SetType.warmup => workoutSetTypeWarmupShort,
        SetType.drop => workoutSetTypeDropShort,
        SetType.failure => workoutSetTypeFailureShort,
      };

  String setTypeName(SetType type) => switch (type) {
        SetType.normal => workoutSetTypeNormal,
        SetType.warmup => workoutSetTypeWarmup,
        SetType.drop => workoutSetTypeDrop,
        SetType.failure => workoutSetTypeFailure,
      };

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

/// Weight number in the display unit, 0.1 precision, trailing zeros dropped.
String weightNumber(double kg, WeightUnit unit) => AzmNumbers.decimal(Units.toDisplay(kg, unit));

/// Weight as typed in the keypad (no thousands separator): `62.5`, `100`.
String weightInputText(double kg, WeightUnit unit) {
  final v = Units.toDisplay(kg, unit);
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

SetLabelKind setLabelKind(SetType t) => switch (t) {
      SetType.normal => SetLabelKind.normal,
      SetType.warmup => SetLabelKind.warmup,
      SetType.drop || SetType.failure => SetLabelKind.other,
    };

/// Primary/secondary names, or "Unknown exercise (id)".
ExerciseNames namesFor(BuildContext context, Exercise? e, String exerciseId) =>
    e == null ? (primary: context.l10n.workoutUnknownExercise(exerciseId), secondary: null) : context.namesOf(e);
