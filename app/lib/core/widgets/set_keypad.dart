import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../l10n/set_labels.dart';
import '../utils/units.dart';
import 'set_row.dart';
import 'weight_keypad.dart';

/// The keypad's text buffer for one set field, shared by every screen that
/// edits sets (live workout, past workout, routine editor). Pure; unit-tested.
///
/// [fresh] = the buffer shows the stored value and the next digit REPLACES
/// it (like a selected text field).
class SetKeypadBuffer {
  String text = '';
  bool fresh = true;

  /// Starts editing a field that currently shows [value] (`''` = empty).
  void load(String value) {
    text = value;
    fresh = true;
  }

  /// Applies a digit / decimal / backspace / ± key to [field] and returns
  /// the value to store: kg for the weight (converted from [unit]), the rep
  /// count for reps; null when the field is now empty. Next/Hide are the
  /// caller's (they don't change the value) and return null.
  ///
  /// Limits: 4 integer digits + 1 decimal for weight, 3 digits for reps;
  /// ± is [Units.keypadStep] in the display unit for weight, 1 for reps.
  double? apply(KeypadKey key, SetField field, WeightUnit unit) {
    final weight = field == SetField.weight;
    switch (key) {
      case KeypadNext() || KeypadHide():
        return null;
      case KeypadStep(:final up):
        fresh = true;
        if (weight) {
          final kg = Units.stepKg(Units.fromDisplay(double.tryParse(text) ?? 0, unit), unit, up: up);
          text = kg > 0 ? setWeightInput(kg, unit) : '';
          return kg > 0 ? kg : null;
        }
        final reps = ((int.tryParse(text) ?? 0) + (up ? 1 : -1)).clamp(0, 999);
        text = reps > 0 ? '$reps' : '';
        return reps > 0 ? reps.toDouble() : null;
      default:
        final r = applyKeypadKey(text, fresh, key, allowDecimal: weight, maxIntegerDigits: weight ? 4 : 3);
        text = r.buffer;
        fresh = r.fresh;
        final v = double.tryParse(text);
        if (v == null) return null;
        return weight ? Units.fromDisplay(v, unit) : v.truncateToDouble();
    }
  }
}

/// [WeightKeypad] with the shared set wording: "Weight (kg)" / "Reps",
/// Next ↔ Done on the last field, ± step, semantics labels. A light
/// selection haptic on ± (every screen, same feel).
class SetValueKeypad extends StatelessWidget {
  const SetValueKeypad({
    super.key,
    required this.field,
    required this.unit,
    required this.buffer,
    required this.hasNext,
    required this.onKey,
    this.weightTitle,
    this.repsTitle,
  });

  final SetField field;
  final WeightUnit unit;

  /// Current text (`''` shows the no-data dash).
  final String buffer;

  /// Another field follows: the primary key reads "Next", else "Done".
  final bool hasNext;
  final ValueChanged<KeypadKey> onKey;

  /// Title overrides (routine editor: "Target weight (kg)" / "Target reps").
  final String? weightTitle;
  final String? repsTitle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final weight = field == SetField.weight;
    return WeightKeypad(
      title: weight
          ? (weightTitle ?? l.commonKeypadWeight(l.weightUnitLabel(unit)))
          : (repsTitle ?? l.commonSetColReps),
      valueText: buffer.isEmpty ? l.commonNoData : buffer,
      allowDecimal: weight,
      stepText: weight ? AzmNumbers.decimal(Units.keypadStep) : '1',
      nextLabel: hasNext ? l.commonKeypadNext : l.commonKeypadDone,
      backspaceLabel: l.commonKeypadBackspace,
      hideLabel: l.commonKeypadHide,
      decreaseLabel: l.commonKeypadDecrease,
      increaseLabel: l.commonKeypadIncrease,
      onKey: (key) {
        if (key is KeypadStep) HapticFeedback.selectionClick();
        onKey(key);
      },
    );
  }
}
