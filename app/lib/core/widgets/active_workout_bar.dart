import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';
import 'azm_pressable.dart';
import 'rest_timer_bar.dart';

/// Minimized active workout, shown above the tab bar on every tab: workout
/// name, elapsed time, mini rest timer; tap to expand (DESIGN.md).
class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({
    super.key,
    required this.name,
    required this.startedAt,
    required this.semanticLabel,
    required this.onTap,
    this.restEndsAt,
    this.now = DateTime.now,
  });

  final String name;
  final DateTime startedAt;
  final DateTime? restEndsAt;
  final String semanticLabel;
  final VoidCallback onTap;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rest = restEndsAt;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, 0, AzmSpace.pageMargin, AzmSpace.xs),
      child: AzmPressable(
        onTap: onTap,
        semanticLabel: '$semanticLabel, $name',
        child: ExcludeSemantics(
          child: Container(
            height: AzmSize.activeBarHeight,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AzmRadius.card),
              border: Border.all(color: c.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center_rounded, size: AzmSize.icon, color: c.accent),
                const SizedBox(width: AzmSpace.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AzmType.listTitle.copyWith(color: c.textPrimary),
                      ),
                      AzmTicker(
                        now: now,
                        period: const Duration(seconds: 1),
                        builder: (context, t) => Text(
                          formatClock(t.difference(startedAt)),
                          style: AzmType.small.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (rest != null) ...[RestTimerMini(endsAt: rest, now: now), const SizedBox(width: AzmSpace.xs)],
                Icon(Icons.keyboard_arrow_up_rounded, size: AzmSize.icon, color: c.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
