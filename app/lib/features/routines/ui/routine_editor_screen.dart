import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/set_keypad.dart';
import '../../../core/widgets/set_row.dart';
import '../../../core/widgets/set_type_sheet.dart';
import '../../../core/widgets/set_undo.dart';
import '../../../core/widgets/weight_keypad.dart';
import '../../settings/data/training_settings.dart';
import '../data/routine_repository.dart';
import 'routines_widgets.dart';

/// Routine editor. Route: AppRoutes.routineNew (routineId == null → new
/// routine) or AppRoutes.routineEditorFor(id). Every edit is written to the
/// DB immediately; the screen only renders what routineDetailProvider emits.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, this.routineId});

  /// Routine to edit, or null for a new one.
  final String? routineId;

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  String? _id;
  RoutineRepository? _repo;
  final _name = TextEditingController();
  final _notes = TextEditingController();
  bool _textLoaded = false;
  bool _leaving = false;

  /// Set + field on the keypad, its buffer, and whether the next digit
  /// replaces it (freshly selected field).
  ({String setId, SetField field})? _editing;
  final _keypad = SetKeypadBuffer();

  RoutineDetail? _detail;
  final _rowKeys = <String, GlobalKey>{};

  bool get _isNew => widget.routineId == null;

  @override
  void initState() {
    super.initState();
    _id = widget.routineId;
    if (_isNew) unawaited(_createRoutine());
  }

  Future<void> _createRoutine() async {
    try {
      final repo = ref.read(routineRepositoryProvider);
      final id = await repo.create();
      if (!mounted) {
        await repo.delete(id);
        return;
      }
      setState(() {
        _repo = repo;
        _id = id;
      });
    } on Object {
      // No database (widget tests of the router): stay an empty editor.
    }
  }

  @override
  void dispose() {
    // A "New routine" left untouched leaves nothing behind.
    final repo = _repo, id = _id;
    if (_isNew && repo != null && id != null && !_leaving) {
      unawaited(repo.isBlank(id).then((blank) => blank ? repo.delete(id) : null));
    }
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  RoutineRepository get _r => (_repo ??= ref.read(routineRepositoryProvider))!;

  WeightUnit get _unit => ref.read(weightUnitProvider).value ?? WeightUnit.kg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final id = _id;
    final detail = id == null ? null : ref.watch(routineDetailProvider(id)).value;
    _detail = detail;
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;
    final defaultRest = ref.watch(defaultRestSecondsProvider).value ?? kDefaultRestSeconds;
    if (detail != null && !_textLoaded) {
      _textLoaded = true;
      _name.text = detail.routine.name;
      _notes.text = detail.routine.notes ?? '';
    }
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
              title: _isNew ? l.routinesNew : l.routinesEditTitle,
              onBack: () => context.pop(),
              onStart: detail == null || detail.exercises.isEmpty ? null : _start,
            ),
            Expanded(
              child: detail == null
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: ListView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AzmSpace.pageMargin,
                          AzmSpace.xs,
                          AzmSpace.pageMargin,
                          AzmSpace.xxxl,
                        ),
                        children: [
                          TextField(
                            key: const ValueKey('routineName'),
                            controller: _name,
                            onTap: _closeKeypad,
                            onChanged: (v) => unawaited(_r.rename(detail.routine.id, v)),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            style: AzmType.cardTitle.copyWith(color: c.textPrimary),
                            decoration: InputDecoration(hintText: l.routinesNameHint),
                          ),
                          const SizedBox(height: AzmSpace.xs),
                          TextField(
                            key: const ValueKey('routineNotes'),
                            controller: _notes,
                            onTap: _closeKeypad,
                            onChanged: (v) => unawaited(_r.setNotes(detail.routine.id, v)),
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            style: AzmType.body.copyWith(color: c.textPrimary),
                            decoration: InputDecoration(hintText: l.routinesNotesHint),
                          ),
                          const SizedBox(height: AzmSpace.xxl),
                          if (detail.exercises.isEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(bottom: AzmSpace.xl),
                              child: Text(
                                l.routinesEditorEmpty,
                                textAlign: TextAlign.center,
                                style: AzmType.secondary.copyWith(color: c.textSecondary),
                              ),
                            ),
                          for (final e in detail.exercises)
                            _ExerciseCard(
                              key: ValueKey(e.entry.id),
                              detail: e,
                              unit: unit,
                              defaultRest: defaultRest,
                              editing: editing,
                              rowKey: (id) => _rowKeys.putIfAbsent(id, GlobalKey.new),
                              onMenu: (name) => _exerciseMenu(e, name, defaultRest),
                              onRest: () => _pickRest(e, defaultRest),
                              onLabelTap: _pickType,
                              onField: _edit,
                              onDeleteSet: _deleteSet,
                              onAddSet: () => unawaited(_r.addSet(e.entry.id)),
                            ),
                          RoutinesWideButton(
                            key: const ValueKey('routineAddExercises'),
                            label: l.routinesAddExercises,
                            icon: Icons.add_rounded,
                            primary: detail.exercises.isEmpty,
                            onTap: () => _addExercises(detail.routine.id),
                          ),
                          const SizedBox(height: AzmSpace.xs),
                          RoutinesWideButton(
                            key: const ValueKey('routineDelete'),
                            label: l.routinesDelete,
                            destructive: true,
                            onTap: () => _delete(detail.routine.id),
                          ),
                        ],
                      ),
                    ),
            ),
            if (editing != null && editingSet != null)
              SetValueKeypad(
                field: editing.field,
                unit: unit,
                buffer: _keypad.text,
                hasNext: _nextTarget() != null,
                onKey: _onKey,
                weightTitle: l.routinesKeypadWeight(l.weightUnitLabel(unit)),
                repsTitle: l.routinesKeypadReps,
              )
            else
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  // ---- Routine actions ---------------------------------------------------------

  Future<void> _start() async {
    final id = _id;
    if (id == null) return;
    _closeKeypad();
    final l = context.l10n;
    final result = await _r.start(id, fallbackName: l.routinesUntitled);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    context.pushReplacement(AppRoutes.activeWorkout);
    if (result.resumed) messenger?.showSnackBar(SnackBar(content: Text(l.routinesResumed)));
  }

  Future<void> _addExercises(String routineId) async {
    _closeKeypad();
    FocusScope.of(context).unfocus();
    final ids = await context.push<List<String>>(AppRoutes.exercisePicker);
    if (ids == null || ids.isEmpty) return;
    await _r.addExercises(routineId, ids);
  }

  Future<void> _delete(String routineId) async {
    final l = context.l10n;
    _closeKeypad();
    final ok = await routinesConfirm(
      context,
      title: l.routinesDeleteTitle,
      body: l.routinesDeleteBody,
      confirm: l.routinesDeleteConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _leaving = true;
    await _r.delete(routineId);
    if (mounted) context.pop();
  }

  Future<void> _exerciseMenu(RoutineExerciseDetail e, String name, int defaultRest) async {
    _closeKeypad();
    final action = await showRoutineExerciseMenu(context, name);
    if (!mounted || action == null) return;
    final l = context.l10n;
    switch (action) {
      case RoutineExerciseAction.rest:
        await _pickRest(e, defaultRest);
      case RoutineExerciseAction.remove:
        final ok = await routinesConfirm(
          context,
          title: l.routinesRemoveExerciseTitle,
          body: l.routinesRemoveExerciseBody,
          confirm: l.routinesRemove,
          destructive: true,
        );
        if (ok) await _r.removeExercise(e.entry.id);
      case RoutineExerciseAction.reorder:
        final d = _detail;
        if (d == null) return;
        await showRoutineReorderSheet(
          context,
          items: [
            for (final x in d.exercises) (id: x.entry.id, name: routineNamesFor(context, x.exercise, x.entry.exerciseId).primary),
          ],
          onReorder: (ids) => unawaited(_r.reorderExercises(ids)),
        );
    }
  }

  Future<void> _pickRest(RoutineExerciseDetail e, int defaultRest) async {
    _closeKeypad();
    final choice = await showRoutineRestSheet(context, current: e.entry.restSeconds, defaultSeconds: defaultRest);
    if (choice != null) await _r.setRestSeconds(e.entry.id, choice.seconds);
  }

  Future<void> _pickType(RoutineSet set) async {
    final type = await showSetTypeSheet(context, set.type);
    if (type != null && type != set.type) await _r.updateSet(set.id, type: type);
  }

  void _deleteSet(RoutineSet set) {
    if (_editing?.setId == set.id) _closeKeypad();
    unawaited(_r.deleteSet(set.id));
    showSetDeletedSnackBar(context, onUndo: () => _r.restoreSet(set));
  }

  // ---- Keypad --------------------------------------------------------------------

  RoutineSet? _findSet(String id) {
    for (final s in _detail?.allSets ?? const <RoutineSet>[]) {
      if (s.id == id) return s;
    }
    return null;
  }

  String _inputText(RoutineSet s, SetField f) => f == SetField.weight
      ? (s.targetWeightKg == null ? '' : setWeightInput(s.targetWeightKg!, _unit))
      : (s.targetReps == null ? '' : '${s.targetReps}');

  void _edit(RoutineSet set, SetField field) {
    FocusScope.of(context).unfocus();
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

  void _closeKeypad() {
    if (_editing != null && mounted) setState(() => _editing = null);
  }

  void _saveWeight(RoutineSet set, double? kg) => unawaited(kg == null || kg <= 0
      ? _r.updateSet(set.id, clearWeight: true)
      : _r.updateSet(set.id, targetWeightKg: kg));

  void _saveReps(RoutineSet set, int? reps) => unawaited(reps == null || reps <= 0
      ? _r.updateSet(set.id, clearReps: true)
      : _r.updateSet(set.id, targetReps: reps));

  void _onKey(KeypadKey key) {
    final e = _editing;
    final set = e == null ? null : _findSet(e.setId);
    if (e == null || set == null) return _closeKeypad();
    final weight = e.field == SetField.weight;
    final unit = _unit;
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
        final v = _keypad.apply(key, e.field, unit);
        setState(() {});
        if (weight) {
          _saveWeight(set, v);
        } else {
          _saveReps(set, v?.toInt());
        }
    }
  }

  /// Next field in reading order: weight → reps, then the next set.
  ({RoutineSet set, SetField field})? _nextTarget() {
    final e = _editing;
    final d = _detail;
    if (e == null || d == null) return null;
    final order = <({RoutineSet set, SetField field})>[
      for (final s in d.allSets) ...[(set: s, field: SetField.weight), (set: s, field: SetField.reps)],
    ];
    final i = order.indexWhere((t) => t.set.id == e.setId && t.field == e.field);
    return i < 0 || i + 1 >= order.length ? null : order[i + 1];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack, required this.onStart});

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xs, AzmSpace.xs, AzmSpace.pageMargin, AzmSpace.xs),
      child: Row(
        children: [
          // arrow_back mirrors automatically in RTL.
          AzmHeaderButton(icon: Icons.arrow_back_rounded, semanticLabel: l.commonBack, onTap: onBack),
          const SizedBox(width: AzmSpace.xxs),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AzmType.screenTitle.copyWith(color: c.textPrimary),
              ),
            ),
          ),
          AzmPressable(
            key: const ValueKey('routineStart'),
            onTap: onStart,
            semanticLabel: l.routinesStartWorkout,
            child: Center(
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md, vertical: AzmSpace.xs),
                decoration: BoxDecoration(
                  color: onStart == null ? c.actionDisabled : c.accent,
                  borderRadius: BorderRadius.circular(AzmRadius.pill),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: onStart == null ? c.textTertiary : c.onAccent, size: AzmSize.icon - AzmSpace.xxs),
                      const SizedBox(width: AzmSpace.xxs),
                      Text(l.routinesStartWorkout, style: AzmType.pillLabel.copyWith(color: onStart == null ? c.textTertiary : c.onAccent)),
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
}

/// One exercise: header (thumbnail, names, menu), rest chip, target sets.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.detail,
    required this.unit,
    required this.defaultRest,
    required this.editing,
    required this.rowKey,
    required this.onMenu,
    required this.onRest,
    required this.onLabelTap,
    required this.onField,
    required this.onDeleteSet,
    required this.onAddSet,
  });

  final RoutineExerciseDetail detail;
  final WeightUnit unit;
  final int defaultRest;
  final ({String setId, SetField field})? editing;
  final GlobalKey Function(String setId) rowKey;
  final ValueChanged<String> onMenu;
  final VoidCallback onRest;
  final ValueChanged<RoutineSet> onLabelTap;
  final void Function(RoutineSet set, SetField field) onField;
  final ValueChanged<RoutineSet> onDeleteSet;
  final VoidCallback onAddSet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final names = routineNamesFor(context, detail.exercise, detail.entry.exerciseId);
    final numbers = normalSetNumbers(detail.sets.map((s) => s.type));
    final rest = detail.entry.restSeconds;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AzmSpace.listGap),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      // No clip: a set's red delete panel reaches past the card to the screen
      // edge (SetRow); nothing else touches the rounded corners.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.md, AzmSpace.md, AzmSpace.xxs, 0),
            child: Row(
              children: [
                if (detail.exercise != null)
                  ExerciseThumbnail(exercise: detail.exercise!)
                else
                  const RoutinesUnknownThumb(),
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
                  semanticLabel: l.routinesExerciseOptions,
                  onTap: () => onMenu(names.primary),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md - AzmSpace.xxs),
              child: AzmPressable(
                onTap: onRest,
                semanticLabel: l.routinesRestTitle,
                child: Center(
                  widthFactor: 1,
                  child: RoutinesPill(
                    icon: Icons.timer_outlined,
                    accent: rest != null,
                    label: rest != null
                        ? l.routinesRestValue(formatRest(rest))
                        : l.routinesRestDefault(formatRest(defaultRest)),
                  ),
                ),
              ),
            ),
          ),
          SetTableHeader(
            setLabel: l.commonSetColSet,
            previousLabel: null,
            weightLabel: l.weightUnitLabel(unit),
            repsLabel: l.commonSetColReps,
            showCheck: false,
          ),
          const SizedBox(height: AzmSpace.xxs),
          for (var i = 0; i < detail.sets.length; i++)
            KeyedSubtree(
              key: rowKey(detail.sets[i].id),
              child: _targetRow(l, detail.sets[i], numbers[i]),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AzmSpace.md),
            child: AzmPressable(
              onTap: onAddSet,
              semanticLabel: l.routinesAddSet,
              child: ExcludeSemantics(
                child: Container(
                  height: AzmSize.headerButton,
                  decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.segment)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: AzmSize.icon - AzmSpace.xxs, color: c.textPrimary),
                      const SizedBox(width: AzmSpace.xxs),
                      Text(l.routinesAddSet, style: AzmType.controlLabel.copyWith(color: c.textPrimary)),
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

  /// One target set on the shared [SetRow]: no "previous" and no ✓ (a
  /// routine holds targets, not logged sets); swipe toward the start edge or
  /// long-press → "Delete set" deletes (with Undo).
  Widget _targetRow(AppLocalizations l, RoutineSet set, int? number) {
    final weight = set.targetWeightKg;
    final reps = set.targetReps;
    final active = editing?.setId == set.id ? editing!.field : null;
    return SetRow(
      key: ValueKey(set.id),
      setId: set.id,
      label: l.setLabel(set.type, number),
      labelKind: setLabelKind(set.type),
      labelSemantics: l.setTypeName(set.type),
      previousText: null,
      weightText: weight == null ? '' : setWeightNumber(weight, unit),
      repsText: reps == null ? '' : AzmNumbers.integer(reps),
      weightHint: l.commonNoData,
      repsHint: l.commonNoData,
      completed: false,
      activeField: active,
      onLabelTap: () => onLabelTap(set),
      onPreviousTap: null,
      onWeightTap: () => onField(set, SetField.weight),
      onRepsTap: () => onField(set, SetField.reps),
      onToggleComplete: null,
      onDelete: () => onDeleteSet(set),
      deleteLabel: l.commonSetDelete,
      completeLabel: null,
    );
  }
}
