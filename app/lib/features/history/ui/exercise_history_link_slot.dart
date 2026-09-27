import 'package:flutter/material.dart';

/// "See all history" entry on the exercise detail screen, rendered by
/// ExerciseDetailScreen under its recent sessions (→ AppRoutes.exerciseHistoryFor).
/// Pre-registered slot (docs/PLAN.md → Parallel windows, round 2): keep the
/// class name and constructor. Empty until the history window builds it.
class ExerciseHistoryLinkSlot extends StatelessWidget {
  const ExerciseHistoryLinkSlot({super.key, required this.exerciseId, required this.sessionCount});

  /// Catalog exercise id.
  final String exerciseId;

  /// Finished workouts with this exercise (the detail shows at most 10).
  final int sessionCount;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
