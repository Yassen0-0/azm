import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_placeholder.dart';

/// Routine editor. Route: AppRoutes.routineNew (routineId == null → new routine) or AppRoutes.routineEditorFor(id).
/// Pre-registered placeholder (docs/PLAN.md → Parallel windows, round 2): keep
/// the class name and constructor, the router builds it.
class RoutineEditorScreen extends StatelessWidget {
  const RoutineEditorScreen({super.key, this.routineId});

  /// Routine to edit, or null for a new one.
  final String? routineId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: '', backLabel: l10n.commonBack, onBack: () => context.pop()),
            Expanded(child: AzmPlaceholder(icon: Icons.edit_note_rounded, message: l10n.shellComingSoon)),
          ],
        ),
      ),
    );
  }
}
