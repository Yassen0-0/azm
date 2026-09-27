import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Stats: workouts per week, total sets, per-exercise PR list. Route: AppRoutes.stats.
/// Pre-registered placeholder (docs/PLAN.md → Parallel windows, round 2): keep
/// the class name and constructor, the router builds it.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: '', backLabel: l10n.commonBack, onBack: () => context.pop()),
            Expanded(child: AzmPlaceholder(icon: Icons.insights_rounded, message: l10n.shellComingSoon)),
          ],
        ),
      ),
    );
  }
}
