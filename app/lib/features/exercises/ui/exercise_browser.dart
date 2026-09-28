import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/exercise_card.dart';
import '../../settings/data/training_settings.dart';
import '../data/exercise_filters.dart';
import '../data/exercise_history.dart';
import '../data/exercise_library.dart';
import '../data/exercise_search_index.dart';
import 'exercise_format.dart';
import 'filter_sheet.dart';

/// Search box + filter bar (Place · Muscle group · Equipment) + results.
/// Shared by the library (tap opens the detail) and the picker (tap toggles
/// selection). Filters combine with each other and with the search text
/// (OR within a type, AND across types) and are remembered per [screen].
///
/// [selection] null = library mode; otherwise the selected ids in order, and
/// every row shows its position (1, 2, 3…) or an empty ring.
class ExerciseBrowser extends ConsumerStatefulWidget {
  const ExerciseBrowser({
    super.key,
    required this.onTap,
    this.selection,
    this.bottomPadding = 0,
    this.screen = FilterScreen.library,
  });

  final ValueChanged<Exercise> onTap;
  final List<String>? selection;

  /// Whose last-used filters are restored and saved.
  final FilterScreen screen;

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
  int _request = 0;

  @override
  void initState() {
    super.initState();
    // The results follow the field's TEXT, whatever changed it: typing, the ×
    // button, keyboard undo, or a programmatic edit. (onChanged alone misses
    // the last two, which left a stale list behind.)
    _text.addListener(_onText);
    _restoreFilters();
  }

  /// Last-used filters of this screen, then the first search (so the list
  /// never flashes unfiltered).
  Future<void> _restoreFilters() async {
    var saved = ExerciseFilters.none;
    try {
      saved = await ref.read(exerciseFilterStoreProvider).load(widget.screen);
      if (!saved.isEmpty) {
        saved = (await ref.read(exerciseSearchIndexProvider.future)).onlyAvailable(saved);
      }
    } on Object {
      saved = ExerciseFilters.none; // no DB / asset (tests): start unfiltered
    }
    if (!mounted) return;
    if (saved.isEmpty) return _run();
    _update(_query.copyWith(filters: saved));
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
    _setFilters(ExerciseFilters.none);
  }

  /// Applies and remembers (per screen) the filters.
  void _setFilters(ExerciseFilters f) {
    _update(_query.copyWith(filters: f));
    ref.read(exerciseFilterStoreProvider).save(widget.screen, f).ignore();
  }

  Future<void> _openFilter(FilterKind kind) async {
    FocusScope.of(context).unfocus();
    final ExerciseSearchIndex index;
    final ExerciseFilterMapping mapping;
    try {
      index = await ref.read(exerciseSearchIndexProvider.future);
      mapping = ref.read(exerciseFilterMappingProvider);
    } on Object {
      return;
    }
    if (!mounted) return;
    final base = _query;
    final picked = await showFilterSheet(
      context,
      kind: kind,
      mapping: mapping,
      options: index.availableOptions(kind),
      selected: base.filters.of(kind),
      countFor: (sel) => index.count(base.copyWith(filters: base.filters.withKind(kind, sel))),
    );
    if (picked == null || !mounted) return;
    _setFilters(_query.filters.withKind(kind, picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final records = ref.watch(exerciseRecordsProvider).value ?? const {};
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;
    final results = _results;
    final selection = widget.selection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
          child: _SearchField(controller: _text),
        ),
        const SizedBox(height: AzmSpace.xxs),
        FilterBar(filters: _query.filters, onOpen: _openFilter),
        _ResultBar(
          count: results?.length,
          onClearFilters: _query.filters.isEmpty ? null : () => _setFilters(ExerciseFilters.none),
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

/// "154 exercises" + "Clear filters" while any filter is active.
class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.count, required this.onClearFilters});

  final int? count;

  /// Null = no active filter (no button).
  final VoidCallback? onClearFilters;

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
            if (onClearFilters != null)
              AzmPressable(
                key: FilterKeys.clearAll,
                onTap: onClearFilters,
                semanticLabel: l10n.exercisesClearFilters,
                child: ExcludeSemantics(
                  child: Center(
                    child: Text(l10n.exercisesClearFilters, style: AzmType.chipLabel.copyWith(color: c.accent)),
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
