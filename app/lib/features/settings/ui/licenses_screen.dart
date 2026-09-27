import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Licences and attributions (exercise dataset MIT, Readex Pro OFL, Gym visual
/// attribution, package licences). Route: AppRoutes.licenses.
/// Pre-registered placeholder (docs/PLAN.md → Parallel windows, round 3): keep
/// the class name and constructor, the router builds it.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: '', backLabel: l10n.commonBack, onBack: () => context.pop()),
            Expanded(child: AzmPlaceholder(icon: Icons.gavel_rounded, message: l10n.shellComingSoon)),
          ],
        ),
      ),
    );
  }
}
