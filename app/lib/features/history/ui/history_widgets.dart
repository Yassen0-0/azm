import 'package:flutter/material.dart';

import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';

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
          // A number is never cut off: it shrinks to fit a narrow cell
          // (4 stats on a 402 pt iPhone: "1,440 kg" was "1,440 …").
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AzmType.rowNumber.copyWith(color: valueColor ?? c.textPrimary),
            ),
          ),
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
