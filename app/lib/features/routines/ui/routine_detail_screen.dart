import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart' show SetType;
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../settings/data/training_settings.dart';
import '../data/routine_repository.dart';
import 'routines_home_section.dart';
import 'routines_widgets.dart';

/// Read-only routine detail, opened by tapping a routine card. Route:
/// AppRoutes.routineDetailFor(id). Per exercise: round thumbnail + name, then
/// SET | KG | REPS as plain text rows (alternating background). "Edit" opens
/// the editor; the dumbbell button at the bottom starts the routine.
class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final detail = ref.watch(routineDetailProvider(routineId)).value;
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;

    return Scaffold(
      backgroundColor: c.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(
              title: detail == null ? l.routinesDetailTitle : l.routineName(detail.routine),
              backLabel: l.commonBack,
              onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.workout),
            ),
            Expanded(
              child: detail == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsetsDirectional.only(bottom: AzmSpace.xl),
                      children: [
                        if ((detail.routine.notes ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AzmSpace.pageMargin,
                              0,
                              AzmSpace.pageMargin,
                              AzmSpace.xs,
                            ),
                            child: Text(
                              detail.routine.notes!.trim(),
                              style: AzmType.secondary.copyWith(color: c.textSecondary),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: AzmSpace.pageMargin, end: AzmSpace.xxs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.routinesDetailExercises,
                                  style: AzmType.itemLabel.copyWith(color: c.textSecondary),
                                ),
                              ),
                              AzmPressable(
                                key: const ValueKey('routineDetailEdit'),
                                onTap: () => context.push(AppRoutes.routineEditorFor(routineId)),
                                semanticLabel: l.routinesEditTitle,
                                child: ExcludeSemantics(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md),
                                      child: Text(
                                        l.routinesEditShort,
                                        style: AzmType.itemLabel.copyWith(color: c.accent),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (detail.exercises.isEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.all(AzmSpace.pageMargin),
                            child: Text(
                              l.routinesDetailEmpty,
                              textAlign: TextAlign.center,
                              style: AzmType.secondary.copyWith(color: c.textSecondary),
                            ),
                          ),
                        for (final e in detail.exercises) _ExerciseBlock(detail: e, unit: unit),
                      ],
                    ),
            ),
            if (detail != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                ),
                child: RoutineStartButton(
                  key: const ValueKey('routineDetailStart'),
                  onTap: detail.exercises.isEmpty ? null : () => unawaited(startRoutine(context, ref, routineId)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({required this.detail, required this.unit});

  final RoutineExerciseDetail detail;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final names = routineNamesFor(context, detail.exercise, detail.entry.exerciseId);
    final numbers = normalSetNumbers(detail.sets.map((s) => s.type));
    final caption = AzmType.smallStrong.copyWith(color: c.textTertiary);
    final value = AzmType.itemLabel.copyWith(color: c.textPrimary);
    final none = AzmType.itemLabel.copyWith(color: c.textNoData);

    Widget row({required Widget set, required Widget kg, required Widget reps, Color? color, Key? key}) => Container(
          key: key,
          color: color,
          constraints: const BoxConstraints(minHeight: AzmSize.detailRow),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
          child: Row(
            children: [
              SizedBox(width: AzmSize.setCellMinWidth, child: Center(child: set)),
              Expanded(child: Center(child: kg)),
              Expanded(child: Center(child: reps)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AzmSpace.md, bottom: AzmSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.pageMargin),
            child: Row(
              children: [
                if (detail.exercise != null)
                  ExerciseThumbnail(exercise: detail.exercise!, size: AzmSize.avatar, round: true)
                else
                  const RoutineUnknownAvatar(),
                const SizedBox(width: AzmSpace.md),
                Expanded(
                  child: Text(
                    names.primary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.rowTitle.copyWith(color: c.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AzmSpace.xxs),
          row(
            set: Text(l.commonSetColSet.toUpperCase(), style: caption),
            kg: Text(l.weightUnitLabel(unit).toUpperCase(), style: caption),
            reps: Text(l.commonSetColReps.toUpperCase(), style: caption),
          ),
          for (var i = 0; i < detail.sets.length; i++)
            row(
              key: ValueKey('routine-detail-set-${detail.sets[i].id}'),
              color: i.isOdd ? c.card : null,
              set: Text(
                l.setLabel(detail.sets[i].type, numbers[i]),
                style: AzmType.controlLabel.copyWith(
                  color: detail.sets[i].type == SetType.warmup ? c.warmupText : c.textPrimary,
                ),
              ),
              kg: detail.sets[i].targetWeightKg == null
                  ? Text(l.commonNoData, style: none)
                  : Text(setWeightNumber(detail.sets[i].targetWeightKg!, unit), style: value),
              reps: detail.sets[i].targetReps == null
                  ? Text(l.commonNoData, style: none)
                  : Text(AzmNumbers.integer(detail.sets[i].targetReps!), style: value),
            ),
        ],
      ),
    );
  }
}
