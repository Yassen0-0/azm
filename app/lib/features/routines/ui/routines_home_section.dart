import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/exercise_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../data/routine_repository.dart';
import 'routines_widgets.dart';

/// "My routines" + "Ready programs" on the Workout tab, rendered by
/// WorkoutHomeScreen under the Start / Resume card.
class RoutinesHomeSection extends ConsumerWidget {
  const RoutinesHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final routines = ref.watch(routinesProvider);
    // No DB (widget tests without one) or still loading: render nothing.
    final list = routines.value;
    if (list == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AzmSpace.xxxl),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l.routinesMyRoutines, style: AzmType.sectionTitle.copyWith(color: c.textPrimary)),
              ),
            ),
            if (list.isNotEmpty)
              AzmPressable(
                key: const ValueKey('routinesNew'),
                onTap: () => context.push(AppRoutes.routineNew),
                semanticLabel: l.routinesNew,
                child: ExcludeSemantics(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: c.accent, size: AzmSize.icon),
                        const SizedBox(width: AzmSpace.xxs),
                        Text(l.routinesNew, style: AzmType.controlLabel.copyWith(color: c.accent)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AzmSpace.xs),
        if (list.isEmpty)
          const _EmptyCard()
        else
          for (final r in list) ...[
            _RoutineCard(summary: r),
            const SizedBox(height: AzmSpace.listGap),
          ],
        if (list.isEmpty) const SizedBox(height: AzmSpace.listGap),
        const _ProgramsEntry(),
      ],
    );
  }
}

/// Starts [routineId] (or resumes the running workout) and opens it.
Future<void> startRoutine(BuildContext context, WidgetRef ref, String routineId) async {
  final l = context.l10n;
  final result = await ref.read(routineRepositoryProvider).start(routineId, fallbackName: l.routinesUntitled);
  if (!context.mounted) return;
  unawaited(context.push(AppRoutes.activeWorkout));
  if (result.resumed) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.routinesResumed)));
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.summary});

  final RoutineSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final r = summary.routine;
    final name = l.routineName(r);
    final count = summary.exerciseIds.length;
    final catalog = ref.watch(catalogExercisesProvider(summary.exerciseIds.toSet().join(','))).value ?? const {};
    final preview = [
      for (final id in summary.exerciseIds)
        if (catalog[id] != null) context.namesOf(catalog[id]!).primary,
    ].join(l.routinesListSeparator);

    return Container(
      key: ValueKey('routine-${r.id}'),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Row(
        children: [
          Expanded(
            child: AzmPressable(
              onTap: () => context.push(AppRoutes.routineEditorFor(r.id)),
              semanticLabel: name,
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AzmSpace.cardPadding,
                    AzmSpace.md,
                    AzmSpace.xs,
                    AzmSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AzmType.rowTitle.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AzmSpace.opticalInset),
                      Text(
                        l.routinesExerciseCount(count, AzmNumbers.integer(count)),
                        style: AzmType.secondaryStrong.copyWith(color: c.textSecondary),
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: AzmSpace.opticalInset),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AzmType.secondary.copyWith(color: c.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          AzmPressable(
            key: ValueKey('routine-start-${r.id}'),
            onTap: count == 0 ? null : () => startRoutine(context, ref, r.id),
            semanticLabel: l.routinesStart(name),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AzmSpace.md),
              child: Container(
                width: AzmSize.minTouchTarget,
                height: AzmSize.minTouchTarget,
                decoration: BoxDecoration(
                  color: count == 0 ? c.actionDisabled : c.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: c.onAccent, size: AzmSize.icon),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.playlist_add_rounded, size: AzmSize.minTouchTarget, color: c.textNoData),
          const SizedBox(height: AzmSpace.xs),
          Text(
            l.routinesEmptyTitle,
            textAlign: TextAlign.center,
            style: AzmType.cardTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AzmSpace.xxs),
          Text(
            l.routinesEmptyBody,
            textAlign: TextAlign.center,
            style: AzmType.secondary.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AzmSpace.xl),
          RoutinesWideButton(
            key: const ValueKey('routinesNew'),
            label: l.routinesNew,
            icon: Icons.add_rounded,
            onTap: () => context.push(AppRoutes.routineNew),
          ),
        ],
      ),
    );
  }
}

class _ProgramsEntry extends StatelessWidget {
  const _ProgramsEntry();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return AzmPressable(
      key: const ValueKey('routinesProgramsEntry'),
      onTap: () => context.push(AppRoutes.programs),
      semanticLabel: l.routinesReadyPrograms,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
          child: Row(
            children: [
              Container(
                width: AzmSize.minTouchTarget,
                height: AzmSize.minTouchTarget,
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AzmRadius.input)),
                child: Icon(Icons.library_books_outlined, color: c.accent, size: AzmSize.icon),
              ),
              const SizedBox(width: AzmSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.routinesReadyPrograms, style: AzmType.rowTitle.copyWith(color: c.textPrimary)),
                    const SizedBox(height: AzmSpace.opticalInset),
                    Text(l.routinesReadyProgramsHint, style: AzmType.secondary.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AzmSpace.xs),
              // chevron_right mirrors in RTL (directional icon).
              Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: AzmSize.icon),
            ],
          ),
        ),
      ),
    );
  }
}
