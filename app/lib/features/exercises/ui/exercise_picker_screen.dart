import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_header.dart';
import '../data/exercise_filters.dart';
import 'exercise_browser.dart';

/// Multi-select exercise picker. CONTRACT: pops a `List<String>` of catalog ids in selection order (or null if cancelled): `final ids = await context.push<List<String>>(AppRoutes.exercisePicker);`
///
/// Tapping a row toggles it; the row shows its position in the selection
/// (1, 2, 3…). Removing one renumbers the rest. Close / system back pops null.
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final List<String> _selected = [];

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final count = _selected.length;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xs, AzmSpace.xs, AzmSpace.pageMargin, AzmSpace.xs),
              child: Row(
                children: [
                  AzmHeaderButton(
                    icon: Icons.close_rounded,
                    semanticLabel: l10n.exercisesPickerCancel,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: AzmSpace.xxs),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.exercisesPickerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AzmType.screenTitle.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ExerciseBrowser(selection: _selected, onTap: (e) => _toggle(e.id), screen: FilterScreen.picker),
            ),
            ColoredBox(
              color: c.pageBackground,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  MediaQuery.paddingOf(context).bottom + AzmSpace.xs,
                ),
                child: FilledButton(
                  key: const ValueKey('exercisePickerConfirm'),
                  onPressed: count == 0 ? null : () => context.pop<List<String>>(List.unmodifiable(_selected)),
                  child: Text(count == 0 ? l10n.exercisesPickerAdd : l10n.exercisesPickerAddCount(count)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
