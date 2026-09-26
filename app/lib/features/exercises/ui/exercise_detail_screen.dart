import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Exercise detail (GIF, instructions, muscles, history, chart, PRs). Route: AppRoutes.exercise(id).
/// Route pre-registered in core/router/app_router.dart. PLACEHOLDER: the
/// owning feature replaces the body; do not change the class name or constructor.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AzmPlaceholder(icon: Icons.construction_rounded, message: context.l10n.shellComingSoon),
        ),
      );
}
