import 'package:azm/core/l10n/gen/app_localizations_ar.dart';
import 'package:azm/core/l10n/gen/app_localizations_en.dart';
import 'package:azm/core/l10n/set_labels.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/core/utils/workout_math.dart';
import 'package:azm/core/widgets/set_keypad.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/core/widgets/weight_keypad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetKeypadBuffer (shared by workout, past workout, routine editor)', () {
    test('digits replace a fresh value, then append; weight is stored in kg', () {
      final b = SetKeypadBuffer()..load('60');
      expect(b.apply(const KeypadDigit(7), SetField.weight, WeightUnit.kg), 7);
      expect(b.apply(const KeypadDigit(0), SetField.weight, WeightUnit.kg), 70);
      expect(b.apply(const KeypadDecimal(), SetField.weight, WeightUnit.kg), 70);
      expect(b.apply(const KeypadDigit(5), SetField.weight, WeightUnit.kg), 70.5);
      expect(b.text, '70.5');
      expect(b.apply(const KeypadDigit(5), SetField.weight, WeightUnit.kg), 70.5, reason: 'one decimal max');
    });

    test('lb input is converted to kg', () {
      final b = SetKeypadBuffer()..load('');
      final kg = b.apply(const KeypadDigit(9), SetField.weight, WeightUnit.lb)!;
      expect(kg, closeTo(Units.fromDisplay(9, WeightUnit.lb), 1e-9));
    });

    test('backspace to empty returns null (caller stores 0 or clears the target)', () {
      final b = SetKeypadBuffer()..load('8');
      expect(b.apply(const KeypadBackspace(), SetField.reps, WeightUnit.kg), isNull);
      expect(b.text, '');
    });

    test('± steps: 2.5 in the display unit for weight, 1 for reps, never below 0', () {
      final w = SetKeypadBuffer()..load('60');
      expect(w.apply(const KeypadStep(up: true), SetField.weight, WeightUnit.kg), 62.5);
      expect(w.text, '62.5');
      expect(w.fresh, isTrue);
      final r = SetKeypadBuffer()..load('1');
      expect(r.apply(const KeypadStep(up: false), SetField.reps, WeightUnit.kg), isNull);
      expect(r.text, '');
      expect(r.apply(const KeypadStep(up: false), SetField.reps, WeightUnit.kg), isNull);
      expect(r.apply(const KeypadStep(up: true), SetField.reps, WeightUnit.kg), 1);
    });

    test('reps: max 3 digits, no decimal', () {
      final b = SetKeypadBuffer()..load('');
      for (final d in [1, 2, 3, 4]) {
        b.apply(KeypadDigit(d), SetField.reps, WeightUnit.kg);
      }
      expect(b.text, '123');
      b.apply(const KeypadDecimal(), SetField.reps, WeightUnit.kg);
      expect(b.text, '123');
    });

    test('next / hide leave the value alone', () {
      final b = SetKeypadBuffer()..load('60');
      expect(b.apply(const KeypadNext(), SetField.weight, WeightUnit.kg), isNull);
      expect(b.text, '60');
    });
  });

  group('shared set labels', () {
    test('letters and names come from one place (ar + en)', () {
      final ar = AppLocalizationsAr(), en = AppLocalizationsEn();
      expect([for (final t in SetType.values) ar.setLabel(t, 2)], ['2', 'ح', 'د', 'ف']);
      expect([for (final t in SetType.values) en.setLabel(t, 2)], ['2', 'W', 'D', 'F']);
      expect(en.setTypeLetter(SetType.normal), isNull);
      expect(en.setTypeName(SetType.drop), 'Drop set');
      expect(normalSetNumbers([SetType.warmup, SetType.normal, SetType.drop, SetType.normal]), [null, 1, null, 2]);
      expect(setLabelKind(SetType.failure), SetLabelKind.other, reason: 'failure is never red');
      expect(setWeightInput(62.5, WeightUnit.kg), '62.5');
      expect(setWeightNumber(1000, WeightUnit.kg), '1,000');
    });
  });
}
