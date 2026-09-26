/// Weight units. Storage is ALWAYS kg; lb exists only at display/input edges.
enum WeightUnit { kg, lb }

abstract final class Units {
  /// Exact international avoirdupois pound: 1 lb = 0.45359237 kg.
  static const double kgPerLb = 0.45359237;
  static const double lbPerKg = 1 / kgPerLb; // 2.2046226218…

  /// Keypad −/+ step, in the DISPLAY unit.
  static const double keypadStep = 2.5;

  static double kgToLb(double kg) => kg * lbPerKg;
  static double lbToKg(double lb) => lb * kgPerLb;

  /// Stored kg → value shown in [unit], rounded to 0.1.
  static double toDisplay(double kg, WeightUnit unit) =>
      _round1(unit == WeightUnit.kg ? kg : kgToLb(kg));

  /// Value typed in [unit] → kg for storage. Not rounded, so a value typed in
  /// lb round-trips back to exactly what the user typed.
  static double fromDisplay(double value, WeightUnit unit) =>
      unit == WeightUnit.kg ? value : lbToKg(value);

  /// Applies a keypad ±[Units.keypadStep] in the display unit to a stored kg
  /// value and returns the new kg value (never below 0).
  static double stepKg(double kg, WeightUnit unit, {required bool up}) {
    final shown = toDisplay(kg, unit);
    final next = shown + (up ? keypadStep : -keypadStep);
    return fromDisplay(next < 0 ? 0 : next, unit);
  }

  static double _round1(double v) => (v * 10).roundToDouble() / 10;
}
