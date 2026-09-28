import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/filter_icon.dart';
import '../data/exercise_filters.dart';
import '../data/exercise_labels.dart';

/// Keys for tests / screenshots.
abstract final class FilterKeys {
  static ValueKey<String> chip(FilterKind k) => ValueKey('filterChip-${k.name}');
  static ValueKey<String> card(FilterKind k, String id) => ValueKey('filterCard-${k.name}-$id');
  static const showResults = ValueKey('filterShowResults');
  static const clear = ValueKey('filterClear');
  static const clearAll = ValueKey('filterClearAll');
}

/// Filter sheet of one type (docs/SPEC.md → Exercise library → Filters): a
/// grid of cards (icon + name), multi-select; "Show N results" applies the
/// selection (N is live: search text and the other filters included) and
/// "Clear filters" unselects this sheet's cards. Returns the new selection,
/// or null when dismissed without applying.
Future<Set<String>?> showFilterSheet(
  BuildContext context, {
  required FilterKind kind,
  required ExerciseFilterMapping mapping,
  required Set<String> selected,
  required int Function(Set<String> selection) countFor,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    // Above the shell's floating tab bar.
    useRootNavigator: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
    builder: (context) => _FilterSheet(kind: kind, mapping: mapping, initial: selected, countFor: countFor),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.kind, required this.mapping, required this.initial, required this.countFor});

  final FilterKind kind;
  final ExerciseFilterMapping mapping;
  final Set<String> initial;
  final int Function(Set<String> selection) countFor;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _draft = {...widget.initial};

  void _toggle(String id) => setState(() {
        if (!_draft.remove(id)) _draft.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final kind = widget.kind;
    final count = widget.countFor(_draft);

    final sections = kind == FilterKind.muscle
        ? [for (final s in widget.mapping.muscleSections) (title: ExerciseLabels.muscleSection(l, s.id), ids: s.groups)]
        : [(title: null, ids: widget.mapping.optionsOf(kind))];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, 0, AzmSpace.pageMargin, AzmSpace.xs),
          child: Semantics(
            header: true,
            child: Text(ExerciseLabels.filterKind(l, kind), style: AzmType.screenTitle.copyWith(color: c.textPrimary)),
          ),
        ),
        Flexible(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              for (final s in sections) ...[
                if (s.title != null)
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.md, AzmSpace.pageMargin, AzmSpace.xs),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(s.title!, style: AzmType.smallStrong.copyWith(color: c.textSecondary)),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: AzmSpace.xs,
                      crossAxisSpacing: AzmSpace.xs,
                      mainAxisExtent: AzmSize.filterCard,
                    ),
                    itemCount: s.ids.length,
                    itemBuilder: (context, i) {
                      final id = s.ids[i];
                      return FilterCard(
                        key: FilterKeys.card(kind, id),
                        iconId: ExerciseLabels.filterIconId(kind, id),
                        label: ExerciseLabels.filterOption(l, kind, id),
                        selected: _draft.contains(id),
                        onTap: () => _toggle(id),
                      );
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AzmSpace.md)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(border: BorderDirectional(top: BorderSide(color: c.divider))),
          padding: EdgeInsetsDirectional.fromSTEB(
            AzmSpace.pageMargin,
            AzmSpace.md,
            AzmSpace.pageMargin,
            MediaQuery.paddingOf(context).bottom + AzmSpace.md,
          ),
          child: Row(
            children: [
              TextButton(
                key: FilterKeys.clear,
                onPressed: _draft.isEmpty ? null : () => setState(_draft.clear),
                child: Text(
                  l.exercisesFilterClearSheet,
                  style: AzmType.button.copyWith(color: _draft.isEmpty ? c.textNoData : c.accent),
                ),
              ),
              const SizedBox(width: AzmSpace.xs),
              Expanded(
                child: FilledButton(
                  key: FilterKeys.showResults,
                  onPressed: count == 0 ? null : () => Navigator.of(context).pop<Set<String>>(Set.unmodifiable(_draft)),
                  child: Text(l.exercisesFilterShowResults(count, AzmNumbers.integer(count))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One card of a filter sheet: icon + name; selected = accent wash, accent
/// border and a ✓ badge at the top end.
class FilterCard extends StatelessWidget {
  const FilterCard({super.key, required this.iconId, required this.label, required this.selected, required this.onTap});

  final String iconId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duration = AzmMotion.of(context, AzmMotion.micro);
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: duration,
          curve: AzmMotion.standard,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.fill,
            borderRadius: BorderRadius.circular(AzmRadius.input),
            border: Border.all(color: selected ? c.accent : c.fill, width: 1.5),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxs, AzmSpace.md, AzmSpace.xxs, AzmSpace.xs),
                child: Column(
                  children: [
                    FilterIcon(iconId, size: AzmSize.filterIcon, base: selected ? c.textSecondary : c.textTertiary),
                    const SizedBox(height: AzmSpace.xs),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AzmType.chipLabel.copyWith(color: selected ? c.accent : c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: AzmSpace.xs,
                  end: AzmSpace.xs,
                  child: Container(
                    width: AzmSize.filterCount,
                    height: AzmSize.filterCount,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: AzmSize.filterCount - AzmSpace.xxs, color: c.onAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The filter bar under the search field: Place · Muscle group · Equipment,
/// sharing the row equally (always all three on screen, any width/language).
/// An active chip turns accent and shows how many of its cards are selected.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.filters, required this.onOpen});

  final ExerciseFilters filters;
  final ValueChanged<FilterKind> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
      child: Row(
        children: [
          for (final k in FilterKind.values) ...[
            if (k.index > 0) const SizedBox(width: AzmSpace.xs),
            Expanded(
              child: _FilterChip(
                key: FilterKeys.chip(k),
                label: ExerciseLabels.filterKind(context.l10n, k),
                count: filters.of(k).length,
                onTap: () => onOpen(k),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.label, required this.count, required this.onTap});

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = count > 0;
    final fg = active ? c.onAccent : c.textPrimary;
    final duration = AzmMotion.of(context, AzmMotion.micro);
    return AzmPressable(
      onTap: onTap,
      selected: active,
      semanticLabel: active ? context.l10n.exercisesFilterActiveCount(label, count) : label,
      child: ExcludeSemantics(
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: AzmMotion.standard,
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AzmSpace.xs),
            decoration: BoxDecoration(
              color: active ? c.accent : c.fill,
              borderRadius: BorderRadius.circular(AzmRadius.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AzmType.chipLabel.copyWith(color: fg)),
                ),
                const SizedBox(width: AzmSpace.xxs),
                if (active)
                  Container(
                    constraints: const BoxConstraints(minWidth: AzmSize.filterCount),
                    height: AzmSize.filterCount,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxs),
                    alignment: AlignmentDirectional.center,
                    decoration: BoxDecoration(color: c.onAccent, borderRadius: BorderRadius.circular(AzmRadius.pill)),
                    child: Text('$count', style: AzmType.badgeLabel.copyWith(color: c.accent)),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded, size: AzmSize.filterCount, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
