import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import 'history_text.dart';

/// Card surface (the card is the elevation: no shadows).
class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.child, this.padded = true});

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padded ? const EdgeInsetsDirectional.all(AzmSpace.cardPadding) : null,
        decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class HistorySectionTitle extends StatelessWidget {
  const HistorySectionTitle(this.text, {super.key, this.top = AzmSpace.xxxl});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(AzmSpace.xxs, top, AzmSpace.xxs, AzmSpace.md),
        child: Semantics(
          header: true,
          child: Text(text, style: AzmType.cardTitle.copyWith(color: context.colors.textPrimary)),
        ),
      );
}

/// Label over a value, centred (stat rows).
class HistoryStat extends StatelessWidget {
  const HistoryStat({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AzmType.statLabel.copyWith(color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AzmSpace.opticalInset),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AzmType.rowNumber.copyWith(color: valueColor ?? c.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// The all-time Lifted number in compact form (`1.2M kg`), counting up to
/// each new value with motion `value` (600 ms). Starts at its value (no
/// count-up from 0 every time the tab opens); reduced motion jumps.
/// Same layout as `LiftedCounter` (history size), which can't format compactly.
class CompactLiftedNumber extends StatelessWidget {
  const CompactLiftedNumber({super.key, required this.kg, required this.unit});

  final double kg;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final v = Units.toDisplay(kg, unit);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: v, end: v),
      duration: AzmMotion.of(context, AzmMotion.valueDuration),
      curve: AzmMotion.value,
      builder: (context, x, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              v <= 0 ? l.historyNoData : ltr(l.compact(x)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AzmType.liftedNumber.copyWith(color: v <= 0 ? c.textNoData : c.textPrimary),
            ),
          ),
          const SizedBox(width: AzmSpace.xxs),
          Text(l.unitLabel(unit), style: AzmType.rowTitle.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// Two-option segmented control (fill track, card thumb, radius segment).
class HistorySegmented<T> extends StatelessWidget {
  const HistorySegmented({super.key, required this.options, required this.selected, required this.onChanged});

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(AzmSpace.opticalInset),
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.segment + AzmSpace.opticalInset)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: AzmPressable(
                onTap: () => onChanged(o.value),
                selected: o.value == selected,
                semanticLabel: o.label,
                child: ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: AzmMotion.of(context, AzmMotion.segment),
                    curve: AzmMotion.standard,
                    height: AzmSize.headerButton,
                    alignment: AlignmentDirectional.center,
                    decoration: BoxDecoration(
                      color: o.value == selected ? c.card : c.fill,
                      borderRadius: BorderRadius.circular(AzmRadius.segment),
                    ),
                    child: Text(
                      o.label,
                      style: AzmType.controlLabel.copyWith(color: o.value == selected ? c.textPrimary : c.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wide button (add exercise / delete workout).
class HistoryWideButton extends StatelessWidget {
  const HistoryWideButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = primary ? c.accent : (destructive ? c.destructiveText : c.textPrimary);
    final bg = primary ? c.accentSoft : (destructive ? c.destructiveTint : c.fill);
    return AzmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.input,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AzmRadius.button)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: fg, size: AzmSize.icon), const SizedBox(width: AzmSpace.xs)],
              Flexible(child: Text(label, style: AzmType.button.copyWith(color: fg), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered empty state (icon, title, body).
class HistoryEmpty extends StatelessWidget {
  const HistoryEmpty({super.key, required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AzmSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AzmSize.minTouchTarget, color: c.textNoData),
            const SizedBox(height: AzmSpace.md),
            Text(title, textAlign: TextAlign.center, style: AzmType.emptyTitle.copyWith(color: c.textPrimary)),
            if (body != null) ...[
              const SizedBox(height: AzmSpace.xs),
              Text(body!, textAlign: TextAlign.center, style: AzmType.secondary.copyWith(color: c.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
