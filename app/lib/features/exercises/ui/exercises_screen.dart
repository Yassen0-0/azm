import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/azm_tab_page.dart';
import 'exercise_browser.dart';

/// Exercises tab: the library (bilingual search + Place / Muscle group /
/// Equipment filters). Tapping an exercise opens its detail.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AzmTabPage(
      title: context.l10n.shellTabExercises,
      body: ExerciseBrowser(onTap: (e) => context.push(AppRoutes.exercise(e.id))),
    );
  }
}
