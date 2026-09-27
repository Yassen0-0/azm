import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';

/// "See all history" entry on the exercise detail screen, rendered by
/// ExerciseDetailScreen under its recent sessions (→ AppRoutes.exerciseHistoryFor).
/// Pre-registered slot (docs/PLAN.md → Parallel windows, round 2): keep the
/// class name and constructor. Shown only when there are more sessions than
/// the detail lists.
class ExerciseHistoryLinkSlot extends StatelessWidget {
  const ExerciseHistoryLinkSlot({super.key, required this.exerciseId, required this.sessionCount});

  /// Catalog exercise id.
  final String exerciseId;

  /// Finished workouts with this exercise (the detail shows at most 10).
  final int sessionCount;

  /// Sessions the exercise detail lists itself (ExerciseDetailScreen.recentSessions).
  static const int shownOnDetail = 10;

  static const linkKey = ValueKey('exerciseHistorySeeAll');

  @override
  Widget build(BuildContext context) {
    if (sessionCount <= shownOnDetail) return const SizedBox.shrink();
    final c = context.colors;
    final l = context.l10n;
    final label = l.historySeeAll(AzmNumbers.integer(sessionCount));
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AzmSpace.listGap),
      child: AzmPressable(
        key: linkKey,
        onTap: () => context.push(AppRoutes.exerciseHistoryFor(exerciseId)),
        semanticLabel: label,
        child: ExcludeSemantics(
          child: Container(
            height: AzmSize.input,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.cardPadding),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: c.accent, size: AzmSize.icon),
                const SizedBox(width: AzmSpace.md),
                Expanded(child: Text(label, style: AzmType.button.copyWith(color: c.accent))),
                // Directional: mirrors in RTL.
                Icon(Icons.chevron_right_rounded, color: c.accent, size: AzmSize.icon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
