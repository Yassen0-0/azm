import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Full-screen active workout (covers the tab bar). Route: AppRoutes.activeWorkout.
/// Route pre-registered in core/router/app_router.dart. PLACEHOLDER: the
/// owning feature replaces the body; do not change the class name or constructor.
class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AzmPlaceholder(icon: Icons.construction_rounded, message: context.l10n.shellComingSoon),
        ),
      );
}
