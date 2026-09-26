import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// Keys of the [WeightKeypad].
sealed class KeypadKey {
  const KeypadKey();
}

class KeypadDigit extends KeypadKey {
  const KeypadDigit(this.digit);
  final int digit;
}

class KeypadDecimal extends KeypadKey {
  const KeypadDecimal();
}

class KeypadBackspace extends KeypadKey {
  const KeypadBackspace();
}

class KeypadStep extends KeypadKey {
  const KeypadStep({required this.up});
  final bool up;
}

class KeypadNext extends KeypadKey {
  const KeypadNext();
}

class KeypadHide extends KeypadKey {
  const KeypadHide();
}

/// Text-buffer editing for the keypad (pure; unit-tested).
///
/// [fresh] = the buffer shows the stored value and the next digit REPLACES it
/// (like a selected field). Returns the new buffer and fresh flag.
({String buffer, bool fresh}) applyKeypadKey(
  String buffer,
  bool fresh,
  KeypadKey key, {
  required bool allowDecimal,
  int maxIntegerDigits = 4,
  int maxDecimals = 1,
}) {
  switch (key) {
    case KeypadDigit(:final digit):
      var b = fresh ? '' : buffer;
      if (b == '0') b = '';
      final dot = b.indexOf('.');
      if (dot >= 0 && b.length - dot - 1 >= maxDecimals) return (buffer: b, fresh: false);
      if (dot < 0 && b.length >= maxIntegerDigits) return (buffer: b, fresh: false);
      return (buffer: '$b$digit', fresh: false);
    case KeypadDecimal():
      if (!allowDecimal) return (buffer: buffer, fresh: fresh);
      final b = fresh || buffer.isEmpty ? '0' : buffer;
      return (buffer: b.contains('.') ? b : '$b.', fresh: false);
    case KeypadBackspace():
      if (fresh) return (buffer: '', fresh: false);
      return (buffer: buffer.isEmpty ? '' : buffer.substring(0, buffer.length - 1), fresh: false);
    case KeypadStep() || KeypadNext() || KeypadHide():
      return (buffer: buffer, fresh: fresh);
  }
}

/// Custom numeric keypad that replaces the system keyboard (DESIGN.md →
/// WeightKeypad): value preview, 0–9, decimal, backspace, −step / +step,
/// close, next/done. Stateless: the parent owns the buffer.
class WeightKeypad extends StatelessWidget {
  const WeightKeypad({
    super.key,
    required this.title,
    required this.valueText,
    required this.allowDecimal,
    required this.stepText,
    required this.nextLabel,
    required this.backspaceLabel,
    required this.hideLabel,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onKey,
  });

  /// e.g. "Weight (kg)" / "Reps".
  final String title;
  final String valueText;
  final bool allowDecimal;

  /// Step shown on the ± keys, e.g. "2.5" or "1".
  final String stepText;
  final String nextLabel;
  final String backspaceLabel;
  final String hideLabel;
  final String decreaseLabel;
  final String increaseLabel;
  final ValueChanged<KeypadKey> onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget digit(int d) => _Key(label: '$d', onTap: () => onKey(KeypadDigit(d)));

    return Container(
      decoration: BoxDecoration(
        color: c.pageBackground,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AzmSpace.xs,
        AzmSpace.xs,
        AzmSpace.xs,
        AzmSpace.xs + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs, vertical: AzmSpace.xxs),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AzmType.fieldLabel.copyWith(color: c.textSecondary))),
                Text(valueText, style: AzmType.keypadValue.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: AzmSpace.xxs),
          _KeyRow(children: [digit(1), digit(2), digit(3), _Key(label: '\u2066−$stepText\u2069', semanticLabel: decreaseLabel, onTap: () => onKey(const KeypadStep(up: false)))]),
          _KeyRow(children: [digit(4), digit(5), digit(6), _Key(label: '\u2066+$stepText\u2069', semanticLabel: increaseLabel, onTap: () => onKey(const KeypadStep(up: true)))]),
          _KeyRow(children: [
            digit(7),
            digit(8),
            digit(9),
            _Key(icon: Icons.backspace_outlined, semanticLabel: backspaceLabel, onTap: () => onKey(const KeypadBackspace())),
          ]),
          _KeyRow(children: [
            _Key(label: '.', enabled: allowDecimal, onTap: () => onKey(const KeypadDecimal())),
            digit(0),
            _Key(icon: Icons.keyboard_arrow_down_rounded, semanticLabel: hideLabel, onTap: () => onKey(const KeypadHide())),
            _Key(label: nextLabel, primary: true, onTap: () => onKey(const KeypadNext())),
          ]),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: AzmSpace.xs),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AzmSpace.xs),
              Expanded(child: children[i]),
            ],
          ],
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, this.semanticLabel, required this.onTap, this.primary = false, this.enabled = true});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = !enabled ? c.textNoData : (primary ? c.onAccent : c.textPrimary);
    return AzmPressable(
      onTap: enabled ? onTap : null,
      semanticLabel: semanticLabel ?? label,
      child: Container(
        height: AzmSize.keypadKeyHeight,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: primary ? c.accent : c.card,
          borderRadius: BorderRadius.circular(AzmRadius.button),
        ),
        child: ExcludeSemantics(
          child: icon != null
              ? Icon(icon, color: fg, size: AzmSize.icon)
              : Text(label!, style: (primary ? AzmType.button : AzmType.rowNumber).copyWith(color: fg)),
        ),
      ),
    );
  }
}
