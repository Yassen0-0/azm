import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Multi-select exercise picker. CONTRACT: pops a `List<String>` of catalog ids in selection order (or null if cancelled): `final ids = await context.push<List<String>>(AppRoutes.exercisePicker);`
/// Route pre-registered in core/router/app_router.dart. PLACEHOLDER: the
/// owning feature replaces the body; do not change the class name or constructor.
class ExercisePickerScreen extends StatelessWidget {
  const ExercisePickerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AzmPlaceholder(icon: Icons.construction_rounded, message: context.l10n.shellComingSoon),
        ),
      );
}
