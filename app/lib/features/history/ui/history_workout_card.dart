import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../data/history_models.dart';
import 'history_text.dart';

/// A past workout in the list / calendar: name, 🏆 count, date · duration ·
/// Lifted, then one line per exercise (sets × name, best set). Tap → detail.
class HistoryWorkoutCard extends StatelessWidget {
  const HistoryWorkoutCard({super.key, required this.workout, required this.exercises, required this.unit});

  final HistoryWorkout workout;

  /// Catalog rows by id (missing = unknown exercise).
  final Map<String, Exercise> exercises;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final w = workout;
    final meta = [
      HistoryDates.short(context, w.startedAt),
      if (w.endedAt != null) l.duration(w.duration),
      l.weight(w.liftedKg, unit),
    ].join(' · ');

    return AzmPressable(
      onTap: () => context.push(AppRoutes.pastWorkoutFor(w.id)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isolate(w.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.rowTitle.copyWith(color: c.textPrimary),
                  ),
                ),
                if (w.prCount > 0) ...[
                  const SizedBox(width: AzmSpace.xs),
                  Semantics(
                    label: l.historyPrCountLabel(w.prCount, AzmNumbers.integer(w.prCount)),
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs, vertical: AzmSpace.opticalInset),
                        decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AzmRadius.pill)),
                        child: Text(
                          l.historyPrBadge(AzmNumbers.integer(w.prCount)),
                          style: AzmType.badgeLabel.copyWith(color: c.pr),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AzmSpace.xxs),
            Text(meta, style: AzmType.small.copyWith(color: c.textSecondary)),
            if (w.exercises.isNotEmpty) ...[
              const SizedBox(height: AzmSpace.md),
              Divider(height: 1, color: c.divider),
              const SizedBox(height: AzmSpace.xs),
              for (final e in w.exercises)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AzmSpace.xxs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.historyExerciseSets(
                            AzmNumbers.integer(e.sets.length),
                            isolate(namesOrUnknown(context, exercises[e.exerciseId], e.exerciseId).primary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AzmType.secondary.copyWith(color: c.textPrimary),
                        ),
                      ),
                      if (e.best != null) ...[
                        const SizedBox(width: AzmSpace.md),
                        Text(l.setValue(e.best!, unit), style: AzmType.rowNumberCompact.copyWith(color: c.textSecondary)),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
