import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// One destination of [AzmTabBar].
class AzmTabItem {
  const AzmTabItem({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// The floating glass tab bar — the ONLY blur in the app.
/// Pill, 64 high, lifted 12 above the bottom inset, card tint at 85% over a
/// σ24 blur, 1px `glassBorder`. Active = accent, inactive = textTertiary.
/// Item order follows reading direction (first tab at the start edge).
class AzmTabBar extends StatelessWidget {
  const AzmTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<AzmTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final duration = AzmMotion.of(context, AzmMotion.nav);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AzmSpace.pageMargin,
        end: AzmSpace.pageMargin,
        bottom: bottomInset + AzmSize.tabBarLift,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AzmRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AzmGlass.blurSigma, sigmaY: AzmGlass.blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.card.withValues(alpha: AzmGlass.tintOpacity),
              borderRadius: BorderRadius.circular(AzmRadius.pill),
              border: Border.all(color: c.glassBorder, width: AzmGlass.borderWidth),
            ),
            child: SizedBox(
              height: AzmSize.tabBarHeight,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _TabButton(
                        item: items[i],
                        selected: i == currentIndex,
                        duration: duration,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final AzmTabItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.textTertiary;
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: item.label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: duration,
              curve: AzmMotion.standard,
              builder: (context, value, _) => Icon(
                selected ? item.activeIcon : item.icon,
                size: AzmSize.tabBarIcon,
                color: value,
              ),
            ),
            const SizedBox(height: AzmSpace.opticalInset),
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: AzmMotion.standard,
              style: AzmType.tabLabel.copyWith(color: color),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
