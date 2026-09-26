import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';
import '../../../core/widgets/exercise_card.dart' show isolateName;
import '../data/exercise_history.dart';

/// Display helpers for weights, sets and dates. Storage stays kg; conversion
/// happens only here. Western digits in both languages.
abstract final class ExerciseFormat {
  static String unit(AppLocalizations l, WeightUnit u) => u == WeightUnit.kg ? l.exercisesUnitKg : l.exercisesUnitLb;

  /// Just the number in the display unit: "62.5".
  static String number(double kg, WeightUnit u) => AzmNumbers.decimal(Units.toDisplay(kg, u));

  /// "62.5 kg", bidi-isolated so it never reorders to "kg 62.5" in RTL.
  static String weight(AppLocalizations l, double kg, WeightUnit u) =>
      isolateName(l.exercisesWeightValue(number(kg, u), unit(l, u)));

  /// "62.5 kg × 8".
  static String set(AppLocalizations l, HistorySet s, WeightUnit u) =>
      l.exercisesSetValue(weight(l, s.weightKg, u), AzmNumbers.integer(s.reps));

  /// Short set-type label for non-normal sets (normal sets use their number).
  static String? typeLabel(AppLocalizations l, SetType t) => switch (t) {
    SetType.normal => null,
    SetType.warmup => l.exercisesSetLabelWarmup,
    SetType.drop => l.exercisesSetLabelDrop,
    SetType.failure => l.exercisesSetLabelFailure,
  };

  /// "26 Sep 2026" in the app language, local time, Western digits.
  static String date(BuildContext context, DateTime utc) {
    final f = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())..useNativeDigits = false;
    return f.format(utc.toLocal());
  }

  /// "26 Sep" (chart axis).
  static String shortDate(BuildContext context, DateTime utc) {
    final f = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())..useNativeDigits = false;
    return f.format(utc.toLocal());
  }
}
