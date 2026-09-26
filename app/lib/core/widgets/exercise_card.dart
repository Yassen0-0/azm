import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../l10n/exercise_names.dart';
import '../media/exercise_media.dart';
import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// Exercise row for lists (DESIGN.md → ExerciseCard): thumbnail (or the
/// muscle-icon fallback), primary name (`rowTitle`), secondary name in the
/// other language (`secondary`), optional 🏆 record badge.
///
/// Selection mode (the picker): pass [selectable] = true and the 1-based
/// [selectionIndex] when selected; the end shows the position in the selection.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.recordLabel,
    this.recordSemanticLabel,
    this.selectable = false,
    this.selectionIndex,
    this.selectionSemanticLabel,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  /// Text of the record badge (e.g. "100 kg"), or null for no badge.
  final String? recordLabel;
  final String? recordSemanticLabel;

  final bool selectable;
  final int? selectionIndex;
  final String? selectionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final names = context.namesOf(exercise);
    final selected = selectionIndex != null;
    return AzmPressable(
      onTap: onTap,
      selected: selectable ? selected : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin, vertical: AzmSpace.xs),
        child: Row(
          children: [
            ExerciseThumbnail(exercise: exercise),
            const SizedBox(width: AzmSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    names.primary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.rowTitle.copyWith(color: c.textPrimary),
                  ),
                  if (names.secondary != null)
                    Text(
                      names.secondary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AzmType.secondary.copyWith(color: c.textSecondary),
                    ),
                ],
              ),
            ),
            if (recordLabel != null) ...[
              const SizedBox(width: AzmSpace.xs),
              _RecordBadge(label: recordLabel!, semanticLabel: recordSemanticLabel),
            ],
            if (selectable) ...[
              const SizedBox(width: AzmSpace.md),
              _SelectionMark(index: selectionIndex, semanticLabel: selectionSemanticLabel),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.label, this.semanticLabel});

  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs, vertical: AzmSpace.xxs),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AzmRadius.pill)),
        child: Text('🏆 $label', maxLines: 1, style: AzmType.badgeLabel.copyWith(color: c.pr)),
      ),
    );
  }
}

/// Empty ring when not selected; accent disc with the 1-based position when selected.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.index, this.semanticLabel});

  final int? index;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = index != null;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AzmMotion.of(context, AzmMotion.micro),
        curve: AzmMotion.standard,
        width: AzmSize.checkbox,
        height: AzmSize.checkbox,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: selected ? c.accent : null,
          shape: BoxShape.circle,
          border: selected ? null : Border.all(color: c.checkboxBorder, width: 1.5),
        ),
        child: selected ? Text('$index', style: AzmType.badgeLabel.copyWith(color: c.onAccent)) : null,
      ),
    );
  }
}
