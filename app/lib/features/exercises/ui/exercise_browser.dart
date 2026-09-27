import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/exercise_card.dart';
import '../../../core/widgets/muscle_chips.dart';
import '../../settings/data/training_settings.dart';
import '../data/exercise_history.dart';
import '../data/exercise_labels.dart';
import '../data/exercise_library.dart';
import '../data/exercise_search_index.dart';
import 'equipment_sheet.dart';
import 'exercise_format.dart';

/// Search box + muscle chips + equipment filter + results. Shared by the
/// library (tap opens the detail) and the picker (tap toggles selection).
///
/// [selection] null = library mode; otherwise the selected ids in order, and
/// every row shows its position (1, 2, 3…) or an empty ring.
class ExerciseBrowser extends ConsumerStatefulWidget {
  const ExerciseBrowser({super.key, required this.onTap, this.selection, this.bottomPadding = 0});

  final ValueChanged<Exercise> onTap;
  final List<String>? selection;

  /// Extra space below the last row (e.g. the picker's confirm bar).
  final double bottomPadding;

  @override
  ConsumerState<ExerciseBrowser> createState() => _ExerciseBrowserState();
}

class _ExerciseBrowserState extends ConsumerState<ExerciseBrowser> {
  final _text = TextEditingController();
  ExerciseQuery _query = const ExerciseQuery();
  List<Exercise>? _results;
  bool _failed = false;
  bool _moreMuscles = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    // The results follow the field's TEXT, whatever changed it: typing, the ×
    // button, keyboard undo, or a programmatic edit. (onChanged alone misses
    // the last two, which left a stale list behind.)
    _text.addListener(_onText);
    _run();
  }

  @override
  void dispose() {
    _text.removeListener(_onText);
    _text.dispose();
    super.dispose();
  }

  void _onText() => _update(_query.copyWith(text: _text.text));

  void _update(ExerciseQuery q) {
    if (q == _query) return;
    setState(() => _query = q);
    _run();
  }

  Future<void> _run() async {
    final request = ++_request;
    final query = _query;
    try {
      final index = await ref.read(exerciseSearchIndexProvider.future);
      final rows = index.search(query);
      if (!mounted || request != _request) return;
      setState(() {
        _results = rows;
        _failed = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _results = const [];
        _failed = true;
      });
    }
  }

  void _clearAll() {
    _text.clear();
    _update(const ExerciseQuery());
  }

  Future<void> _pickEquipment() async {
    FocusScope.of(context).unfocus();
    final choice = await showEquipmentSheet(context, selected: _query.equipment);
    if (choice == null || !mounted) return;
    _update(_query.copyWith(equipment: () => choice.equipment));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final records = ref.watch(exerciseRecordsProvider).value ?? const {};
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;
    final results = _results;
    final selection = widget.selection;
    // A selected rare muscle stays visible even if "More" was never tapped.
    final showMoreMuscles = _moreMuscles || ExerciseLabels.moreTargets.contains(_query.target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(controller: _text),
              ),
              const SizedBox(width: AzmSpace.xs),
              _EquipmentButton(active: _query.equipment != null, onTap: _pickEquipment),
            ],
          ),
        ),
        const SizedBox(height: AzmSpace.xxs),
        MuscleChips(
          items: [
            MuscleChipItem(value: null, label: l10n.exercisesFilterAll),
            for (final t in ExerciseLabels.targets) MuscleChipItem(value: t, label: ExerciseLabels.muscle(l10n, t)),
            if (showMoreMuscles)
              for (final t in ExerciseLabels.moreTargets)
                MuscleChipItem(value: t, label: ExerciseLabels.muscle(l10n, t)),
          ],
          moreLabel: showMoreMuscles ? null : l10n.exercisesFilterMore,
          onMore: () => setState(() => _moreMuscles = true),
          selected: _query.target,
          onSelected: (t) => _update(_query.copyWith(target: () => t)),
        ),
        _ResultBar(
          count: results?.length,
          equipmentLabel: _query.equipment == null ? null : ExerciseLabels.equipmentLabel(l10n, _query.equipment!),
          onClearEquipment: () => _update(_query.copyWith(equipment: () => null)),
        ),
        Expanded(
          child: switch (results) {
            null => const SizedBox.shrink(),
            [] when _failed => _EmptyState(icon: Icons.fitness_center_rounded, title: l10n.exercisesLibraryEmpty),
            [] => _EmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.exercisesNoResultsTitle,
              body: l10n.exercisesNoResultsBody,
              action: _query.isEmpty ? null : (l10n.exercisesClearFilters, _clearAll),
            ),
            _ => ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsetsDirectional.only(bottom: widget.bottomPadding),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final e = results[i];
                final record = records[e.id];
                final recordText = record == null || record.heaviestKg <= 0
                    ? null
                    : ExerciseFormat.weight(l10n, record.heaviestKg, unit);
                final position = selection == null ? -1 : selection.indexOf(e.id);
                return ExerciseCard(
                  key: ValueKey(e.id),
                  exercise: e,
                  onTap: () => widget.onTap(e),
                  recordLabel: recordText,
                  recordSemanticLabel: recordText == null ? null : l10n.exercisesPrBadge(recordText),
                  selectable: selection != null,
                  selectionIndex: position >= 0 ? position + 1 : null,
                  selectionSemanticLabel: position >= 0 ? l10n.exercisesPickerSelected(position + 1) : null,
                );
              },
            ),
          },
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  /// Search runs from the controller's listener (see _ExerciseBrowserState).
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SizedBox(
      height: AzmSize.input,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          style: AzmType.body.copyWith(color: c.textPrimary),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: l10n.exercisesSearchHint,
            contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md),
            prefixIcon: Icon(Icons.search_rounded, color: c.textTertiary, size: AzmSize.icon),
            suffixIcon: value.text.isNotEmpty
                ? AzmPressable(
                    semanticLabel: l10n.exercisesSearchClear,
                    onTap: controller.clear,
                    child: Icon(Icons.close_rounded, color: c.textTertiary, size: AzmSize.icon - AzmSpace.xxs),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _EquipmentButton extends StatelessWidget {
  const _EquipmentButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      selected: active,
      semanticLabel: context.l10n.exercisesFilterEquipment,
      child: AnimatedContainer(
        duration: AzmMotion.of(context, AzmMotion.micro),
        curve: AzmMotion.standard,
        width: AzmSize.input,
        height: AzmSize.input,
        decoration: BoxDecoration(
          color: active ? c.accent : c.muted,
          borderRadius: BorderRadius.circular(AzmRadius.input),
        ),
        child: Icon(Icons.tune_rounded, size: AzmSize.icon, color: active ? c.onAccent : c.textPrimary),
      ),
    );
  }
}

/// "154 exercises" + the active equipment filter as a removable pill.
class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.count, required this.equipmentLabel, required this.onClearEquipment});

  final int? count;
  final String? equipmentLabel;
  final VoidCallback onClearEquipment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return SizedBox(
      height: AzmSize.minTouchTarget,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count == null ? '' : l10n.exercisesResultCount(count!, AzmNumbers.integer(count!)),
                style: AzmType.small.copyWith(color: c.textSecondary),
              ),
            ),
            if (equipmentLabel != null)
              AzmPressable(
                onTap: onClearEquipment,
                semanticLabel: l10n.exercisesRemoveEquipmentFilter(equipmentLabel!),
                child: ExcludeSemantics(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AzmSpace.md,
                        AzmSpace.xxs,
                        AzmSpace.xs,
                        AzmSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(AzmRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(equipmentLabel!, style: AzmType.chipLabel.copyWith(color: c.accent)),
                          const SizedBox(width: AzmSpace.xxs),
                          Icon(Icons.close_rounded, size: AzmSpace.xl, color: c.accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AzmSpace.xxxl),
      child: Column(
        children: [
          const SizedBox(height: AzmSpace.xxxl),
          Icon(icon, size: AzmSize.minTouchTarget, color: c.textNoData),
          const SizedBox(height: AzmSpace.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AzmType.emptyTitle.copyWith(color: c.textPrimary),
          ),
          if (body != null) ...[
            const SizedBox(height: AzmSpace.xxs),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: AzmType.secondary.copyWith(color: c.textSecondary),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AzmSpace.md),
            TextButton(
              onPressed: action!.$2,
              child: Text(action!.$1, style: AzmType.button.copyWith(color: c.accent)),
            ),
          ],
        ],
      ),
    );
  }
}
