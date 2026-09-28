import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/set_labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';
import '../../../core/widgets/azm_placeholder.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/lifted_counter.dart';
import '../../../core/widgets/rest_timer_bar.dart';
import '../../../core/widgets/set_row.dart';
import '../../../core/widgets/workout_time_sheet.dart';
import '../data/workout_models.dart';
import '../data/workout_repository.dart';
import 'workout_format.dart';

/// Post-workout summary. Route: AppRoutes.workoutSummaryFor(id).
/// Duration, Lifted + fun comparison, PRs (🏆, celebrate), best set per exercise.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(workoutDetailProvider(workoutId));
    final d = async.value;
    void done() => context.go(AppRoutes.workout);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: d == null
                  ? (async.isLoading
                      ? const SizedBox.shrink()
                      : AzmPlaceholder(icon: Icons.search_off_rounded, message: l.workoutSummaryNotFound))
                  : _SummaryBody(detail: d),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AzmSpace.pageMargin,
                AzmSpace.xs,
                AzmSpace.pageMargin,
                AzmSpace.xs,
              ),
              child: _DoneButton(label: l.workoutDone, onTap: done),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.detail});

  final WorkoutDetail detail;

  /// Start + end (forgot to open or finish on time). History, stats and PRs
  /// re-read the DB, so they follow.
  Future<void> _editTimes(BuildContext context, WidgetRef ref) async {
    final w = detail.workout;
    final end = w.endedAt;
    if (end == null) return;
    final r = await showWorkoutTimesSheet(context, start: w.startedAt, end: end, now: ref.read(workoutClockProvider));
    if (r != null) await ref.read(workoutRepositoryProvider).setTimes(w.id, start: r.start, end: r.end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final w = detail.workout;
    final unit = detail.unit;
    final lifted = detail.liftedTotalKg;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = (DateFormat.yMMMEd(locale)..useNativeDigits = false).format(w.startedAt.toLocal());
    final duration = (w.endedAt ?? DateTime.now()).difference(w.startedAt);

    final prRows = <Widget>[];
    final bestRows = <Widget>[];
    for (final e in detail.exercises) {
      final name = namesFor(context, e.exercise, e.entry.exerciseId).primary;
      for (final pr in e.prs.entries) {
        final s = e.sets[pr.key];
        prRows.add(_PrRow(
          name: name,
          types: [for (final t in PrType.values) if (pr.value.contains(t)) l.prTypeName(t)].join(' · '),
          value: l.setValueWithUnit(s, unit),
        ));
      }
      final best = bestSet(e.sets);
      if (best != null) {
        bestRows.add(_LineRow(title: name, value: l.setValueWithUnit(best, unit)));
      }
    }

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.xxxl, AzmSpace.pageMargin, AzmSpace.xl),
      children: [
        Text(l.workoutSummaryTitle, style: AzmType.stepTitle.copyWith(color: c.textPrimary)),
        const SizedBox(height: AzmSpace.xxs),
        Text('${w.name} · $date', style: AzmType.secondary.copyWith(color: c.textSecondary)),
        const SizedBox(height: AzmSpace.xl),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.workoutStatLifted, style: AzmType.statLabel.copyWith(color: c.textSecondary)),
              const SizedBox(height: AzmSpace.xs),
              LiftedCounter(
                value: Units.toDisplay(lifted, unit),
                unit: l.weightUnitLabel(unit),
                size: LiftedCounterSize.summary,
                comparison: l.comparison(lifted),
                fromZero: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AzmSpace.listGap),
        _Card(
          child: Row(
            children: [
              _Stat(label: l.workoutStatDuration, value: formatClock(duration)),
              _Stat(label: l.workoutStatSets, value: '${detail.completedSets}'),
              _Stat(label: l.workoutStatPrs, value: '${prRows.length}'),
            ],
          ),
        ),
        if (w.endedAt != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AzmPressable(
              key: const ValueKey('summaryEditTime'),
              onTap: () => _editTimes(context, ref),
              semanticLabel: l.workoutEditTimes,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, color: c.accent, size: AzmSize.icon - AzmSpace.xxs),
                    const SizedBox(width: AzmSpace.xs),
                    Text(l.workoutEditTimes, style: AzmType.controlLabel.copyWith(color: c.accent)),
                  ],
                ),
              ),
            ),
          ),
        if (prRows.isNotEmpty) ...[
          _SectionTitle(text: l.workoutSummaryPrs),
          _Card(padded: false, child: Column(children: prRows)),
        ],
        if (bestRows.isNotEmpty) ...[
          _SectionTitle(text: l.workoutSummaryBestSets),
          _Card(padded: false, child: Column(children: bestRows)),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padded = true});

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) => Container(
        padding: padded ? const EdgeInsetsDirectional.all(AzmSpace.cardPadding) : null,
        decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxs, AzmSpace.xxl, AzmSpace.xxs, AzmSpace.xs),
        child: Text(text, style: AzmType.cardTitle.copyWith(color: context.colors.textPrimary)),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AzmType.statLabel.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.opticalInset),
          Text(value, style: AzmType.rowNumber.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}

/// 🏆 exercise — PR types — the set, scaling in with the celebration curve.
class _PrRow extends StatelessWidget {
  const _PrRow({required this.name, required this.types, required this.value});

  final String name;
  final String types;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.cardPadding, vertical: AzmSpace.md),
      child: Row(
        children: [
          PrBadge(style: AzmType.rowTitle),
          const SizedBox(width: AzmSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AzmType.listTitle.copyWith(color: c.textPrimary)),
                Text(types, style: AzmType.small.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: AzmMotion.reduced(context) ? 1 : 0.6, end: 1),
            duration: AzmMotion.of(context, AzmMotion.celebrationDuration),
            curve: AzmMotion.celebration,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Text(value, style: AzmType.rowNumber.copyWith(color: c.pr)),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.cardPadding, vertical: AzmSpace.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AzmType.listTitle.copyWith(color: c.textPrimary))),
          const SizedBox(width: AzmSpace.md),
          Text(value, style: AzmType.rowNumberCompact.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.primaryButton,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AzmRadius.button)),
          child: Text(label, style: AzmType.button.copyWith(color: c.onAccent)),
        ),
      ),
    );
  }
}
