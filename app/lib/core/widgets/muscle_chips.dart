import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// One chip of [MuscleChips]. [value] null = the "all" chip.
@immutable
class MuscleChipItem {
  const MuscleChipItem({required this.value, required this.label});

  final String? value;
  final String label;
}

/// Horizontal scroll of single-select filter chips (DESIGN.md → MuscleChips):
/// pill, `fill` → `accent` when selected, `chipLabel`. The first chip sits at
/// the start edge (mirrors in RTL). Each chip keeps a 48px hit area.
class MuscleChips extends StatelessWidget {
  const MuscleChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.moreLabel,
    this.onMore,
  });

  final List<MuscleChipItem> items;
  final String? selected;
  final ValueChanged<String?> onSelected;

  /// Optional final "More" chip (never selected); tapping it calls [onMore],
  /// which typically adds more [items] inline.
  final String? moreLabel;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final hasMore = moreLabel != null && onMore != null;
    return SizedBox(
      height: AzmSize.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: AzmSpace.xs),
        itemBuilder: (context, i) {
          if (i == items.length) return _Chip(label: moreLabel!, selected: false, onTap: onMore!);
          final item = items[i];
          return _Chip(label: item.label, selected: item.value == selected, onTap: () => onSelected(item.value));
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duration = AzmMotion.of(context, AzmMotion.micro);
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      child: Center(
        child: AnimatedContainer(
          duration: duration,
          curve: AzmMotion.standard,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md, vertical: AzmSpace.xs),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.fill,
            borderRadius: BorderRadius.circular(AzmRadius.pill),
          ),
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: AzmMotion.standard,
            style: AzmType.chipLabel.copyWith(color: selected ? c.onAccent : c.textPrimary),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}
