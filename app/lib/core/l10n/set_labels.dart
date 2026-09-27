import '../utils/units.dart';
import '../utils/workout_math.dart';
import 'l10n.dart';

/// Set-type labels and the set table's strings, shared by the live workout,
/// past-workout editing and the routine editor, so ح/W, د/D, ف/F and the
/// keypad wording can never drift apart between screens (strings: the core
/// ARB fragment, `commonSet…` / `commonKeypad…`).
extension SetLabels on AppLocalizations {
  /// Set label chip: the number for normal sets, the type letter otherwise.
  String setLabel(SetType type, int? number) => switch (type) {
        SetType.normal => number == null ? '' : AzmNumbers.integer(number),
        SetType.warmup => commonSetTypeWarmupShort,
        SetType.drop => commonSetTypeDropShort,
        SetType.failure => commonSetTypeFailureShort,
      };

  /// Letter for a non-normal set, null for a normal one (history lines).
  String? setTypeLetter(SetType type) => type == SetType.normal ? null : setLabel(type, null);

  String setTypeName(SetType type) => switch (type) {
        SetType.normal => commonSetTypeNormal,
        SetType.warmup => commonSetTypeWarmup,
        SetType.drop => commonSetTypeDrop,
        SetType.failure => commonSetTypeFailure,
      };

  String weightUnitLabel(WeightUnit unit) => unit == WeightUnit.kg ? commonUnitKg : commonUnitLb;
}

/// Normal sets count 1, 2, 3…; other types get null (they show a letter).
List<int?> normalSetNumbers(Iterable<SetType> types) {
  var n = 0;
  return [for (final t in types) t == SetType.normal ? ++n : null];
}

/// Weight number in the display unit, 0.1 precision, trailing zeros dropped:
/// `62.5`, `1,000`.
String setWeightNumber(double kg, WeightUnit unit) => AzmNumbers.decimal(Units.toDisplay(kg, unit));

/// Weight as typed on the keypad (no thousands separator): `62.5`, `100`.
String setWeightInput(double kg, WeightUnit unit) {
  final v = Units.toDisplay(kg, unit);
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
