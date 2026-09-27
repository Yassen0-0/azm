import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// First-run onboarding (≤ 2 screens: unit, optional ready program).
/// Route: AppRoutes.onboarding. The router opens it at launch when
/// [onboardingDoneAtLaunchProvider] is false; on finish it must write
/// `onboarding_done` and `context.go(AppRoutes.workout)`.
/// Pre-registered placeholder (docs/PLAN.md → Parallel windows, round 2): keep
/// the class name and constructor, the router builds it.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AzmPlaceholder(icon: Icons.waving_hand_outlined, message: context.l10n.shellComingSoon),
      ),
    );
  }
}
