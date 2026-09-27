import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/set_row.dart' show PrBadge;
import '../../exercises/data/exercise_history.dart';
import '../../exercises/data/exercise_library.dart';
import '../../settings/data/training_settings.dart';
import 'history_text.dart';
import 'history_widgets.dart';

/// Full history of one exercise ("See all history" from the exercise detail,
/// which lists only the latest 10). Route: AppRoutes.exerciseHistoryFor(id).
/// Records on top, then every session newest first with its sets; 🏆 marks
/// the sets that were a PR when logged. Tap a session → that past workout.
class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({super.key, required this.exerciseId});

  /// Catalog exercise id.
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final exercise = ref.watch(exerciseByIdProvider(exerciseId)).value;
    final history = ref.watch(exerciseHistoryProvider(exerciseId)).value;
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;
    final title = exercise == null ? '' : isolate(namesOrUnknown(context, exercise, exerciseId).primary);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: title, backLabel: l.commonBack, onBack: () => context.pop()),
            Expanded(
              child: history == null
                  ? const SizedBox.shrink()
                  : history.isEmpty
                      ? HistoryEmpty(icon: Icons.history_rounded, title: l.historyEmptyTitle)
                      : _Body(history: history, unit: unit),
            ),
          ],
        ),
      ),
      backgroundColor: c.pageBackground,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.history, required this.unit});

  final ExerciseHistory history;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prs = sessionPrs(history.sessions);
    final r = history.records;
    String rec(double kg) => kg <= 0 ? l.historyNoData : l.weight(kg, unit);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AzmSpace.pageMargin,
        AzmSpace.xs,
        AzmSpace.pageMargin,
        MediaQuery.paddingOf(context).bottom + AzmSpace.xxxl,
      ),
      children: [
        HistoryCard(
          child: Row(
            children: [
              HistoryStat(label: l.historyRecordHeaviest, value: rec(r.heaviestKg), valueColor: context.colors.pr),
              HistoryStat(label: l.historyRecord1Rm, value: rec(r.best1RmKg), valueColor: context.colors.pr),
              HistoryStat(label: l.historyRecordVolume, value: rec(r.bestVolumeKg), valueColor: context.colors.pr),
            ],
          ),
        ),
        HistorySectionTitle(l.workoutCount(history.sessions.length)),
        for (final (i, s) in history.sessions.indexed) ...[
          if (i > 0) const SizedBox(height: AzmSpace.listGap),
          _SessionCard(session: s, prSets: prs[i], unit: unit),
        ],
      ],
    );
  }
}

/// For each session (same order as [sessions], newest first): indices of its
/// sets that were a PR versus every EARLIER session.
List<Set<int>> sessionPrs(List<ExerciseSession> sessions) {
  final out = List<Set<int>>.filled(sessions.length, const {});
  var bests = PrBests.none;
  for (var i = sessions.length - 1; i >= 0; i--) {
    final stats = [for (final s in sessions[i].sets) s.stats];
    out[i] = detectPrs(stats, bests).keys.toSet();
    final mine = PrBests.fromSets(stats);
    bests = PrBests(
      heaviestKg: mine.heaviestKg > bests.heaviestKg ? mine.heaviestKg : bests.heaviestKg,
      best1RmKg: mine.best1RmKg > bests.best1RmKg ? mine.best1RmKg : bests.best1RmKg,
      bestVolumeKg: mine.bestVolumeKg > bests.bestVolumeKg ? mine.bestVolumeKg : bests.bestVolumeKg,
    );
  }
  return out;
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.prSets, required this.unit});

  final ExerciseSession session;
  final Set<int> prSets;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final numbers = normalNumbers(session.sets.map((s) => s.type));
    return AzmPressable(
      onTap: () => context.push(AppRoutes.pastWorkoutFor(session.workoutId)),
      child: HistoryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isolate(session.workoutName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.listTitle.copyWith(color: c.textPrimary),
                  ),
                ),
                // Directional: mirrors in RTL.
                Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: AzmSize.icon),
              ],
            ),
            Text(HistoryDates.full(context, session.startedAt), style: AzmType.small.copyWith(color: c.textSecondary)),
            const SizedBox(height: AzmSpace.xs),
            for (final (i, s) in session.sets.indexed)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AzmSpace.xxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: AzmSpace.xxxl,
                      child: Text(
                        l.setLabel(s.type, numbers[i]),
                        style: AzmType.rowNumberCompact.copyWith(
                          color: s.type == SetType.warmup ? c.warmupText : c.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      ltr(l.historySetValue(l.weight(s.weightKg, unit), AzmNumbers.integer(s.reps))),
                      style: AzmType.rowNumberCompact.copyWith(color: prSets.contains(i) ? c.pr : c.textPrimary),
                    ),
                    if (prSets.contains(i)) ...[
                      const SizedBox(width: AzmSpace.xxs),
                      const PrBadge(),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
