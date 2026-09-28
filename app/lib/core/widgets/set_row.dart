import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
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
    // Upper-case captions (SET · PREVIOUS · KG · REPS); Arabic has no case.
    Widget cell(String t) =>
        Text(t.toUpperCase(), style: style, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis);
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
///
/// Delete: the row follows the finger toward the START edge (right to left in
/// English, left to right in Arabic) over a red panel that reaches the screen
/// edge. Released past 25 % it rests open on a "Delete" button (tap it; tap
/// elsewhere or scroll to close; one open row at a time); past 60 % (light
/// haptic when crossing) it deletes at once; otherwise it springs back.
/// Long-press → set menu → "Delete set" and the screen-reader action are the
/// fallbacks. A delete slides the row out and collapses its height before
/// [onDelete] runs, so nothing jumps. Value cells are keyed `set-weight-<setId>` /
/// `set-reps-<setId>` (tests).
class SetRow extends StatefulWidget {
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
    this.valuesMuted = false,
    this.background,
  });

  /// Keys for tests: the long-press target and the menu's delete action.
  static ValueKey<(String, String)> rowKey(String setId) => ValueKey(('set-row-body', setId));
  static const menuDeleteKey = ValueKey('setMenuDelete');
  static const swipeDeleteKey = ValueKey('setSwipeDelete');

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

  /// [weightText] / [repsText] are the app's pre-fill (routine target, a
  /// copied set), not typed yet: drawn muted like a hint until edited.
  final bool valuesMuted;

  /// Row colour when not ✓ (default `card`; the live workout sits on the page).
  final Color? background;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> with TickerProviderStateMixin {
  /// How far the row has slid toward the START edge, in logical px (0 = at
  /// rest). Driven directly by the finger, then by springs.
  late final AnimationController _slide = AnimationController.unbounded(vsync: this);

  /// 1 → 0 while the row's height collapses after a delete.
  late final AnimationController _size = AnimationController(vsync: this, value: 1, duration: AzmMotion.exit);

  double _width = 0;

  /// Distance from the row's END edge to the screen edge (the red panel
  /// bleeds over the page margin to the screen edge).
  double _bleed = 0;
  bool _pastDelete = false; // haptic once per crossing of the delete threshold
  bool _deleting = false;
  ScrollPosition? _scroll;

  /// Collapsed and handed to [SetRow.onDelete]: render nothing until the
  /// parent drops this row (the DB stream re-emits a few ms later).
  bool _gone = false;

  /// Resting open (or springing there) on the Delete button.
  bool _openState = false;
  bool get _open => _openState && !_deleting;

  @override
  void dispose() {
    _unwatchScroll();
    if (_SwipeRegistry.open == this) _SwipeRegistry.open = null;
    _slide.dispose();
    _size.dispose();
    super.dispose();
  }

  /// +1 when the END edge is on the right (English), −1 when it is on the
  /// left (Arabic): drag deltas and translations are physical.
  double get _endSign => AlignmentDirectional.centerEnd.resolve(Directionality.of(context)).x;

  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _width = box.size.width;
    final originX = box.localToGlobal(Offset.zero).dx;
    final screen = MediaQuery.sizeOf(context).width;
    _bleed = (_endSign > 0 ? screen - (originX + _width) : originX).clamp(0.0, AzmSpace.xxxl * 2);
  }

  /// Offset at which a partial swipe rests open: wide enough to show the
  /// whole "Delete" label (adaptive to the text scale), within 50 % of the row.
  double get _openExtent {
    final needed = SetSwipeMetrics.labelWidth(context) + 2 * AzmSpace.xl - _bleed;
    return needed.clamp(SetSwipeMetrics.minOpen, _width * SetSwipeMetrics.maxOpenFraction);
  }

  // ---- Gestures ------------------------------------------------------------------

  void _onDragStart(DragStartDetails _) {
    if (_deleting) return;
    final other = _SwipeRegistry.open;
    if (other != null && other != this) other._close();
    _slide.stop();
    _measure();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_deleting || _width <= 0) return;
    final towardStart = -d.delta.dx * _endSign;
    final v = (_slide.value + towardStart).clamp(0.0, _width);
    _slide.value = v;
    final past = v >= _width * SetSwipeMetrics.deleteFraction;
    if (past && !_pastDelete) unawaited(HapticFeedback.lightImpact());
    _pastDelete = past;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_deleting || _width <= 0) return;
    final velocity = -d.velocity.pixelsPerSecond.dx * _endSign; // + = toward start
    final v = _slide.value;
    _pastDelete = false;
    if (v >= _width * SetSwipeMetrics.deleteFraction ||
        (velocity > SetSwipeMetrics.flingVelocity && v >= _width * SetSwipeMetrics.openFraction)) {
      unawaited(_delete());
    } else if (v >= _width * SetSwipeMetrics.openFraction && velocity > -SetSwipeMetrics.flingVelocity) {
      _snapTo(_openExtent);
    } else {
      _close();
    }
  }

  void _snapTo(double target) {
    if (target > 0) {
      final other = _SwipeRegistry.open;
      if (other != null && other != this) other._close();
      _SwipeRegistry.open = this;
      _watchScroll();
    }
    _openState = target > 0;
    if (AzmMotion.reduced(context)) {
      _slide.value = target;
    } else {
      // Springs stop within a tolerance: land exactly on the target.
      _slide.animateWith(SpringSimulation(AzmMotion.crisp, _slide.value, target, 0)).whenCompleteOrCancel(() {
        if (mounted && !_deleting && _slide.value != target && (_slide.value - target).abs() < 1) _slide.value = target;
      });
    }
    setState(() {}); // tap-outside region + close overlay follow the open state
  }

  void _close() {
    if (!mounted || _deleting) return;
    if (_SwipeRegistry.open == this) _SwipeRegistry.open = null;
    _unwatchScroll();
    _snapTo(0);
  }

  void _watchScroll() {
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos == _scroll) return;
    _unwatchScroll();
    _scroll = pos?..addListener(_close);
  }

  void _unwatchScroll() {
    _scroll?.removeListener(_close);
    _scroll = null;
  }

  /// Slide out, collapse the height, then delete (no layout jump).
  Future<void> _delete() async {
    if (_deleting) return;
    _deleting = true;
    _openState = false;
    if (_SwipeRegistry.open == this) _SwipeRegistry.open = null;
    _unwatchScroll();
    _measure();
    setState(() {});
    if (!AzmMotion.reduced(context)) {
      await _slide.animateTo(_width, duration: AzmMotion.exit, curve: AzmMotion.standard);
      if (!mounted) return;
      await _size.animateTo(0, curve: AzmMotion.standard);
      if (!mounted) return;
    }
    setState(() => _gone = true);
    widget.onDelete();
  }

  Future<void> _openMenu() async {
    if (_open) return _close();
    if (await showSetMenuSheet(context, label: widget.label, kind: widget.labelKind, deleteLabel: widget.deleteLabel) &&
        mounted) {
      unawaited(_delete());
    }
  }

  // ---- Build -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final w = widget;
    final c = context.colors;
    final tick = AzmMotion.of(context, AzmMotion.tick);

    final row = AnimatedContainer(
      duration: tick,
      curve: AzmMotion.standard,
      constraints: const BoxConstraints(minHeight: AzmSize.setRowMinHeight),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs),
      color: w.completed ? c.setDoneTint : (w.background ?? c.card),
      child: Row(
        children: [
          _LabelCell(label: w.label, kind: w.labelKind, onTap: w.onLabelTap, semanticLabel: w.labelSemantics ?? w.label),
          if (w.previousText != null)
            Expanded(
              flex: SetRowColumns.previousFlex,
              child: AzmPressable(
                onTap: w.onPreviousTap,
                child: Center(
                  child: Text(
                    w.previousText!,
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
              key: ValueKey('set-weight-${w.setId}'),
              text: w.weightText,
              hint: w.weightHint,
              active: w.activeField == SetField.weight,
              completed: w.completed,
              muted: w.valuesMuted,
              onTap: w.onWeightTap,
            ),
          ),
          Expanded(
            flex: SetRowColumns.valueFlex,
            child: _ValueCell(
              key: ValueKey('set-reps-${w.setId}'),
              text: w.repsText,
              hint: w.repsHint,
              active: w.activeField == SetField.reps,
              completed: w.completed,
              muted: w.valuesMuted,
              onTap: w.onRepsTap,
              badge: w.isPr ? const PrBadge() : null,
            ),
          ),
          if (w.onToggleComplete != null)
            _CheckCell(completed: w.completed, onTap: w.onToggleComplete!, semanticLabel: w.completeLabel ?? ''),
        ],
      ),
    );

    final endSign = _endSign;
    final sliding = AnimatedBuilder(
      animation: _slide,
      builder: (context, child) {
        final d = _slide.value;
        // Everything from the row content's END edge to the screen edge is
        // red; the part over the page margin grows with the finger too.
        final outside = d <= 0 ? 0.0 : (d < _bleed ? d : _bleed);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (d >= 0.5)
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: -outside,
                width: d + outside,
                child: _DeletePanel(
                  label: context.l10n.commonSwipeDelete,
                  semanticLabel: w.deleteLabel,
                  endInset: outside,
                  onTap: () => unawaited(_delete()),
                ),
              ),
            ClipRect(
              child: Transform.translate(
                offset: Offset(-d * endSign, 0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: Stack(
        children: [
          row,
          // While open, a tap on the row closes it instead of editing.
          if (_open)
            Positioned.fill(
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close),
            ),
        ],
      ),
    );

    final swipeable = TapRegion(
      onTapOutside: _open ? (_) => _close() : null,
      child: Semantics(
        customSemanticsActions: {CustomSemanticsAction(label: w.deleteLabel): () => unawaited(_delete())},
        child: GestureDetector(
          key: SetRow.rowKey(w.setId),
          behavior: HitTestBehavior.opaque,
          onLongPress: _openMenu,
          // The row tracks the finger from where it touched (no lost slop).
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: () => _onDragEnd(DragEndDetails()),
          child: sliding,
        ),
      ),
    );
    // SizeTransition clips its child, which would cut the red panel off at
    // the card edge: only wrap while the height collapses after a delete.
    if (!_deleting) return swipeable;
    return SizeTransition(sizeFactor: _size, alignment: AlignmentDirectional.topCenter, child: swipeable);
  }
}

/// Thresholds and sizes of the set swipe (docs/DESIGN.md → SetRow).
abstract final class SetSwipeMetrics {
  /// Past this share of the row width on release, the row snaps open.
  static const double openFraction = 0.25;

  /// Past this share, the set is deleted (light haptic when crossing it).
  static const double deleteFraction = 0.6;

  /// Open width limits.
  static const double minOpen = AzmSize.setCellMinWidth + AzmSpace.xl;
  static const double maxOpenFraction = 0.5;

  /// A fling toward the start this fast deletes (from the open threshold on).
  static const double flingVelocity = 1500;

  /// Width of icon + gap + "Delete" at the current text scale.
  static double labelWidth(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: context.l10n.commonSwipeDelete, style: AzmType.controlLabel),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = AzmSize.icon + AzmSpace.xs + tp.width;
    tp.dispose();
    return w;
  }
}

/// Only one set row is open at a time: opening (or starting to drag) another
/// closes the previous one.
abstract final class _SwipeRegistry {
  static _SetRowState? open;
}

/// The red delete panel: full row height, square corners, flush with the
/// screen edge; "Delete" + trash pinned near the screen edge. The label
/// never truncates: when the panel is too narrow for it, only the icon shows.
class _DeletePanel extends StatelessWidget {
  const _DeletePanel({required this.label, required this.semanticLabel, required this.endInset, required this.onTap});

  final String label;
  final String semanticLabel;

  /// Part of the panel over the page margin (not hit-testable: outside the row).
  final double endInset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final full = SetSwipeMetrics.labelWidth(context) + 2 * AzmSpace.xl;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        key: SetRow.swipeDeleteKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: c.destructive,
          child: LayoutBuilder(
            builder: (context, box) {
              final showText = box.maxWidth >= full;
              final showIcon = box.maxWidth >= AzmSize.icon + AzmSpace.xs;
              return Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: showText ? AzmSpace.xl : AzmSpace.xxs),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showIcon) Icon(Icons.delete_outline_rounded, color: c.onState, size: AzmSize.icon),
                        if (showText) ...[
                          const SizedBox(width: AzmSpace.xs),
                          Text(label, maxLines: 1, softWrap: false, style: AzmType.controlLabel.copyWith(color: c.onState)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Long-press menu of a set row: "Delete set" (destructive). Returns true
/// when the user chose to delete. Shared by every set table.
Future<bool> showSetMenuSheet(
  BuildContext context, {
  required String label,
  required SetLabelKind kind,
  required String deleteLabel,
}) async {
  unawaited(HapticFeedback.selectionClick());
  final delete = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
              child: Row(
                children: [
                  SetLabelChip(label: label, kind: kind),
                  const SizedBox(width: AzmSpace.md),
                  Expanded(child: Text(ctx.l10n.commonSetColSet, style: AzmType.cardTitle.copyWith(color: c.textPrimary))),
                ],
              ),
            ),
            AzmPressable(
              key: SetRow.menuDeleteKey,
              onTap: () => Navigator.pop(ctx, true),
              semanticLabel: deleteLabel,
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxl, vertical: AzmSpace.md),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: c.destructiveText, size: AzmSize.icon),
                      const SizedBox(width: AzmSpace.md),
                      Expanded(child: Text(deleteLabel, style: AzmType.itemLabel.copyWith(color: c.destructiveText))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AzmSpace.xs),
          ],
        ),
      );
    },
  );
  return delete ?? false;
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
      width: AzmSize.setBox,
      height: AzmSize.setBox,
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
    this.muted = false,
    this.badge,
  });

  final String text;
  final String hint;
  final bool active;
  final bool completed;
  final bool muted;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final empty = text.isEmpty;
    // Outlined box (KG / REPS). Hint and pre-filled values are muted until
    // edited; a ✓ row drops the outline. The whole cell is the tap target.
    final color = empty ? c.textTertiary : (muted && !completed ? c.textTertiary : c.textPrimary);
    final border = active
        ? Border.all(color: c.accent, width: AzmSize.outlineActive)
        : Border.all(color: completed ? Colors.transparent : c.checkboxBorder, width: AzmSize.outline);
    return AzmPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AzmSize.touchCompact),
        child: Center(
          child: AnimatedContainer(
            duration: AzmMotion.of(context, AzmMotion.micro),
            margin: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxs),
            constraints: const BoxConstraints(minHeight: AzmSize.setBox),
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AzmRadius.segment),
              border: border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    empty ? hint : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.rowNumber.copyWith(color: color),
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: AzmSpace.opticalInset), badge!],
              ],
            ),
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
            width: AzmSize.setBox,
            height: AzmSize.setBox,
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
