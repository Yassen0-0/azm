import 'package:azm/core/utils/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kg ↔ lb', () {
    test('conversion factors', () {
      expect(Units.lbToKg(1), closeTo(0.45359237, 1e-12));
      expect(Units.kgToLb(1), closeTo(2.2046226218, 1e-9));
      expect(Units.kgToLb(100), closeTo(220.46226218, 1e-7));
    });

    test('round trip is lossless', () {
      for (final kg in [0.0, 2.5, 60.0, 102.5, 227.3]) {
        expect(Units.lbToKg(Units.kgToLb(kg)), closeTo(kg, 1e-9));
      }
    });

    test('display rounds to 0.1 in the chosen unit', () {
      expect(Units.toDisplay(100, WeightUnit.kg), 100);
      expect(Units.toDisplay(100, WeightUnit.lb), 220.5);
      expect(Units.toDisplay(62.456, WeightUnit.kg), 62.5);
    });

    test('value typed in lb is stored in kg and shows back unchanged', () {
      final kg = Units.fromDisplay(135, WeightUnit.lb);
      expect(kg, closeTo(61.2349, 1e-4));
      expect(Units.toDisplay(kg, WeightUnit.lb), 135);
    });

    test('keypad ±2.5 steps in the display unit, never below 0', () {
      expect(Units.stepKg(60, WeightUnit.kg, up: true), 62.5);
      expect(Units.stepKg(60, WeightUnit.kg, up: false), 57.5);
      expect(Units.stepKg(1, WeightUnit.kg, up: false), 0);
      final kg = Units.fromDisplay(135, WeightUnit.lb);
      expect(Units.toDisplay(Units.stepKg(kg, WeightUnit.lb, up: true), WeightUnit.lb), 137.5);
    });
  });
}
