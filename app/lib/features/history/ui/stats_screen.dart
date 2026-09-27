import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/compact_number.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../settings/data/training_settings.dart';
import '../data/history_format.dart';
import '../data/history_models.dart';
import '../data/history_repository.dart';
import 'history_text.dart';
import 'history_week_chart.dart';
import 'history_widgets.dart';

/// Stats: totals, workouts per week (last 12 weeks, week start per locale),
/// per-exercise records (heaviest, e1RM, best set volume) → exercise detail.
/// Route: AppRoutes.stats.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  /// Weeks shown in the chart.
  static const int weeks = 12;

  /// Key of the records section (screenshots scroll to it).
  static const recordsKey = ValueKey('statsRecords');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final data = ref.watch(historyProvider).value;
    final exercises = data?.exercises ?? const {};
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: l.historyStatsTitle, backLabel: l.commonBack, onBack: () => context.pop()),
            Expanded(
              child: data == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AzmSpace.pageMargin,
                        AzmSpace.xs,
                        AzmSpace.pageMargin,
                        MediaQuery.paddingOf(context).bottom + AzmSpace.xxxl,
                      ),
                      children: [
                        _Totals(data: data, unit: unit),
                        HistorySectionTitle(l.historyStatsPerWeek),
                        _Weekly(data: data),
                        HistorySectionTitle(l.historyStatsRecords, key: recordsKey),
                        if (data.records.isEmpty)
                          HistoryCard(
                            child: Text(
                              l.historyStatsRecordsEmpty,
                              style: AzmType.secondary.copyWith(color: context.colors.textSecondary),
                            ),
                          )
                        else
                          HistoryCard(
                            padded: false,
                            child: Column(
                              children: [
                                for (final (i, r) in data.records.indexed) ...[
                                  if (i > 0) Divider(height: 1, indent: AzmSpace.cardPadding, color: context.colors.divider),
                                  _RecordRow(record: r, exercise: exercises[r.exerciseId], unit: unit),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.data, required this.unit});

  final HistoryData data;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lifted = Units.toDisplay(data.liftedKg, unit);
    return HistoryCard(
      child: Row(
        children: [
          HistoryStat(label: l.historyStatWorkouts, value: AzmNumbers.integer(data.workouts.length)),
          HistoryStat(label: l.historyStatSets, value: AzmNumbers.integer(data.setCount)),
          HistoryStat(
            label: l.historyStatLifted,
            value: lifted <= 0 ? l.historyNoData : l.historyWeightValue(l.compactNumberText(lifted), l.weightUnitLabel(unit)),
          ),
        ],
      ),
    );
  }
}

class _Weekly extends StatelessWidget {
  const _Weekly({required this.data});

  final HistoryData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final perWeek = workoutsPerWeek(
      data.workouts.map((w) => w.startedAt),
      today: DateTime.now(),
      firstDayOfWeek: MaterialLocalizations.of(context).firstDayOfWeekIndex,
      weeks: StatsScreen.weeks,
    );
    final thisWeek = perWeek.last.count;
    final average = perWeek.fold(0, (n, w) => n + w.count) / perWeek.length;
    return HistoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.historyStatsThisWeek(thisWeek, AzmNumbers.integer(thisWeek)),
            style: AzmType.rowTitle.copyWith(color: c.textPrimary),
          ),
          Text(
            l.historyStatsAverage(AzmNumbers.decimal(average)),
            style: AzmType.small.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AzmSpace.md),
          HistoryWeekChart(counts: [for (final w in perWeek) w.count]),
          const SizedBox(height: AzmSpace.xs),
          Row(
            children: [
              Text(HistoryDates.dayMonth(context, perWeek.first.start), style: AzmType.chartLabel.copyWith(color: c.textSecondary)),
              const Spacer(),
              Text(HistoryDates.dayMonth(context, perWeek.last.start), style: AzmType.chartLabel.copyWith(color: c.textSecondary)),
              // Keeps the dates under the bars, clear of the scale column.
              const SizedBox(width: AzmSpace.xxxl),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.exercise, required this.unit});

  final ExerciseRecord record;
  final Exercise? exercise;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final names = namesOrUnknown(context, exercise, record.exerciseId);
    final b = record.bests;

    Widget value(String label, double kg) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AzmType.small.copyWith(color: c.textTertiary)),
              Text(l.weight(kg, unit), maxLines: 1, style: AzmType.rowNumberCompact.copyWith(color: c.pr)),
            ],
          ),
        );

    return AzmPressable(
      onTap: exercise == null ? null : () => context.push(AppRoutes.exercise(record.exerciseId)),
      semanticLabel: names.primary,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.cardPadding, AzmSpace.md, AzmSpace.xs, AzmSpace.md),
        child: Row(
          children: [
            if (exercise != null) ...[ExerciseThumbnail(exercise: exercise!), const SizedBox(width: AzmSpace.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isolate(names.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AzmType.listTitle.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AzmSpace.xxs),
                  Row(
                    children: [
                      value(l.historyRecordHeaviest, b.heaviestKg),
                      value(l.historyRecord1Rm, b.best1RmKg),
                      value(l.historyRecordVolume, b.bestVolumeKg),
                    ],
                  ),
                ],
              ),
            ),
            // Directional: mirrors in RTL.
            if (exercise != null) Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: AzmSize.icon),
          ],
        ),
      ),
    );
  }
}
