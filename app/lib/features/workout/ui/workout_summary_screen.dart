import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Post-workout summary. Route: AppRoutes.workoutSummary(id).
/// Route pre-registered in core/router/app_router.dart. PLACEHOLDER: the
/// owning feature replaces the body; do not change the class name or constructor.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AzmPlaceholder(icon: Icons.construction_rounded, message: context.l10n.shellComingSoon),
        ),
      );
}
