import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/lifted_counter.dart';
import '../../../core/widgets/rest_timer_bar.dart';
import '../../../core/widgets/set_row.dart';
import '../../../core/widgets/set_keypad.dart';
import '../../../core/widgets/set_undo.dart';
import '../../../core/widgets/workout_time_sheet.dart';
import '../../../core/widgets/weight_keypad.dart';
import '../data/rest_timer.dart';
import '../data/workout_models.dart';
import '../data/workout_repository.dart';
import 'workout_exercise_section.dart';
import 'workout_format.dart';
import '../../../core/widgets/set_type_sheet.dart';
import 'workout_sheets.dart';

/// Full-screen active workout (covers the tab bar). Route: AppRoutes.activeWorkout.
/// Everything shown comes from the DB (workoutDetailProvider); every edit is
/// written immediately, so killing the app loses nothing.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> implements WorkoutSetActions {
  /// Set + field on the keypad, its text buffer, and whether the next digit
  /// replaces the buffer (freshly selected field).
  ({String setId, SetField field})? _editing;
  final _keypad = SetKeypadBuffer();

  WorkoutDetail? _detail;
  bool _leaving = false;
  bool _checkingGone = false;
  final _rowKeys = <String, GlobalKey>{};

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);
  WeightUnit get _unit => _detail?.unit ?? WeightUnit.kg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final active = ref.watch(activeWorkoutProvider);
    final workout = active.value;

    if (workout == null) {
      if (!active.isLoading && !_leaving && !_checkingGone) {
        // Nothing to show (discarded elsewhere / stale route): go back. The
        // provider can still hold the null from BEFORE "Start workout" (the
        // DB stream hasn't re-emitted yet on a slow device), so confirm
        // with the DB before leaving.
        _checkingGone = true;
        unawaited(_leaveIfGone());
      }
      return const Scaffold(body: SizedBox.shrink());
    }

    final detail = ref.watch(workoutDetailProvider(workout.id)).value;
    _detail = detail;
    final rest = ref.watch(restTimerProvider);
    final editing = _editing;
    final editingSet = editing == null ? null : _findSet(editing.setId);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(
              workout: workout,
              restRunning: rest != null,
              onMinimize: _minimize,
              onEditStart: () => _editStart(workout),
              onTimer: _manualTimer,
              onFinish: _finish,
            ),
            _Stats(workout: workout, detail: detail),
            Expanded(
              child: detail == null
                  ? const SizedBox.shrink()
                  : ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AzmSpace.pageMargin,
                        AzmSpace.xl,
                        AzmSpace.pageMargin,
                        AzmSpace.xxxl,
                      ),
                      children: [
                        if (detail.exercises.isEmpty) _EmptyHint(text: l.workoutEmpty),
                        for (final e in detail.exercises)
                          WorkoutExerciseSection(
                            key: ValueKey(e.entry.id),
                            detail: e,
                            unit: detail.unit,
                            actions: this,
                            editing: editing,
                            rowKey: (id) => _rowKeys.putIfAbsent(id, GlobalKey.new),
                          ),
                        _WideButton(
                          label: l.workoutAddExercise,
                          icon: Icons.add_rounded,
                          onTap: () => _addExercises(workout.id),
                          primary: true,
                        ),
                        const SizedBox(height: AzmSpace.xs),
                        _WideButton(
                          label: l.workoutDiscard,
                          onTap: () => _discard(workout.id),
                          destructive: true,
                        ),
                      ],
                    ),
            ),
            if (rest != null)
              RestTimerBar(
                endsAt: rest.endsAt,
                totalSeconds: rest.totalSeconds,
                now: ref.read(workoutClockProvider),
                label: l.workoutRest,
                skipLabel: l.workoutRestSkip,
                lessLabel: l.workoutRestLess,
                moreLabel: l.workoutRestMore,
                adjustSeconds: kRestAdjustSeconds,
                onLess: () => ref.read(restTimerProvider.notifier).adjust(-kRestAdjustSeconds),
                onMore: () => ref.read(restTimerProvider.notifier).adjust(kRestAdjustSeconds),
                onSkip: () => ref.read(restTimerProvider.notifier).skip(),
              ),
            if (editing != null && editingSet != null)
              SetValueKeypad(
                field: editing.field,
                unit: _unit,
                buffer: _keypad.text,
                hasNext: _nextTarget() != null,
                onKey: _onKey,
              )
            else
              SizedBox(height: MediaQuery.paddingOf(context).bottom + (rest == null ? 0 : AzmSpace.xs)),
          ],
        ),
      ),
      backgroundColor: c.pageBackground,
    );
  }

  // ---- Navigation ----------------------------------------------------------

  Future<void> _leaveIfGone() async {
    final w = await _repo.active();
    _checkingGone = false;
    if (w != null || !mounted || _leaving) return;
    if (context.canPop()) context.pop();
  }

  void _minimize() {
    _closeKeypad();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.workout);
    }
  }

  Future<void> _addExercises(String workoutId) async {
    _closeKeypad();
    final ids = await context.push<List<String>>(AppRoutes.exercisePicker);
    if (ids == null || ids.isEmpty) return;
    await _repo.addExercises(workoutId, ids);
  }

  Future<void> _finish() async {
    final d = _detail;
    if (d == null) return;
    final l = context.l10n;
    final id = d.workout.id;
    _closeKeypad();
    final open = uncheckedSets(d);
    final unchecked = open.loggable.length + open.empty;

    Future<void> finish({List<SetCompletion> complete = const []}) =>
        _leave(() => _repo.finish(id, complete: complete), AppRoutes.workoutSummaryFor(id));
    Future<void> offerDiscard() async {
      final discard = await confirmDialog(
        context,
        title: l.workoutDiscardTitle,
        body: l.workoutFinishNothing,
        confirm: l.workoutDiscardConfirm,
        destructive: true,
      );
      if (discard) await _leave(() => _repo.discard(id), AppRoutes.workout);
    }

    if (d.completedSets == 0 && open.loggable.isEmpty) return offerDiscard();
    if (unchecked == 0) {
      final ok = await confirmDialog(context, title: l.workoutFinishTitle, body: l.workoutFinishAllDoneBody, confirm: l.workoutFinish);
      if (ok) await finish();
      return;
    }
    final choice = await showFinishUncheckedDialog(context, unchecked: unchecked, empty: open.empty);
    if (!mounted) return;
    switch (choice) {
      case FinishChoice.markAllDone:
        await finish(complete: open.loggable);
      case FinishChoice.removeThem:
        if (d.completedSets == 0) return offerDiscard(); // nothing would be left
        await finish();
      case null:
        return;
    }
  }

  Future<void> _discard(String workoutId) async {
    final l = context.l10n;
    _closeKeypad();
    final ok = await confirmDialog(
      context,
      title: l.workoutDiscardTitle,
      body: l.workoutDiscardBody,
      confirm: l.workoutDiscardConfirm,
      destructive: true,
    );
    if (ok) await _leave(() => _repo.discard(workoutId), AppRoutes.workout);
  }

  Future<void> _leave(Future<void> Function() change, String location) async {
    setState(() => _leaving = true);
    hideSetDeletedSnackBar(context);
    await ref.read(restTimerProvider.notifier).skip();
    await change();
    if (mounted) context.go(location);
  }

  // ---- Set actions -----------------------------------------------------------

  WorkoutSet? _findSet(String id) {
    for (final s in _detail?.allSets ?? const <WorkoutSet>[]) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> onLabelTap(WorkoutSet set) async {
    final type = await showSetTypeSheet(context, set.type);
    if (type != null && type != set.type) await _repo.updateSet(set.id, type: type);
  }

  @override
  void onPreviousTap(WorkoutSet set, WorkoutSet previous) {
    unawaited(_repo.updateSet(set.id, weightKg: previous.weightKg, reps: previous.reps));
    final e = _editing;
    if (e?.setId == set.id) {
      setState(() => _keypad.load(e!.field == SetField.weight ? setWeightInput(previous.weightKg, _unit) : '${previous.reps}'));
    }
  }

  @override
  void onFieldTap(WorkoutExerciseDetail exercise, WorkoutSet set, SetField field) => _edit(set, field);

  void _edit(WorkoutSet set, SetField field) {
    setState(() {
      _editing = (setId: set.id, field: field);
      _keypad.load(_inputText(set, field));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[set.id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: AzmMotion.of(context, AzmMotion.sheetDuration),
          curve: AzmMotion.sheet,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  String _inputText(WorkoutSet s, SetField f) => f == SetField.weight
      ? (s.weightKg > 0 ? setWeightInput(s.weightKg, _unit) : '')
      : (s.reps > 0 ? '${s.reps}' : '');

  @override
  Future<void> onToggleComplete(WorkoutExerciseDetail exercise, WorkoutSet set, WorkoutSet? previous) async {
    if (set.completedAt != null) {
      await _repo.setCompleted(set.id, false);
      return;
    }
    final (:weightKg, :reps) = completionValues(set, previous);
    if (reps <= 0) {
      // Nothing to log yet: open the keypad on reps instead.
      unawaited(HapticFeedback.selectionClick());
      _edit(set, SetField.reps);
      return;
    }
    if (_editing?.setId == set.id) _closeKeypad();
    unawaited(HapticFeedback.lightImpact());
    await _repo.setCompleted(set.id, true, weightKg: weightKg, reps: reps);
    if (exercise.restOff) return; // "Rest Timer: OFF" for this exercise
    final rest = ref.read(restTimerProvider.notifier);
    await rest.start(exercise.restSeconds);
    await _maybeExplainExactAlarms(rest);
  }

  /// Android 14+: once ever, on the first rest timer, explain why exact
  /// alarms matter and offer the system screen. Declining keeps the inexact
  /// fallback; it is never asked again automatically.
  Future<void> _maybeExplainExactAlarms(RestTimerController rest) async {
    if (!await rest.shouldExplainExactAlarms() || !mounted) return;
    await rest.markExactAlarmsExplained();
    if (!mounted) return;
    if (await showExactAlarmSheet(context)) await rest.requestExactAlarms();
  }

  /// Swipe or long-press → "Delete set": gone from the DB at once (the
  /// remaining sets renumber and Lifted/sets/PRs recompute from the stream),
  /// with ~4 s to undo. Works for any set, ✓ or not, including the last one
  /// of an exercise (the exercise stays, with "Add set").
  @override
  void onDeleteSet(WorkoutSet set) {
    if (_editing?.setId == set.id) _closeKeypad();
    unawaited(_repo.deleteSet(set.id));
    showSetDeletedSnackBar(context, onUndo: () => _repo.restoreSet(set, status: WorkoutStatus.active));
  }

  @override
  void onAddSet(WorkoutExerciseDetail exercise) => unawaited(_repo.addSet(exercise.entry.id));

  @override
  Future<void> onExerciseMenu(WorkoutExerciseDetail exercise, String name) async {
    _closeKeypad();
    final action = await showExerciseMenu(context, name);
    if (!mounted || action == null) return;
    switch (action) {
      case ExerciseMenuAction.remove:
        await _repo.removeExercise(exercise.entry.id);
      case ExerciseMenuAction.reorder:
        final d = _detail;
        if (d == null) return;
        await showReorderSheet(
          context,
          items: [for (final e in d.exercises) (id: e.entry.id, name: namesFor(context, e.exercise, e.entry.exerciseId).primary)],
          onReorder: (ids) => unawaited(_repo.reorderExercises(ids)),
        );
    }
  }

  @override
  void onNotesChanged(WorkoutExerciseDetail exercise, String notes) =>
      unawaited(_repo.setExerciseNotes(exercise.entry.id, notes));

  @override
  void onNotesFocus() => _closeKeypad();

  @override
  Future<void> onRestTap(WorkoutExerciseDetail exercise, String name) async {
    _closeKeypad();
    final choice = await showExerciseRestSheet(
      context,
      exerciseName: name,
      current: exercise.restIsOverride ? exercise.restSeconds : null,
      defaultSeconds: exercise.defaultRestSeconds,
    );
    if (choice != null) await _repo.setExerciseRest(exercise.entry.id, choice.seconds);
  }

  // ---- Top bar ---------------------------------------------------------------

  /// Tap on the elapsed time: move the start back (forgot to open the app on
  /// time). The duration follows from the DB; the rest timer is untouched.
  Future<void> _editStart(Workout workout) async {
    _closeKeypad();
    FocusScope.of(context).unfocus();
    final start = await showWorkoutStartSheet(
      context,
      start: workout.startedAt,
      now: ref.read(workoutClockProvider),
      hint: context.l10n.workoutStartTimeHint,
    );
    if (start != null) await _repo.setStartedAt(workout.id, start);
  }

  /// ⏱ in the top bar: start a manual rest countdown (or skip the running one).
  Future<void> _manualTimer() async {
    _closeKeypad();
    FocusScope.of(context).unfocus();
    final running = ref.read(restTimerProvider);
    final seconds = await showManualRestSheet(
      context,
      runningEndsAt: running?.endsAt,
      now: ref.read(workoutClockProvider),
    );
    if (seconds == null || !mounted) return;
    final rest = ref.read(restTimerProvider.notifier);
    if (seconds <= 0) return rest.skip();
    await rest.start(seconds);
    await _maybeExplainExactAlarms(rest);
  }

  // ---- Keypad ----------------------------------------------------------------

  void _closeKeypad() {
    if (_editing != null && mounted) setState(() => _editing = null);
  }

  void _onKey(KeypadKey key) {
    final e = _editing;
    final set = e == null ? null : _findSet(e.setId);
    if (e == null || set == null) return _closeKeypad();
    final weight = e.field == SetField.weight;
    switch (key) {
      case KeypadHide():
        _closeKeypad();
      case KeypadNext():
        final next = _nextTarget();
        if (next == null) {
          _closeKeypad();
        } else {
          _edit(next.set, next.field);
        }
      default:
        final v = _keypad.apply(key, e.field, _unit);
        setState(() {});
        unawaited(weight ? _repo.updateSet(set.id, weightKg: v ?? 0) : _repo.updateSet(set.id, reps: (v ?? 0).toInt()));
    }
  }

  /// Next field in reading order: weight → reps, then the next set without ✓.
  ({WorkoutSet set, SetField field})? _nextTarget() {
    final e = _editing;
    final d = _detail;
    if (e == null || d == null) return null;
    final order = <({WorkoutSet set, SetField field})>[
      for (final s in d.allSets) ...[(set: s, field: SetField.weight), (set: s, field: SetField.reps)],
    ];
    final i = order.indexWhere((t) => t.set.id == e.setId && t.field == e.field);
    if (i < 0) return null;
    for (var j = i + 1; j < order.length; j++) {
      if (order[j].set.completedAt == null) return order[j];
    }
    return null;
  }
}

/// Top bar (card colour up to the status bar): minimize ⌄, live elapsed time
/// (tap → change the start time), ⏱ manual rest timer, accent "Finish".
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.workout,
    required this.restRunning,
    required this.onMinimize,
    required this.onEditStart,
    required this.onTimer,
    required this.onFinish,
  });

  final Workout workout;
  final bool restRunning;
  final VoidCallback onMinimize;
  final VoidCallback onEditStart;
  final VoidCallback onTimer;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    return ColoredBox(
      color: c.card,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxs, AzmSpace.xxs, AzmSpace.pageMargin, AzmSpace.xxs),
          child: Row(
            children: [
              AzmPressable(
                key: const ValueKey('workoutMinimize'),
                onTap: onMinimize,
                semanticLabel: l.workoutMinimize,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: c.textPrimary, size: AzmSize.icon + AzmSpace.xxs),
              ),
              AzmTicker(
                period: const Duration(seconds: 1),
                now: ref.read(workoutClockProvider),
                builder: (_, now) {
                  final elapsed = formatClock(now.difference(workout.startedAt));
                  return AzmPressable(
                    key: const ValueKey('workoutElapsed'),
                    onTap: onEditStart,
                    semanticLabel: l.workoutElapsedEdit(elapsed),
                    child: ExcludeSemantics(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxs),
                          child: Text(elapsed, style: AzmType.rowNumberCompact.copyWith(color: c.accent)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              AzmPressable(
                key: const ValueKey('workoutTimerButton'),
                onTap: onTimer,
                semanticLabel: l.workoutTimerTitle,
                selected: restRunning,
                child: Icon(Icons.timer_outlined, color: restRunning ? c.accent : c.textPrimary, size: AzmSize.icon),
              ),
              const SizedBox(width: AzmSpace.xs),
              AzmPressable(
                key: const ValueKey('workoutFinish'),
                onTap: onFinish,
                semanticLabel: l.workoutFinish,
                child: Center(
                  child: Container(
                    height: AzmSize.setBox,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xl),
                    alignment: AlignmentDirectional.center,
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AzmRadius.segment)),
                    child: ExcludeSemantics(
                      child: Text(l.workoutFinish, style: AzmType.pillLabel.copyWith(color: c.onAccent)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Duration | Lifted (شِلت) | Sets: small labels above the values, then a
/// divider. (A muscle/body diagram is a later idea, docs/PLAN.md.)
class _Stats extends ConsumerWidget {
  const _Stats({required this.workout, required this.detail});

  final Workout workout;
  final WorkoutDetail? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final d = detail;
    final unit = d?.unit ?? WeightUnit.kg;
    final valueStyle = AzmType.rowNumber.copyWith(color: c.textPrimary);

    Widget stat(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AzmType.small.copyWith(color: c.textSecondary)),
              const SizedBox(height: AzmSpace.opticalInset),
              value,
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.md, AzmSpace.pageMargin, AzmSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat(
                l.workoutStatDuration,
                AzmTicker(
                  period: const Duration(seconds: 1),
                  now: ref.read(workoutClockProvider),
                  builder: (_, now) => Text(
                    formatClock(now.difference(workout.startedAt)),
                    style: valueStyle.copyWith(color: c.accent),
                  ),
                ),
              ),
              stat(
                l.workoutStatLifted,
                LiftedCounter(value: Units.toDisplay(d?.liftedTotalKg ?? 0, unit), unit: l.weightUnitLabel(unit)),
              ),
              stat(l.workoutStatSets, Text('${d?.completedSets ?? 0}', style: valueStyle)),
            ],
          ),
        ),
        Divider(height: 1, thickness: AzmSize.outline, color: c.divider),
      ],
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = primary ? c.accent : (destructive ? c.destructiveText : c.textPrimary);
    final bg = primary ? c.accentSoft : (destructive ? c.destructiveTint : c.fill);
    return AzmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.buttonCompact,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AzmRadius.input)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: fg, size: AzmSize.icon), const SizedBox(width: AzmSpace.xs)],
              Flexible(child: Text(label, style: AzmType.button.copyWith(color: fg), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AzmSpace.xxxl),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: AzmSize.minTouchTarget, color: c.textNoData),
          const SizedBox(height: AzmSpace.md),
          Text(text, textAlign: TextAlign.center, style: AzmType.secondary.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
