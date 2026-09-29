import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/set_row.dart';
import '../data/workout_models.dart';
import 'workout_format.dart';
import 'workout_sheets.dart' show formatRestSeconds;

/// Callbacks from an exercise section to the active workout screen.
abstract interface class WorkoutSetActions {
  void onLabelTap(WorkoutSet set);
  void onPreviousTap(WorkoutSet set, WorkoutSet previous);
  void onFieldTap(WorkoutExerciseDetail exercise, WorkoutSet set, SetField field);
  void onToggleComplete(WorkoutExerciseDetail exercise, WorkoutSet set, WorkoutSet? previous);
  void onDeleteSet(WorkoutSet set);
  void onAddSet(WorkoutExerciseDetail exercise);
  void onExerciseMenu(WorkoutExerciseDetail exercise, String name);
  void onNotesChanged(WorkoutExerciseDetail exercise, String notes);
  void onNotesFocus();
  void onRestTap(WorkoutExerciseDetail exercise, String name);
}

/// One exercise block of the live workout (Hevy layout, no card): round
/// thumbnail + name (accent) + ⋮ menu, a one-line notes field, the tappable
/// "Rest Timer: 1:30 / OFF" line, the SET | PREVIOUS | KG | REPS | ✓ table
/// and a full-width "+ Add set" button.
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
    final numbers = normalSetNumbers(detail.sets.map((s) => s.type));
    final rest = detail.restOff ? l.workoutRestOff : formatRestSeconds(detail.restSeconds);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AzmSpace.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (detail.exercise != null)
                ExerciseThumbnail(exercise: detail.exercise!, size: AzmSize.avatar, round: true)
              else
                const _UnknownAvatar(),
              // A real thumbnail sits at the start of a minTouchTarget box (its slack is
              // part of the gap); the unknown avatar is exactly AzmSize.avatar wide.
              SizedBox(width: detail.exercise != null ? AzmSpace.xxs : AzmSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      names.primary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AzmType.rowTitle.copyWith(color: c.accent),
                    ),
                    if (names.secondary != null)
                      Text(
                        names.secondary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AzmType.small.copyWith(color: c.textTertiary),
                      ),
                  ],
                ),
              ),
              AzmPressable(
                key: ValueKey('exercise-menu-${detail.entry.id}'),
                onTap: () => actions.onExerciseMenu(detail, names.primary),
                semanticLabel: l.workoutExerciseOptions,
                child: Icon(Icons.more_vert_rounded, color: c.textPrimary, size: AzmSize.icon),
              ),
            ],
          ),
          _NotesField(
            key: ValueKey('exercise-notes-${detail.entry.id}'),
            initial: detail.entry.notes ?? '',
            hint: l.workoutNotesHint,
            onFocus: actions.onNotesFocus,
            onChanged: (v) => actions.onNotesChanged(detail, v),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AzmPressable(
              key: ValueKey('exercise-rest-${detail.entry.id}'),
              onTap: () => actions.onRestTap(detail, names.primary),
              semanticLabel: l.workoutRestLine(rest),
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AzmSize.touchCompact),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detail.restOff ? Icons.timer_off_outlined : Icons.timer_outlined,
                        color: c.accent,
                        size: AzmSize.icon - AzmSpace.xxs,
                      ),
                      const SizedBox(width: AzmSpace.xs),
                      Text(l.workoutRestLine(rest), style: AzmType.itemLabel.copyWith(color: c.accent)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SetTableHeader(
            setLabel: l.commonSetColSet,
            previousLabel: l.commonSetColPrevious,
            weightLabel: l.weightUnitLabel(unit),
            repsLabel: l.commonSetColReps,
          ),
          for (var i = 0; i < detail.sets.length; i++) _row(context, i, numbers[i]),
          const SizedBox(height: AzmSpace.xs),
          AzmPressable(
            key: ValueKey('exercise-add-set-${detail.entry.id}'),
            onTap: () => actions.onAddSet(detail),
            semanticLabel: l.workoutAddSet,
            child: ExcludeSemantics(
              child: Container(
                height: AzmSize.buttonCompact,
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.input)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: AzmSize.icon, color: c.textPrimary),
                    const SizedBox(width: AzmSpace.xs),
                    Text(l.workoutAddSet, style: AzmType.button.copyWith(color: c.textPrimary)),
                  ],
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
      child: _setRow(context, l, i, s, number, prev, hasPrev, active),
    );
  }

  Widget _setRow(
    BuildContext context,
    AppLocalizations l,
    int i,
    WorkoutSet s,
    int? number,
    WorkoutSet? prev,
    bool hasPrev,
    SetField? active,
  ) {
    return SetRow(
      key: ValueKey(s.id),
      setId: s.id,
      label: l.setLabel(s.type, number),
      labelKind: setLabelKind(s.type),
      previousText: hasPrev ? l.setValueWithUnit(prev!, unit) : l.commonNoData,
      weightText: s.weightKg > 0 || s.completedAt != null ? setWeightNumber(s.weightKg, unit) : '',
      repsText: s.reps > 0 || s.completedAt != null ? '${s.reps}' : '',
      weightHint: hasPrev ? setWeightNumber(prev!.weightKg, unit) : l.commonNoData,
      repsHint: hasPrev ? '${prev!.reps}' : l.commonNoData,
      valuesMuted: s.prefilled,
      background: context.colors.pageBackground,
      completed: s.completedAt != null,
      isPr: detail.prs.containsKey(i),
      activeField: active,
      onLabelTap: () => actions.onLabelTap(s),
      onPreviousTap: hasPrev ? () => actions.onPreviousTap(s, prev!) : null,
      onWeightTap: () => actions.onFieldTap(detail, s, SetField.weight),
      onRepsTap: () => actions.onFieldTap(detail, s, SetField.reps),
      onToggleComplete: () => actions.onToggleComplete(detail, s, hasPrev ? prev : null),
      onDelete: () => actions.onDeleteSet(s),
      deleteLabel: l.commonSetDelete,
      completeLabel: l.commonSetComplete,
    );
  }
}

/// One-line notes under the exercise name; every edit is written at once.
/// Keeps its own text while focused so DB echoes never move the cursor.
class _NotesField extends StatefulWidget {
  const _NotesField({super.key, required this.initial, required this.hint, required this.onFocus, required this.onChanged});

  final String initial;
  final String hint;
  final VoidCallback onFocus;
  final ValueChanged<String> onChanged;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) widget.onFocus();
    });
  }

  @override
  void didUpdateWidget(_NotesField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.initial != _controller.text) _controller.text = widget.initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: _controller,
      focusNode: _focus,
      onChanged: widget.onChanged,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      style: AzmType.body.copyWith(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AzmType.body.copyWith(color: c.textTertiary),
        filled: false,
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsetsDirectional.symmetric(vertical: AzmSpace.xs),
      ),
    );
  }
}

class _UnknownAvatar extends StatelessWidget {
  const _UnknownAvatar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AzmSize.avatar,
      height: AzmSize.avatar,
      decoration: BoxDecoration(color: c.fill, shape: BoxShape.circle),
      child: Icon(Icons.help_outline_rounded, color: c.textTertiary, size: AzmSize.icon - AzmSpace.xxs),
    );
  }
}
