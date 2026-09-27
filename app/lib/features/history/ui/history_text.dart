import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/exercise_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/set_row.dart';
import '../data/history_format.dart';

/// Display helpers of the history feature. Storage stays kg; conversion
/// happens only here. Western digits in both languages.
extension HistoryText on AppLocalizations {
  String unitLabel(WeightUnit u) => u == WeightUnit.kg ? historyUnitKg : historyUnitLb;

  /// "62.5 kg" (left-to-right isolate, never reorders to "kg 62.5").
  String weight(double kg, WeightUnit u) => ltr(historyWeightValue(weightNumber(kg, u), unitLabel(u)));

  /// "60 × 8" / "60 kg × 8", weight first in both languages.
  String setValue(WorkoutSet s, WeightUnit u, {bool withUnit = true}) => ltr(historySetValue(
        withUnit ? weight(s.weightKg, u) : weightNumber(s.weightKg, u),
        AzmNumbers.integer(s.reps),
      ));

  /// Compact big total: `84,500` / `450K` / `1.2M` (`1.2 مليون`).
  String compact(double value) {
    final c = compactNumber(value);
    return switch (c.scale) {
      CompactScale.none => c.number,
      CompactScale.thousand => historyCompactThousand(c.number),
      CompactScale.million => historyCompactMillion(c.number),
      CompactScale.billion => historyCompactBillion(c.number),
    };
  }

  /// "55 min" / "1 h 5 min".
  String duration(Duration d) {
    final minutes = d.inMinutes < 0 ? 0 : d.inMinutes;
    if (minutes < 60) return historyDurationMinutes(AzmNumbers.integer(minutes));
    return historyDurationHours(AzmNumbers.integer(minutes ~/ 60), AzmNumbers.integer(minutes % 60));
  }

  String workoutCount(int n) => historyWorkoutCount(n, AzmNumbers.integer(n));

  String setCount(int n) => historySetCount(n, AzmNumbers.integer(n));

  String setLabel(SetType type, int? number) => switch (type) {
        SetType.normal => number == null ? '' : AzmNumbers.integer(number),
        SetType.warmup => historySetTypeWarmupShort,
        SetType.drop => historySetTypeDropShort,
        SetType.failure => historySetTypeFailureShort,
      };

  String setTypeName(SetType type) => switch (type) {
        SetType.normal => historySetTypeNormal,
        SetType.warmup => historySetTypeWarmup,
        SetType.drop => historySetTypeDrop,
        SetType.failure => historySetTypeFailure,
      };
}

/// Wraps a numeric expression in a Unicode left-to-right isolate so the bidi
/// algorithm can't reorder its parts inside Arabic text.
String ltr(String s) => '\u2066$s\u2069';

/// First-strong isolate for names (English names inside Arabic UI).
String isolate(String s) => '\u2068$s\u2069';

/// Weight number in the display unit, 0.1 precision: `62.5`, `100`.
String weightNumber(double kg, WeightUnit u) => AzmNumbers.decimal(Units.toDisplay(kg, u));

/// As typed in the keypad (no separators): `62.5`, `100`.
String weightInput(double kg, WeightUnit u) {
  final v = Units.toDisplay(kg, u);
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

SetLabelKind labelKind(SetType t) => switch (t) {
      SetType.normal => SetLabelKind.normal,
      SetType.warmup => SetLabelKind.warmup,
      SetType.drop || SetType.failure => SetLabelKind.other,
    };

/// Normal sets count 1, 2, 3…; other types get null (they show a letter).
List<int?> normalNumbers(Iterable<SetType> types) {
  var n = 0;
  return [for (final t in types) t == SetType.normal ? ++n : null];
}

/// Primary/secondary names, or "Unknown exercise (id)".
ExerciseNames namesOrUnknown(BuildContext context, Exercise? e, String id) =>
    e == null ? (primary: context.l10n.historyUnknownExercise(id), secondary: null) : context.namesOf(e);

/// Date formats in the app language, local time, Western digits.
abstract final class HistoryDates {
  static String _tag(BuildContext c) => Localizations.localeOf(c).toLanguageTag();

  /// "Sat, 26 Sep 2026".
  static String full(BuildContext c, DateTime utc) =>
      (DateFormat.yMMMEd(_tag(c))..useNativeDigits = false).format(utc.toLocal());

  /// "Sat, 26 Sep" (cards).
  static String short(BuildContext c, DateTime utc) =>
      (DateFormat.MMMEd(_tag(c))..useNativeDigits = false).format(utc.toLocal());

  /// "18:05".
  static String time(BuildContext c, DateTime utc) =>
      (DateFormat.Hm(_tag(c))..useNativeDigits = false).format(utc.toLocal());

  /// "September 2026" for a LOCAL month.
  static String month(BuildContext c, DateTime localMonth) =>
      (DateFormat.yMMMM(_tag(c))..useNativeDigits = false).format(localMonth);

  /// "Saturday, 26 September 2026" for a LOCAL day (screen readers).
  static String longDay(BuildContext c, DateTime localDay) =>
      (DateFormat.yMMMMEEEEd(_tag(c))..useNativeDigits = false).format(localDay);

  /// "26 Sep" for a LOCAL day (chart axis).
  static String dayMonth(BuildContext c, DateTime localDay) =>
      (DateFormat.MMMd(_tag(c))..useNativeDigits = false).format(localDay);
}
