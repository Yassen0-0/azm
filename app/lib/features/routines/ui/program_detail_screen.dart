import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// One ready program (days, exercises, sets) + "Add to my routines". Route: AppRoutes.programFor(id).
/// Pre-registered placeholder (docs/PLAN.md → Parallel windows, round 2): keep
/// the class name and constructor, the router builds it.
class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  /// Catalog program id (`ppl`, `upper_lower`, `full_body_3x`).
  final String programId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: '', backLabel: l10n.commonBack, onBack: () => context.pop()),
            Expanded(child: AzmPlaceholder(icon: Icons.library_books_outlined, message: l10n.shellComingSoon)),
          ],
        ),
      ),
    );
  }
}
