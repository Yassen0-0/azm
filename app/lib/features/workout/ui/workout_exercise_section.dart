import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/set_row.dart';
import '../data/workout_models.dart';
import 'workout_format.dart';

/// Callbacks from an exercise section to the active workout screen.
abstract interface class WorkoutSetActions {
  void onLabelTap(WorkoutSet set);
  void onPreviousTap(WorkoutSet set, WorkoutSet previous);
  void onFieldTap(WorkoutExerciseDetail exercise, WorkoutSet set, SetField field);
  void onToggleComplete(WorkoutExerciseDetail exercise, WorkoutSet set, WorkoutSet? previous);
  void onDeleteSet(WorkoutSet set);
  void onAddSet(WorkoutExerciseDetail exercise);
  void onExerciseMenu(WorkoutExerciseDetail exercise, String name);
}

/// One exercise card: header (thumbnail, names, menu), set table, add set.
class WorkoutExerciseSection extends StatelessWidget {
  const WorkoutExerciseSection({
    super.key,
    required this.detail,
    required this.unit,
    required this.actions,
    required this.rowKey,
    this.editing,
  });

  final WorkoutExerciseDetail detail;
  final WeightUnit unit;
  final WorkoutSetActions actions;

  /// Stable key per set row (the screen scrolls the edited row into view).
  final GlobalKey Function(String setId) rowKey;

  /// The set + field currently on the keypad (if in this exercise).
  final ({String setId, SetField field})? editing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final names = namesFor(context, detail.exercise, detail.entry.exerciseId);
    final numbers = normalSetNumbers(detail.sets);

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
                  _UnknownThumb(),
                const SizedBox(width: AzmSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(names.primary, style: AzmType.rowTitle.copyWith(color: c.textPrimary)),
                      if (names.secondary != null)
                        Text(names.secondary!, style: AzmType.secondary.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                AzmHeaderButton(
                  icon: Icons.more_horiz_rounded,
                  semanticLabel: l.workoutExerciseOptions,
                  onTap: () => actions.onExerciseMenu(detail, names.primary),
                ),
              ],
            ),
          ),
          SetTableHeader(
            setLabel: l.workoutColSet,
            previousLabel: l.workoutColPrevious,
            weightLabel: l.unitLabel(unit),
            repsLabel: l.workoutColReps,
          ),
          const SizedBox(height: AzmSpace.xxs),
          for (var i = 0; i < detail.sets.length; i++) _row(context, i, numbers[i]),
          Padding(
            padding: const EdgeInsetsDirectional.all(AzmSpace.md),
            child: AzmPressable(
              onTap: () => actions.onAddSet(detail),
              semanticLabel: l.workoutAddSet,
              child: ExcludeSemantics(
                child: Container(
                  height: AzmSize.headerButton,
                  decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.segment)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: AzmSize.icon - AzmSpace.xxs, color: c.textPrimary),
                      const SizedBox(width: AzmSpace.xxs),
                      Text(l.workoutAddSet, style: AzmType.controlLabel.copyWith(color: c.textPrimary)),
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

  Widget _row(BuildContext context, int i, int? number) {
    final l = context.l10n;
    final s = detail.sets[i];
    final prev = detail.previousFor(i);
    final hasPrev = prev != null && prev.reps > 0;
    final active = editing?.setId == s.id ? editing!.field : null;
    return KeyedSubtree(
      key: rowKey(s.id),
      child: _setRow(l, i, s, number, prev, hasPrev, active),
    );
  }

  Widget _setRow(AppLocalizations l, int i, WorkoutSet s, int? number, WorkoutSet? prev, bool hasPrev, SetField? active) {
    return SetRow(
      key: ValueKey(s.id),
      setId: s.id,
      label: l.setLabelFor(s.type, number),
      labelKind: setLabelKind(s.type),
      previousText: hasPrev ? l.setValue(prev!, unit) : l.workoutNoData,
      weightText: s.weightKg > 0 || s.completedAt != null ? weightNumber(s.weightKg, unit) : '',
      repsText: s.reps > 0 || s.completedAt != null ? '${s.reps}' : '',
      weightHint: hasPrev ? weightNumber(prev!.weightKg, unit) : l.workoutNoData,
      repsHint: hasPrev ? '${prev!.reps}' : l.workoutNoData,
      completed: s.completedAt != null,
      isPr: detail.prs.containsKey(i),
      activeField: active,
      onLabelTap: () => actions.onLabelTap(s),
      onPreviousTap: hasPrev ? () => actions.onPreviousTap(s, prev!) : null,
      onWeightTap: () => actions.onFieldTap(detail, s, SetField.weight),
      onRepsTap: () => actions.onFieldTap(detail, s, SetField.reps),
      onToggleComplete: () => actions.onToggleComplete(detail, s, hasPrev ? prev : null),
      onDelete: () => actions.onDeleteSet(s),
      deleteLabel: l.workoutDeleteSet,
      completeLabel: l.workoutCompleteSet,
    );
  }
}

class _UnknownThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AzmSize.thumbnailList,
      height: AzmSize.thumbnailList,
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.input)),
      child: Icon(Icons.help_outline_rounded, color: c.textTertiary),
    );
  }
}
