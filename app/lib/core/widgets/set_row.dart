import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../theme/azm_theme.dart';
import '../utils/workout_math.dart';
import 'azm_pressable.dart';

/// How the set label is drawn: normal sets show their number, warm-ups an
/// amber letter, drop/failure a default-colour letter (failure is NEVER red).
enum SetLabelKind { normal, warmup, other }

SetLabelKind setLabelKind(SetType t) => switch (t) {
      SetType.normal => SetLabelKind.normal,
      SetType.warmup => SetLabelKind.warmup,
      SetType.drop || SetType.failure => SetLabelKind.other,
    };

/// Which value cell is being edited with the keypad.
enum SetField { weight, reps }

/// Column widths shared by [SetRow] and [SetTableHeader] (flex factors).
abstract final class SetRowColumns {
  static const int previousFlex = 3;
  static const int valueFlex = 2;
}

/// Column captions above a set table: set · previous · unit · reps · ✓.
/// Without [previousLabel] the previous column is left out; without
/// [showCheck] the ✓ column (match the [SetRow]s below).
class SetTableHeader extends StatelessWidget {
  const SetTableHeader({
    super.key,
    required this.setLabel,
    required this.previousLabel,
    required this.weightLabel,
    required this.repsLabel,
    this.showCheck = true,
  });

  final String setLabel;
  final String? previousLabel;
  final String weightLabel;
  final String repsLabel;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final style = AzmType.smallStrong.copyWith(color: context.colors.textTertiary);
    Widget cell(String t) => Text(t, style: style, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs),
      child: Row(
        children: [
          SizedBox(width: AzmSize.setCellMinWidth, child: cell(setLabel)),
          if (previousLabel != null) Expanded(flex: SetRowColumns.previousFlex, child: cell(previousLabel!)),
          Expanded(flex: SetRowColumns.valueFlex, child: cell(weightLabel)),
          Expanded(flex: SetRowColumns.valueFlex, child: cell(repsLabel)),
          if (showCheck)
            SizedBox(
              width: AzmSize.setCellMinWidth,
              child: Icon(Icons.check_rounded, size: AzmSize.tabBarBadgeDisc, color: context.colors.textTertiary),
            ),
        ],
      ),
    );
  }
}

/// One set: `[type label] [previous] [weight] [reps] [✓]` (DESIGN.md → SetRow).
/// Pure view: all values are pre-formatted, every action is a callback.
///
/// The one set row of the app: the live workout uses every column; a past
/// workout leaves out ✓ ([onToggleComplete] null: every set there is done);
/// the routine editor also leaves out previous ([previousText] null).
/// Swipe toward the end edge deletes. Value cells are keyed
/// `set-weight-<setId>` / `set-reps-<setId>` (tests).
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.setId,
    required this.label,
    required this.labelKind,
    required this.previousText,
    required this.weightText,
    required this.repsText,
    required this.weightHint,
    required this.repsHint,
    required this.completed,
    required this.onLabelTap,
    required this.onPreviousTap,
    required this.onWeightTap,
    required this.onRepsTap,
    required this.onToggleComplete,
    required this.onDelete,
    required this.deleteLabel,
    required this.completeLabel,
    this.activeField,
    this.isPr = false,
    this.labelSemantics,
  });

  /// Stable id of the set (swipe-to-delete key).
  final String setId;
  final String label;
  final SetLabelKind labelKind;

  /// e.g. `60 × 8`; the no-data dash when there is none; null = no column.
  final String? previousText;

  /// Current values, empty when not entered yet (the hint shows instead).
  final String weightText;
  final String repsText;
  final String weightHint;
  final String repsHint;
  final bool completed;
  final bool isPr;
  final SetField? activeField;

  final VoidCallback onLabelTap;
  final VoidCallback? onPreviousTap;
  final VoidCallback onWeightTap;
  final VoidCallback onRepsTap;
  /// Null = no ✓ column.
  final VoidCallback? onToggleComplete;
  final VoidCallback onDelete;
  final String deleteLabel;
  final String? completeLabel;

  /// Screen-reader label of the type chip (default: [label]).
  final String? labelSemantics;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tick = AzmMotion.of(context, AzmMotion.tick);

    final row = AnimatedContainer(
      duration: tick,
      curve: AzmMotion.standard,
      constraints: const BoxConstraints(minHeight: AzmSize.setRowMinHeight),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs),
      color: completed ? c.setDoneTint : c.card,
      child: Row(
        children: [
          _LabelCell(label: label, kind: labelKind, onTap: onLabelTap, semanticLabel: labelSemantics ?? label),
          if (previousText != null)
            Expanded(
              flex: SetRowColumns.previousFlex,
              child: AzmPressable(
                onTap: onPreviousTap,
                child: Center(
                  child: Text(
                    previousText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.secondaryStrong.copyWith(color: c.textTertiary),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: SetRowColumns.valueFlex,
            child: _ValueCell(
              key: ValueKey('set-weight-$setId'),
              text: weightText,
              hint: weightHint,
              active: activeField == SetField.weight,
              completed: completed,
              onTap: onWeightTap,
            ),
          ),
          Expanded(
            flex: SetRowColumns.valueFlex,
            child: _ValueCell(
              key: ValueKey('set-reps-$setId'),
              text: repsText,
              hint: repsHint,
              active: activeField == SetField.reps,
              completed: completed,
              onTap: onRepsTap,
              badge: isPr ? const PrBadge() : null,
            ),
          ),
          if (onToggleComplete != null)
            _CheckCell(completed: completed, onTap: onToggleComplete!, semanticLabel: completeLabel ?? ''),
        ],
      ),
    );

    // Swipe toward the END edge to delete (mirrors in RTL automatically).
    return Dismissible(
      key: ValueKey(('set-row', setId)),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: c.destructiveTint,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xl),
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          label: deleteLabel,
          child: Icon(Icons.delete_outline_rounded, color: c.destructive),
        ),
      ),
      child: Semantics(
        customSemanticsActions: {CustomSemanticsAction(label: deleteLabel): onDelete},
        child: row,
      ),
    );
  }
}

class _LabelCell extends StatelessWidget {
  const _LabelCell({required this.label, required this.kind, required this.onTap, required this.semanticLabel});

  final String label;
  final SetLabelKind kind;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AzmSize.setCellMinWidth,
      child: AzmPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Center(
          child: SetLabelChip(label: label, kind: kind),
        ),
      ),
    );
  }
}

/// The set label chip: the number, or the type letter (warm-up amber;
/// failure never red). Also used by the set type menu.
class SetLabelChip extends StatelessWidget {
  const SetLabelChip({super.key, required this.label, required this.kind});

  final String label;
  final SetLabelKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (kind) {
      SetLabelKind.warmup => (c.warmupText, c.warmupTint),
      SetLabelKind.normal => (c.textSecondary, c.fill),
      SetLabelKind.other => (c.textPrimary, c.fill),
    };
    return Container(
      width: AzmSize.headerButton,
      height: AzmSize.headerButton,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AzmRadius.segment)),
      child: ExcludeSemantics(child: Text(label, style: AzmType.controlLabel.copyWith(color: fg))),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    super.key,
    required this.text,
    required this.hint,
    required this.active,
    required this.completed,
    required this.onTap,
    this.badge,
  });

  final String text;
  final String hint;
  final bool active;
  final bool completed;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final empty = text.isEmpty;
    return AzmPressable(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: AzmMotion.of(context, AzmMotion.micro),
          margin: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxs),
          constraints: const BoxConstraints(minHeight: AzmSize.headerButton),
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            color: completed ? Colors.transparent : c.fill,
            borderRadius: BorderRadius.circular(AzmRadius.segment),
            border: Border.all(color: active ? c.accent : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  empty ? hint : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AzmType.rowNumber.copyWith(color: empty ? c.textNoData : c.textPrimary),
                ),
              ),
              if (badge != null) ...[const SizedBox(width: AzmSpace.opticalInset), badge!],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCell extends StatelessWidget {
  const _CheckCell({required this.completed, required this.onTap, required this.semanticLabel});

  final bool completed;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: AzmSize.setCellMinWidth,
      child: AzmPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        selected: completed,
        child: Center(
          child: AnimatedContainer(
            duration: AzmMotion.of(context, AzmMotion.tick),
            curve: AzmMotion.standard,
            width: AzmSize.headerButton,
            height: AzmSize.headerButton,
            decoration: BoxDecoration(
              color: completed ? c.setDone : c.fill,
              borderRadius: BorderRadius.circular(AzmRadius.segment),
            ),
            child: Icon(
              Icons.check_rounded,
              size: AzmSize.icon - AzmSpace.xxs,
              color: completed ? c.onState : c.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 🏆 PR badge. Pops in with the `celebrate` spring, clamped so the badge
/// itself never overshoots past 1.0 (DESIGN.md → Motion). Reduced motion: static.
class PrBadge extends StatefulWidget {
  const PrBadge({super.key, this.style});

  final TextStyle? style;

  static const String trophy = '🏆';

  @override
  State<PrBadge> createState() => _PrBadgeState();
}

class _PrBadgeState extends State<PrBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 0);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AzmMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.animateWith(SpringSimulation(AzmMotion.celebrate, 0, 1, 0));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(scale: _c.value.clamp(0.0, 1.0), child: child),
        child: Text(PrBadge.trophy, style: widget.style ?? AzmType.badgeLabel),
      );
}
