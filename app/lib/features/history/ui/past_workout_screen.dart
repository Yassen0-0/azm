import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/set_row.dart';
import '../../../core/widgets/set_keypad.dart';
import '../../../core/widgets/set_undo.dart';
import '../../../core/widgets/set_type_sheet.dart';
import '../../../core/widgets/weight_keypad.dart';
import '../../../core/widgets/workout_time_sheet.dart';
import '../../workout/data/workout_models.dart';
import '../../workout/data/workout_repository.dart';
import '../data/history_repository.dart';
import 'history_sheets.dart';
import 'history_text.dart';
import 'history_widgets.dart';
import 'past_exercise_section.dart';

/// Past (finished) workout detail, editable. Route: AppRoutes.pastWorkoutFor(id).
///
/// Same set table as the live workout (SetRow + SetValueKeypad) without the
/// ✓: every set of a finished workout is done. Weights, reps, types, add
/// sets, add/remove exercises, rename, delete; a set is deleted by the user
/// only (swipe or long-press menu, with Undo), never behind their back.
/// Every edit is written at once; Lifted, PRs and records everywhere recompute from the DB streams
/// (PRs chronologically, so later workouts can change too).
class PastWorkoutScreen extends ConsumerStatefulWidget {
  const PastWorkoutScreen({super.key, required this.workoutId});

  final String workoutId;

  /// Keys for tests / screenshots.
  static const menuKey = ValueKey('pastWorkoutMenu');

  @override
  ConsumerState<PastWorkoutScreen> createState() => _PastWorkoutScreenState();
}

class _PastWorkoutScreenState extends ConsumerState<PastWorkoutScreen> implements PastSetActions {
  ({String setId, SetField field})? _editing;
  final _keypad = SetKeypadBuffer();
  bool _leaving = false;

  WorkoutDetail? _detail;
  final _rowKeys = <String, GlobalKey>{};

  late final WorkoutRepository _sets = ref.read(workoutRepositoryProvider);
  /// Captured up front: dispose() can't use `ref` any more. Null without a
  /// database (widget tests of the router).
  HistoryRepository? _historyOrNull;
  HistoryRepository get _history => _historyOrNull!;

  WeightUnit get _unit => _detail?.unit ?? WeightUnit.kg;

  @override
  void initState() {
    super.initState();
    try {
      _historyOrNull = ref.read(historyRepositoryProvider);
    } on Object {
      _historyOrNull = null;
    }
    // Sets left without ✓ (app killed right after adding an exercise) are
    // logged, never removed.
    unawaited(_historyOrNull?.logUnticked(widget.workoutId).catchError((Object _) => const <String>[]));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final async = ref.watch(pastWorkoutDetailProvider(widget.workoutId));
    final d = async.value;
    final finished = d != null && d.workout.status == WorkoutStatus.finished;
    _detail = finished ? d : null;
    final editing = _editing;
    final editingSet = editing == null ? null : _findSet(editing.setId);

    return Scaffold(
      backgroundColor: c.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              name: finished ? d.workout.name : '',
              onBack: () => context.pop(),
              onMenu: finished ? () => _menu(d.workout) : null,
            ),
            Expanded(
              child: !finished
                  ? (async.isLoading || _leaving
                      ? const SizedBox.shrink()
                      : HistoryEmpty(icon: Icons.search_off_rounded, title: l.historyNotFound))
                  : ListView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AzmSpace.pageMargin,
                        0,
                        AzmSpace.pageMargin,
                        AzmSpace.xxxl,
                      ),
                      children: [
                        Text(
                          '${HistoryDates.full(context, d.workout.startedAt)} · ${HistoryDates.time(context, d.workout.startedAt)}',
                          style: AzmType.secondary.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: AzmSpace.md),
                        _Stats(detail: d),
                        const SizedBox(height: AzmSpace.md),
                        Text(l.historyEditHint, style: AzmType.small.copyWith(color: c.textTertiary)),
                        const SizedBox(height: AzmSpace.md),
                        for (final e in d.exercises)
                          PastExerciseSection(
                            key: ValueKey(e.entry.id),
                            detail: e,
                            unit: d.unit,
                            actions: this,
                            editing: editing,
                            rowKey: (id) => _rowKeys.putIfAbsent(id, GlobalKey.new),
                          ),
                        HistoryWideButton(
                          label: l.historyAddExercise,
                          icon: Icons.add_rounded,
                          primary: true,
                          onTap: _addExercises,
                        ),
                        const SizedBox(height: AzmSpace.xs),
                        HistoryWideButton(label: l.historyDeleteWorkout, destructive: true, onTap: _delete),
                      ],
                    ),
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
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  // ---- Workout actions -------------------------------------------------------

  Future<void> _menu(Workout w) async {
    final l = context.l10n;
    _closeKeypad();
    final action = await showHistorySheet<String>(
      context,
      title: isolate(w.name),
      children: (ctx) => [
        HistorySheetAction(label: l.historyRename, icon: Icons.edit_outlined, onTap: () => Navigator.pop(ctx, 'rename')),
        if (w.endedAt != null)
          HistorySheetAction(
            key: const ValueKey('pastWorkoutEditTime'),
            label: l.historyEditTime,
            icon: Icons.schedule_rounded,
            onTap: () => Navigator.pop(ctx, 'time'),
          ),
        HistorySheetAction(
          label: l.historyDeleteWorkout,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onTap: () => Navigator.pop(ctx, 'delete'),
        ),
      ],
    );
    if (!mounted) return;
    if (action == 'rename') {
      final name = await showRenameDialog(context, w.name);
      if (name != null) await _history.rename(w.id, name);
    } else if (action == 'time') {
      // Start + end (end after start, nothing in the future). History, stats
      // and PRs re-read the DB, so they follow.
      final r = await showWorkoutTimesSheet(context, start: w.startedAt, end: w.endedAt!, now: ref.read(workoutClockProvider));
      if (r != null) await ref.read(workoutRepositoryProvider).setTimes(w.id, start: r.start, end: r.end);
    } else if (action == 'delete') {
      await _delete();
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    _closeKeypad();
    final ok = await historyConfirm(
      context,
      title: l.historyDeleteTitle,
      body: l.historyDeleteBody,
      confirm: l.historyDeleteConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _leaving = true);
    await _history.delete(widget.workoutId);
    if (mounted) context.pop();
  }

  Future<void> _addExercises() async {
    _closeKeypad();
    final ids = await context.push<List<String>>(AppRoutes.exercisePicker);
    if (ids == null || ids.isEmpty || !mounted) return;
    final before = {for (final e in _detail?.exercises ?? const <WorkoutExerciseDetail>[]) e.entry.id};
    await _sets.addExercises(widget.workoutId, ids);
    // New sets are logged at once (values from the workout before, if any),
    // then the keypad opens on the first one.
    await _history.logUnticked(widget.workoutId);
    final d = await _sets.loadDetail(widget.workoutId);
    if (!mounted || d == null) return;
    for (final e in d.exercises) {
      if (!before.contains(e.entry.id) && e.sets.isNotEmpty) {
        _detail = d;
        _edit(e.sets.first, SetField.weight);
        return;
      }
    }
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
    if (type != null && type != set.type) await _sets.updateSet(set.id, type: type);
  }

  @override
  void onPreviousTap(WorkoutSet set, WorkoutSet previous) {
    unawaited(_sets.updateSet(set.id, weightKg: previous.weightKg, reps: previous.reps));
    final e = _editing;
    if (e?.setId == set.id) {
      setState(() => _keypad.load(e!.field == SetField.weight ? setWeightInput(previous.weightKg, _unit) : '${previous.reps}'));
    }
  }

  @override
  void onFieldTap(WorkoutSet set, SetField field) => _edit(set, field);

  void _edit(WorkoutSet set, SetField field) {
    setState(() {
      _editing = (setId: set.id, field: field);
      _keypad.load(field == SetField.weight
          ? (set.weightKg > 0 ? setWeightInput(set.weightKg, _unit) : '')
          : (set.reps > 0 ? '${set.reps}' : ''));
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

  @override
  void onDeleteSet(WorkoutSet set) {
    if (_editing?.setId == set.id) _closeKeypad();
    unawaited(_sets.deleteSet(set.id));
    showSetDeletedSnackBar(context, onUndo: () => _sets.restoreSet(set, status: WorkoutStatus.finished));
  }

  @override
  void onAddSet(WorkoutExerciseDetail exercise) {
    final w = _detail?.workout;
    if (w == null) return;
    unawaited(_history.addLoggedSet(exercise.entry.id, w.endedAt ?? w.startedAt));
  }

  @override
  Future<void> onExerciseMenu(WorkoutExerciseDetail exercise, String name) async {
    final l = context.l10n;
    _closeKeypad();
    final remove = await showHistorySheet<bool>(
      context,
      title: isolate(name),
      children: (ctx) => [
        HistorySheetAction(
          label: l.historyRemoveExercise,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onTap: () => Navigator.pop(ctx, true),
        ),
      ],
    );
    if (remove == true) await _sets.removeExercise(exercise.entry.id);
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
        unawaited(weight ? _sets.updateSet(set.id, weightKg: v ?? 0) : _sets.updateSet(set.id, reps: (v ?? 0).toInt()));
    }
  }

  /// Next field in reading order: weight → reps → next set's weight …
  ({WorkoutSet set, SetField field})? _nextTarget() {
    final e = _editing;
    final d = _detail;
    if (e == null || d == null) return null;
    final order = <({WorkoutSet set, SetField field})>[
      for (final s in d.allSets) ...[(set: s, field: SetField.weight), (set: s, field: SetField.reps)],
    ];
    final i = order.indexWhere((t) => t.set.id == e.setId && t.field == e.field);
    return i < 0 || i + 1 >= order.length ? null : order[i + 1];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onBack, required this.onMenu});

  final String name;
  final VoidCallback onBack;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xs, AzmSpace.xs, AzmSpace.xs, AzmSpace.xs),
      child: Row(
        children: [
          // arrow_back mirrors automatically in RTL.
          AzmHeaderButton(icon: Icons.arrow_back_rounded, semanticLabel: l.commonBack, onTap: onBack),
          const SizedBox(width: AzmSpace.xxs),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                isolate(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AzmType.screenTitle.copyWith(color: c.textPrimary),
              ),
            ),
          ),
          if (onMenu != null)
            AzmHeaderButton(
              key: PastWorkoutScreen.menuKey,
              icon: Icons.more_horiz_rounded,
              semanticLabel: l.historyWorkoutOptions,
              onTap: onMenu!,
            ),
        ],
      ),
    );
  }
}

/// Duration | Lifted | sets | PRs of the (edited) workout.
class _Stats extends StatelessWidget {
  const _Stats({required this.detail});

  final WorkoutDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final w = detail.workout;
    final prSets = detail.exercises.fold(0, (n, e) => n + e.prs.length);
    return HistoryCard(
      child: Row(
        children: [
          HistoryStat(
            label: l.historyStatDuration,
            value: w.endedAt == null ? l.historyNoData : l.duration(w.endedAt!.difference(w.startedAt)),
          ),
          HistoryStat(label: l.historyStatLifted, value: l.weight(detail.liftedTotalKg, detail.unit)),
          HistoryStat(label: l.historyStatSets, value: AzmNumbers.integer(detail.completedSets)),
          HistoryStat(
            label: l.historyStatPrs,
            value: AzmNumbers.integer(prSets),
            valueColor: prSets > 0 ? c.pr : null,
          ),
        ],
      ),
    );
  }
}
