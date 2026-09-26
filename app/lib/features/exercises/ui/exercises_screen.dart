import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';
import '../../../core/widgets/azm_tab_page.dart';

/// Exercises tab. Placeholder until features/exercises is built (docs/PLAN.md).
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AzmTabPage(
      title: l10n.shellTabExercises,
      body: AzmPlaceholder(icon: Icons.format_list_bulleted_rounded, message: l10n.shellComingSoon),
    );
  }
}
