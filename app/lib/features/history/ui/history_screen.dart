import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/azm_tab_page.dart';
import '../../settings/data/training_settings.dart';
import '../data/history_format.dart';
import '../data/history_models.dart';
import '../data/history_repository.dart';
import 'history_calendar.dart';
import 'history_text.dart';
import 'history_widgets.dart';
import 'history_workout_card.dart';

enum HistoryView { list, calendar }

/// History tab: all-time Lifted header (+ Stats entry), list ↔ calendar of
/// finished workouts, empty state. Everything is derived from the DB stream
/// ([historyProvider]), so edits and deletes show up immediately.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  /// Keys for tests / screenshots.
  static const statsKey = ValueKey('historyOpenStats');

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryView _view = HistoryView.list;
  DateTime? _month; // local, first of month
  DateTime? _selected; // local day

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(historyProvider);
    final data = async.value;
    final exercises = ref.watch(historyExercisesProvider).value ?? const {};
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;

    final Widget body;
    if (data == null) {
      body = const SizedBox.shrink();
    } else if (data.isEmpty) {
      body = HistoryEmpty(icon: Icons.history_rounded, title: l.historyEmptyTitle, body: l.historyEmptyBody);
    } else {
      body = ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.xs, AzmSpace.pageMargin, AzmSpace.xxxl),
        children: [
          _LiftedHeader(data: data, unit: unit),
          const SizedBox(height: AzmSpace.listGap),
          HistorySegmented<HistoryView>(
            options: [
              (value: HistoryView.list, label: l.historyViewList),
              (value: HistoryView.calendar, label: l.historyViewCalendar),
            ],
            selected: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
          if (_view == HistoryView.list)
            ..._list(context, data, exercises, unit)
          else
            ..._calendar(context, data, exercises, unit),
        ],
      );
    }
    return AzmTabPage(title: l.shellTabHistory, body: body);
  }

  List<Widget> _list(BuildContext context, HistoryData data, Map<String, Exercise> exercises, WeightUnit unit) {
    final out = <Widget>[];
    DateTime? month;
    for (final w in data.workouts) {
      final d = localDay(w.startedAt);
      final m = DateTime(d.year, d.month);
      if (m != month) {
        month = m;
        out.add(HistorySectionTitle(HistoryDates.month(context, m), top: out.isEmpty ? AzmSpace.xl : AzmSpace.xxl));
      } else {
        out.add(const SizedBox(height: AzmSpace.listGap));
      }
      out.add(HistoryWorkoutCard(key: ValueKey(w.id), workout: w, exercises: exercises, unit: unit));
    }
    return out;
  }

  List<Widget> _calendar(BuildContext context, HistoryData data, Map<String, Exercise> exercises, WeightUnit unit) {
    final l = context.l10n;
    final byDay = groupByLocalDay(data.workouts, (w) => w.startedAt);
    final today = localDay(DateTime.now().toUtc());
    final month = _month ?? DateTime(today.year, today.month);
    // Default selection: the latest day with workouts in the shown month.
    final selected = _selected ??
        (byDay.keys.where((d) => d.year == month.year && d.month == month.month).toList()..sort()).lastOrNull;
    final dayWorkouts = selected == null ? const <HistoryWorkout>[] : (byDay[selected] ?? const []);

    return [
      const SizedBox(height: AzmSpace.listGap),
      HistoryCard(
        child: HistoryMonthCalendar(
          month: month,
          byDay: byDay,
          selected: selected,
          today: today,
          title: HistoryDates.month(context, month),
          onSelect: (d) => setState(() => _selected = d),
          onMonth: (delta) => setState(() {
            _month = DateTime(month.year, month.month + delta);
            _selected = null;
          }),
        ),
      ),
      if (selected == null)
        _Hint(l.historyPickDay)
      else ...[
        HistorySectionTitle(HistoryDates.longDay(context, selected), top: AzmSpace.xxl),
        if (dayWorkouts.isEmpty) _Hint(l.historyDayEmpty, top: 0),
        for (final (i, w) in dayWorkouts.indexed) ...[
          if (i > 0) const SizedBox(height: AzmSpace.listGap),
          HistoryWorkoutCard(key: ValueKey(w.id), workout: w, exercises: exercises, unit: unit),
        ],
      ],
    ];
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.top = AzmSpace.xxl});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.only(top: top, start: AzmSpace.xxs, end: AzmSpace.xxs),
        child: Text(text, style: AzmType.secondary.copyWith(color: context.colors.textSecondary)),
      );
}

/// "Lifted so far" + compact all-time total, workout/set counts, Stats entry.
class _LiftedHeader extends StatelessWidget {
  const _LiftedHeader({required this.data, required this.unit});

  final HistoryData data;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return HistoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.historyLiftedSoFar, style: AzmType.statLabel.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.xxs),
          CompactLiftedNumber(kg: data.liftedKg, unit: unit),
          const SizedBox(height: AzmSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l.workoutCount(data.workouts.length)} · ${l.setCount(data.setCount)}',
                  style: AzmType.secondary.copyWith(color: c.textSecondary),
                ),
              ),
              AzmPressable(
                key: HistoryScreen.statsKey,
                onTap: () => context.push(AppRoutes.stats),
                semanticLabel: l.historyOpenStats,
                child: ExcludeSemantics(
                  child: Container(
                    height: AzmSize.headerButton,
                    padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.md, 0, AzmSpace.xs, 0),
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AzmRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_rounded, size: AzmSize.icon - AzmSpace.xxs, color: c.accent),
                        const SizedBox(width: AzmSpace.xxs),
                        Text(l.historyOpenStats, style: AzmType.pillLabel.copyWith(color: c.accent)),
                        // Directional: mirrors in RTL.
                        Icon(Icons.chevron_right_rounded, size: AzmSize.icon - AzmSpace.xxs, color: c.accent),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
