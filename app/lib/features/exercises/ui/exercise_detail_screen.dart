import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/exercise_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/media/media_resolver.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_placeholder.dart';
import '../../../core/widgets/exercise_card.dart' show isolateName;
import '../../../core/widgets/muscle_chips.dart';
import '../../history/ui/exercise_history_link_slot.dart';
import '../../settings/data/training_settings.dart';
import '../data/exercise_history.dart';
import '../data/exercise_labels.dart';
import '../data/exercise_library.dart';
import 'exercise_format.dart';
import 'exercise_progress_chart.dart';

/// Exercise detail (GIF, instructions, muscles, history, chart, PRs). Route: AppRoutes.exercise(id).
///
/// Media → names → muscles/equipment → records → progress chart → recent
/// history → instructions. History data comes from [exerciseHistoryProvider]
/// (see `data/exercise_history.dart` for the interface).
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  /// Key of the "Your history" section (screenshots scroll to it).
  static const historyKey = ValueKey('exerciseDetailHistory');

  /// Most recent workouts listed under "Your history".
  static const int recentSessions = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));
    final e = exercise.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(
              title: e == null ? '' : isolateName(context.namesOf(e).primary),
              backLabel: l10n.commonBack,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: switch (exercise) {
                AsyncData(value: final Exercise e) => _DetailBody(exercise: e),
                AsyncLoading() => const SizedBox.shrink(),
                _ => AzmPlaceholder(icon: Icons.help_outline_rounded, message: l10n.exercisesUnknown),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final e = exercise;
    final names = context.namesOf(e);
    final hasMedia = ref.watch(mediaResolverProvider).gifFor(e) != null;
    final history = ref.watch(exerciseHistoryProvider(e.id)).value ?? ExerciseHistory.empty;
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;
    final instructions = exerciseInstructions(e, Localizations.localeOf(context));

    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AzmSpace.pageMargin,
        AzmSpace.xs,
        AzmSpace.pageMargin,
        MediaQuery.paddingOf(context).bottom + AzmSpace.xxxl,
      ),
      children: [
        _Card(
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                ExerciseAnimation(exercise: e, size: math.min(box.maxWidth, AzmSize.exerciseMedia)),
                if (hasMedia) ...[
                  const SizedBox(height: AzmSpace.xs),
                  Text(
                    // LTR isolate: the Latin credit keeps its order in Arabic.
                    '\u2066${l10n.exercisesDetailAttribution}\u2069',
                    textAlign: TextAlign.center,
                    style: AzmType.micro.copyWith(color: c.textMicro),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AzmSpace.xl),
        Text(isolateName(names.primary), style: AzmType.sectionTitle.copyWith(color: c.textPrimary)),
        if (names.secondary != null)
          Text(isolateName(names.secondary!), style: AzmType.body.copyWith(color: c.textSecondary)),
        const SizedBox(height: AzmSpace.xl),
        _MusclesCard(exercise: e),
        _SectionTitle(l10n.exercisesDetailRecords),
        _RecordsCard(records: history.records, unit: unit),
        _SectionTitle(l10n.exercisesDetailProgress),
        _ProgressCard(history: history, unit: unit),
        _SectionTitle(l10n.exercisesDetailHistory, key: ExerciseDetailScreen.historyKey),
        if (history.isEmpty)
          _Card(child: _Muted(l10n.exercisesHistoryEmpty))
        else
          for (final (i, s) in history.sessions.take(ExerciseDetailScreen.recentSessions).indexed) ...[
            if (i > 0) const SizedBox(height: AzmSpace.listGap),
            _SessionCard(session: s, unit: unit),
          ],
        // History window slot: "See all history".
        ExerciseHistoryLinkSlot(exerciseId: e.id, sessionCount: history.sessions.length),
        _SectionTitle(l10n.exercisesDetailInstructions),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (instructions.englishFallback) ...[
                _Muted(l10n.exercisesDetailInstructionsEnglishOnly),
                const SizedBox(height: AzmSpace.md),
              ],
              for (final (i, step) in instructions.steps.indexed)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : AzmSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: AzmSpace.xxxl,
                        child: Text(
                          AzmNumbers.integer(i + 1),
                          style: AzmType.rowNumberCompact.copyWith(color: c.textTertiary),
                        ),
                      ),
                      Expanded(
                        // English steps keep their own direction inside an Arabic UI.
                        child: Text(isolateName(step), style: AzmType.body.copyWith(color: c.textPrimary)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: AzmSpace.xxxl, bottom: AzmSpace.md),
    child: Semantics(
      header: true,
      child: Text(text, style: AzmType.cardTitle.copyWith(color: context.colors.textPrimary)),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsetsDirectional.all(AzmSpace.cardPadding)});

  final Widget child;
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
    child: child,
  );
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AzmType.secondary.copyWith(color: context.colors.textSecondary));
}

class _MusclesCard extends StatelessWidget {
  const _MusclesCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = exercise;
    // Several dataset keys share a label (lats / latissimus dorsi): show each once,
    // and never repeat the target.
    final target = ExerciseLabels.muscle(l10n, e.target);
    final secondary = <String>{for (final m in decodeStringList(e.secondaryMuscles)) ExerciseLabels.muscle(l10n, m)}
      ..remove(target);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: l10n.exercisesDetailTarget, values: [target], highlight: true),
          if (secondary.isNotEmpty) _InfoRow(label: l10n.exercisesDetailSecondary, values: secondary.toList()),
          _InfoRow(label: l10n.exercisesDetailEquipment, values: [ExerciseLabels.equipmentLabel(l10n, e.equipment)]),
          _InfoRow(
            label: l10n.exercisesDetailBodyPart,
            values: [ExerciseLabels.bodyPart(l10n, e.bodyPart)],
            last: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.values, this.highlight = false, this.last = false});

  final String label;
  final List<String> values;
  final bool highlight;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: last ? 0 : AzmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AzmType.fieldLabel.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.xxs),
          Wrap(
            spacing: AzmSpace.xs,
            runSpacing: AzmSpace.xs,
            children: [
              for (final v in values)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md, vertical: AzmSpace.xxs),
                  decoration: BoxDecoration(
                    color: highlight ? c.accentSoft : c.fill,
                    borderRadius: BorderRadius.circular(AzmRadius.pill),
                  ),
                  child: Text(v, style: AzmType.chipLabel.copyWith(color: highlight ? c.accent : c.textPrimary)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records, required this.unit});

  final PrBests records;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget stat(String label, double kg) => Expanded(
      child: _Stat(label: label, kg: kg, unit: unit),
    );
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stat(l10n.exercisesRecordHeaviest, records.heaviestKg),
          const SizedBox(width: AzmSpace.md),
          stat(l10n.exercisesRecordBest1Rm, records.best1RmKg),
          const SizedBox(width: AzmSpace.md),
          stat(l10n.exercisesRecordBestVolume, records.bestVolumeKg),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.kg, required this.unit});

  final String label;
  final double kg;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final none = kg <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                // "No data yet" is a grey dash, never 0.
                text: none ? '—' : '\u2068${ExerciseFormat.number(kg, unit)}', // isolate opens here…
                style: AzmType.rowNumber.copyWith(color: none ? c.textNoData : c.pr),
              ),
              if (!none)
                TextSpan(
                  text: ' ${ExerciseFormat.unit(l10n, unit)}\u2069', // …and closes here (no "kg 70" in RTL)
                  style: AzmType.small.copyWith(color: c.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(height: AzmSpace.xxs),
        Text(label, style: AzmType.small.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

enum _Metric { heaviest, oneRm, volume }

class _ProgressCard extends StatefulWidget {
  const _ProgressCard({required this.history, required this.unit});

  final ExerciseHistory history;
  final WeightUnit unit;

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> {
  _Metric _metric = _Metric.oneRm;

  List<ProgressPoint> _points() => [
    for (final s in widget.history.sessions.reversed)
      (
        date: s.startedAt,
        valueKg: switch (_metric) {
          _Metric.heaviest => s.bests.heaviestKg,
          _Metric.oneRm => s.bests.best1RmKg,
          _Metric.volume => s.volumeKg,
        },
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final points = _points().where((p) => p.valueKg > 0).toList();
    return _Card(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AzmSpace.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuscleChips(
            items: [
              MuscleChipItem(value: _Metric.heaviest.name, label: l10n.exercisesChartHeaviest),
              MuscleChipItem(value: _Metric.oneRm.name, label: l10n.exercisesChart1Rm),
              MuscleChipItem(value: _Metric.volume.name, label: l10n.exercisesChartVolume),
            ],
            selected: _metric.name,
            onSelected: (v) => setState(() => _metric = _Metric.values.byName(v!)),
          ),
          const SizedBox(height: AzmSpace.md),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.cardPadding),
            child: points.length < 2
                ? _Muted(l10n.exercisesChartEmpty)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ExerciseFormat.weight(l10n, points.last.valueKg, widget.unit),
                        style: AzmType.rowNumber.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AzmSpace.xs),
                      ExerciseProgressChart(points: points),
                      const SizedBox(height: AzmSpace.xs),
                      Row(
                        children: [
                          Text(
                            ExerciseFormat.shortDate(context, points.first.date),
                            style: AzmType.chartLabel.copyWith(color: c.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            ExerciseFormat.shortDate(context, points.last.date),
                            style: AzmType.chartLabel.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.unit});

  final ExerciseSession session;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    var normal = 0;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isolateName(session.workoutName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AzmType.listTitle.copyWith(color: c.textPrimary),
          ),
          Text(ExerciseFormat.date(context, session.startedAt), style: AzmType.small.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.xs),
          for (final s in session.sets)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AzmSpace.xxs),
              child: Row(
                children: [
                  SizedBox(
                    width: AzmSpace.xxxl,
                    child: Text(
                      ExerciseFormat.typeLabel(l10n, s.type) ?? AzmNumbers.integer(++normal),
                      style: AzmType.rowNumberCompact.copyWith(
                        color: s.type == SetType.warmup ? c.warmupText : c.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    ExerciseFormat.set(l10n, s, unit),
                    style: AzmType.rowNumberCompact.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
