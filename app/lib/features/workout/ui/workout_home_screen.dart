import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';
import '../../../core/widgets/azm_tab_page.dart';

/// Workout tab. Placeholder until features/workout is built (docs/PLAN.md).
class WorkoutHomeScreen extends StatelessWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AzmTabPage(
      title: l10n.shellTabWorkout,
      body: AzmPlaceholder(icon: Icons.fitness_center_rounded, message: l10n.shellComingSoon),
    );
  }
}
