import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/lifted_counter.dart';
import '../../../core/widgets/rest_timer_bar.dart';
import '../../../core/widgets/set_row.dart';
import '../../../core/widgets/weight_keypad.dart';
import '../data/rest_timer.dart';
import '../data/workout_models.dart';
import '../data/workout_repository.dart';
import '../debug/debug_seed.dart';
import 'workout_exercise_section.dart';
import 'workout_format.dart';
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
  String _buffer = '';
  bool _fresh = true;

  WorkoutDetail? _detail;
  bool _leaving = false;
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
      if (!active.isLoading && !_leaving) {
        // Nothing to show (discarded elsewhere / stale route): go back.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.canPop()) context.pop();
        });
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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              name: workout.name,
              onMinimize: _minimize,
              onFinish: _finish,
            ),
            _Stats(workout: workout, detail: detail),
            Expanded(
              child: detail == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AzmSpace.pageMargin,
                        AzmSpace.md,
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
                        // DEBUG ONLY — remove at merge (see debug/debug_seed.dart).
                        if (kDebugMode) ...[
                          const SizedBox(height: AzmSpace.xs),
                          _WideButton(
                            label: l.workoutDebugSeed,
                            icon: Icons.bug_report_outlined,
                            onTap: () => debugSeedExercises(_repo, workout.id),
                          ),
                        ],
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
              WeightKeypad(
                title: editing.field == SetField.weight
                    ? l.workoutKeypadWeight(l.unitLabel(_unit))
                    : l.workoutColReps,
                valueText: _buffer.isEmpty ? l.workoutNoData : _buffer,
                allowDecimal: editing.field == SetField.weight,
                stepText: editing.field == SetField.weight ? AzmNumbers.decimal(Units.keypadStep) : '1',
                nextLabel: _nextTarget() == null ? l.workoutDone : l.workoutKeypadNext,
                backspaceLabel: l.workoutKeypadBackspace,
                hideLabel: l.workoutKeypadHide,
                decreaseLabel: l.workoutKeypadDecrease,
                increaseLabel: l.workoutKeypadIncrease,
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
    _closeKeypad();
    if (d.completedSets == 0) {
      final discard = await confirmDialog(
        context,
        title: l.workoutDiscardTitle,
        body: l.workoutFinishNothing,
        confirm: l.workoutDiscardConfirm,
        destructive: true,
      );
      if (discard) await _leave(() => _repo.discard(d.workout.id), AppRoutes.workout);
      return;
    }
    final ok = await confirmDialog(context, title: l.workoutFinishTitle, body: l.workoutFinishBody, confirm: l.workoutFinish);
    if (ok) await _leave(() => _repo.finish(d.workout.id), AppRoutes.workoutSummaryFor(d.workout.id));
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
      setState(() {
        _buffer = e!.field == SetField.weight ? weightInputText(previous.weightKg, _unit) : '${previous.reps}';
        _fresh = true;
      });
    }
  }

  @override
  void onFieldTap(WorkoutExerciseDetail exercise, WorkoutSet set, SetField field) => _edit(set, field);

  void _edit(WorkoutSet set, SetField field) {
    setState(() {
      _editing = (setId: set.id, field: field);
      _buffer = _inputText(set, field);
      _fresh = true;
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
      ? (s.weightKg > 0 ? weightInputText(s.weightKg, _unit) : '')
      : (s.reps > 0 ? '${s.reps}' : '');

  @override
  Future<void> onToggleComplete(WorkoutExerciseDetail exercise, WorkoutSet set, WorkoutSet? previous) async {
    if (set.completedAt != null) {
      await _repo.setCompleted(set.id, false);
      return;
    }
    var weight = set.weightKg;
    var reps = set.reps;
    if (reps <= 0 && previous != null) {
      reps = previous.reps;
      if (weight <= 0) weight = previous.weightKg;
    }
    if (reps <= 0) {
      // Nothing to log yet: open the keypad on reps instead.
      unawaited(HapticFeedback.selectionClick());
      _edit(set, SetField.reps);
      return;
    }
    if (_editing?.setId == set.id) _closeKeypad();
    unawaited(HapticFeedback.lightImpact());
    await _repo.setCompleted(set.id, true, weightKg: weight, reps: reps);
    await ref.read(restTimerProvider.notifier).start(exercise.restSeconds);
  }

  @override
  void onDeleteSet(WorkoutSet set) {
    if (_editing?.setId == set.id) _closeKeypad();
    unawaited(_repo.deleteSet(set.id));
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
      case KeypadStep(:final up):
        if (weight) {
          final kg = Units.stepKg(Units.fromDisplay(double.tryParse(_buffer) ?? 0, _unit), _unit, up: up);
          unawaited(_repo.updateSet(set.id, weightKg: kg));
          setState(() {
            _buffer = kg > 0 ? weightInputText(kg, _unit) : '';
            _fresh = true;
          });
        } else {
          final reps = ((int.tryParse(_buffer) ?? 0) + (up ? 1 : -1)).clamp(0, 999);
          unawaited(_repo.updateSet(set.id, reps: reps));
          setState(() {
            _buffer = reps > 0 ? '$reps' : '';
            _fresh = true;
          });
        }
      default:
        final r = applyKeypadKey(_buffer, _fresh, key, allowDecimal: weight, maxIntegerDigits: weight ? 4 : 3);
        setState(() {
          _buffer = r.buffer;
          _fresh = r.fresh;
        });
        if (weight) {
          unawaited(_repo.updateSet(set.id, weightKg: Units.fromDisplay(double.tryParse(r.buffer) ?? 0, _unit)));
        } else {
          unawaited(_repo.updateSet(set.id, reps: int.tryParse(r.buffer) ?? 0));
        }
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

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onMinimize, required this.onFinish});

  final String name;
  final VoidCallback onMinimize;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xs, AzmSpace.xs, AzmSpace.pageMargin, AzmSpace.xxs),
      child: Row(
        children: [
          AzmHeaderButton(icon: Icons.keyboard_arrow_down_rounded, semanticLabel: l.workoutMinimize, onTap: onMinimize),
          const SizedBox(width: AzmSpace.xxs),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AzmType.screenTitle.copyWith(color: c.textPrimary),
              ),
            ),
          ),
          AzmPressable(
            onTap: onFinish,
            semanticLabel: l.workoutFinish,
            child: Center(
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xl, vertical: AzmSpace.xs),
                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AzmRadius.pill)),
                child: ExcludeSemantics(
                  child: Text(l.workoutFinish, style: AzmType.pillLabel.copyWith(color: c.onAccent)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// duration | Lifted | sets.
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
            children: [
              Text(label, style: AzmType.statLabel.copyWith(color: c.textSecondary)),
              const SizedBox(height: AzmSpace.opticalInset),
              value,
            ],
          ),
        );
    Widget divider() => const SizedBox(height: AzmSize.headerButton, child: VerticalDivider());

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin, vertical: AzmSpace.xs),
      child: Row(
        children: [
          stat(
            l.workoutStatDuration,
            AzmTicker(
              period: const Duration(seconds: 1),
              now: ref.read(workoutClockProvider),
              builder: (_, now) => Text(formatClock(now.difference(workout.startedAt)), style: valueStyle),
            ),
          ),
          divider(),
          stat(
            l.workoutStatLifted,
            LiftedCounter(value: Units.toDisplay(d?.liftedTotalKg ?? 0, unit), unit: l.unitLabel(unit)),
          ),
          divider(),
          stat(l.workoutStatSets, Text('${d?.completedSets ?? 0}', style: valueStyle)),
        ],
      ),
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
          height: AzmSize.input,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AzmRadius.button)),
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
