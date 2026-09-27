import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../data/history_format.dart';
import '../data/history_models.dart';
import 'history_text.dart';

/// Month grid (DESIGN: weekday letters in `dayLabel`). The week starts per
/// locale (`MaterialLocalizations.firstDayOfWeekIndex`: Saturday in Arabic,
/// Sunday in English). Days with workouts get an `accentSoft` disc; the
/// selected day an `accent` disc. Columns follow reading direction, so the
/// grid mirrors in RTL.
class HistoryMonthCalendar extends StatelessWidget {
  const HistoryMonthCalendar({
    super.key,
    required this.month,
    required this.byDay,
    required this.selected,
    required this.today,
    required this.onSelect,
    required this.onMonth,
    required this.title,
  });

  /// Any day in the shown month (local).
  final DateTime month;

  /// Local day → its workouts.
  final Map<DateTime, List<HistoryWorkout>> byDay;
  final DateTime? selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  /// −1 / +1 month.
  final ValueChanged<int> onMonth;

  /// "September 2026".
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final ml = MaterialLocalizations.of(context);
    final first = ml.firstDayOfWeekIndex;
    final grid = monthGrid(month, first);

    return Column(
      children: [
        Row(
          children: [
            // chevron_left mirrors in RTL (matchTextDirection): "previous"
            // always points to the start edge.
            AzmHeaderButton(icon: Icons.chevron_left_rounded, semanticLabel: l.historyPrevMonth, onTap: () => onMonth(-1)),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AzmType.cardTitle.copyWith(color: c.textPrimary),
              ),
            ),
            AzmHeaderButton(icon: Icons.chevron_right_rounded, semanticLabel: l.historyNextMonth, onTap: () => onMonth(1)),
          ],
        ),
        const SizedBox(height: AzmSpace.xs),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  ml.narrowWeekdays[(first + i) % 7],
                  textAlign: TextAlign.center,
                  style: AzmType.dayLabel.copyWith(color: c.weekLabel),
                ),
              ),
          ],
        ),
        const SizedBox(height: AzmSpace.xxs),
        for (final week in grid)
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: day == null
                      ? const SizedBox(height: AzmSize.dayPicker)
                      : _DayCell(
                          day: day,
                          count: byDay[day]?.length ?? 0,
                          selected: day == selected,
                          today: day == today,
                          onTap: () => onSelect(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final has = count > 0;
    final bg = selected ? c.accent : (has ? c.accentSoft : null);
    final fg = selected ? c.onAccent : (has ? c.accent : (today ? c.textPrimary : c.textSecondary));
    final label = HistoryDates.longDay(context, day);
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: has ? '$label · ${context.l10n.historyStatWorkouts} ${AzmNumbers.integer(count)}' : label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: AzmSize.dayPicker,
          child: Center(
            child: AnimatedContainer(
              duration: AzmMotion.of(context, AzmMotion.micro),
              curve: AzmMotion.standard,
              width: AzmSize.headerButton,
              height: AzmSize.headerButton,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: today && !selected ? Border.all(color: c.accent, width: AzmGlass.borderWidth) : null,
              ),
              child: Text(
                AzmNumbers.integer(day.day),
                style: (has || today ? AzmType.smallStrong : AzmType.small).copyWith(color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
