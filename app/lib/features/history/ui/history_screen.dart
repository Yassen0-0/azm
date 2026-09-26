import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/azm_placeholder.dart';
import '../../../core/widgets/azm_tab_page.dart';

/// History tab. Placeholder until features/history is built (docs/PLAN.md).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AzmTabPage(
      title: l10n.shellTabHistory,
      body: AzmPlaceholder(icon: Icons.history_rounded, message: l10n.shellComingSoon),
    );
  }
}
