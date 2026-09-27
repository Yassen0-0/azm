import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/set_row.dart';
import '../../workout/data/workout_models.dart';
import 'history_text.dart';

/// Callbacks from an exercise section to the past workout screen.
abstract interface class PastSetActions {
  void onLabelTap(WorkoutSet set);
  void onPreviousTap(WorkoutSet set, WorkoutSet previous);
  void onFieldTap(WorkoutSet set, SetField field);
  void onToggleComplete(WorkoutSet set, WorkoutSet? previous);
  void onDeleteSet(WorkoutSet set);
  void onAddSet(WorkoutExerciseDetail exercise);
  void onExerciseMenu(WorkoutExerciseDetail exercise, String name);
}

/// One exercise of a past workout: header (thumbnail, names, menu), the same
/// SetRow table as the live workout ("previous" = the workout before this
/// one; 🏆 = PR versus every earlier workout), add set.
class PastExerciseSection extends StatelessWidget {
  const PastExerciseSection({
    super.key,
    required this.detail,
    required this.unit,
    required this.actions,
    required this.rowKey,
    this.editing,
  });

  final WorkoutExerciseDetail detail;
  final WeightUnit unit;
  final PastSetActions actions;
  final GlobalKey Function(String setId) rowKey;
  final ({String setId, SetField field})? editing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final names = namesOrUnknown(context, detail.exercise, detail.entry.exerciseId);
    final numbers = normalNumbers(detail.sets.map((s) => s.type));

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AzmSpace.listGap),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.md, AzmSpace.md, AzmSpace.xxs, AzmSpace.xs),
            child: Row(
              children: [
                if (detail.exercise != null)
                  ExerciseThumbnail(exercise: detail.exercise!)
                else
                  Container(
                    width: AzmSize.thumbnailList,
                    height: AzmSize.thumbnailList,
                    decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.input)),
                    child: Icon(Icons.help_outline_rounded, color: c.textTertiary),
                  ),
                const SizedBox(width: AzmSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isolate(names.primary), style: AzmType.rowTitle.copyWith(color: c.textPrimary)),
                      if (names.secondary != null)
                        Text(isolate(names.secondary!), style: AzmType.secondary.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                AzmHeaderButton(
                  icon: Icons.more_horiz_rounded,
                  semanticLabel: l.historyExerciseOptions,
                  onTap: () => actions.onExerciseMenu(detail, names.primary),
                ),
              ],
            ),
          ),
          SetTableHeader(
            setLabel: l.historyColSet,
            previousLabel: l.historyColPrevious,
            weightLabel: l.unitLabel(unit),
            repsLabel: l.historyColReps,
          ),
          const SizedBox(height: AzmSpace.xxs),
          for (var i = 0; i < detail.sets.length; i++)
            KeyedSubtree(key: rowKey(detail.sets[i].id), child: _row(l, i, numbers[i])),
          Padding(
            padding: const EdgeInsetsDirectional.all(AzmSpace.md),
            child: AzmPressable(
              onTap: () => actions.onAddSet(detail),
              semanticLabel: l.historyAddSet,
              child: ExcludeSemantics(
                child: Container(
                  height: AzmSize.headerButton,
                  decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.segment)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: AzmSize.icon - AzmSpace.xxs, color: c.textPrimary),
                      const SizedBox(width: AzmSpace.xxs),
                      Text(l.historyAddSet, style: AzmType.controlLabel.copyWith(color: c.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppLocalizations l, int i, int? number) {
    final s = detail.sets[i];
    final prev = detail.previousFor(i);
    final hasPrev = prev != null && prev.reps > 0;
    final done = s.completedAt != null;
    return SetRow(
      key: ValueKey(s.id),
      setId: s.id,
      label: l.setLabel(s.type, number),
      labelKind: labelKind(s.type),
      previousText: hasPrev ? l.setValue(prev, unit, withUnit: false) : l.historyNoData,
      weightText: s.weightKg > 0 || done ? weightNumber(s.weightKg, unit) : '',
      repsText: s.reps > 0 || done ? AzmNumbers.integer(s.reps) : '',
      weightHint: hasPrev ? weightNumber(prev.weightKg, unit) : l.historyNoData,
      repsHint: hasPrev ? AzmNumbers.integer(prev.reps) : l.historyNoData,
      completed: done,
      isPr: detail.prs.containsKey(i),
      activeField: editing?.setId == s.id ? editing!.field : null,
      onLabelTap: () => actions.onLabelTap(s),
      onPreviousTap: hasPrev ? () => actions.onPreviousTap(s, prev) : null,
      onWeightTap: () => actions.onFieldTap(s, SetField.weight),
      onRepsTap: () => actions.onFieldTap(s, SetField.reps),
      onToggleComplete: () => actions.onToggleComplete(s, hasPrev ? prev : null),
      onDelete: () => actions.onDeleteSet(s),
      deleteLabel: l.historyDeleteSet,
      completeLabel: l.historyCompleteSet,
    );
  }
}
