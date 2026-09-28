import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// Sheets that change a workout's times (the user forgot to open the app on
/// time). Wheels for day · hour · minute (24 h, Western digits); nothing may
/// be in the future, and an end must come after its start. The caller writes
/// the result to the DB (WorkoutRepository.setStartedAt / setTimes).

/// Running workout: pick a new START. Returns it (UTC), or null if dismissed.
Future<DateTime?> showWorkoutStartSheet(
  BuildContext context, {
  required DateTime start,
  required DateTime Function() now,
  String? hint,
}) =>
    showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _TimesSheet(start: start, end: null, now: now, hint: hint),
    );

/// Finished workout: START and END. Returns both (UTC), or null if dismissed.
Future<({DateTime start, DateTime end})?> showWorkoutTimesSheet(
  BuildContext context, {
  required DateTime start,
  required DateTime end,
  required DateTime Function() now,
}) async {
  final r = await showModalBottomSheet<Object>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _TimesSheet(start: start, end: end, now: now),
  );
  return r is ({DateTime start, DateTime end}) ? r : null;
}

/// `1:05:09` / `12:30` for a duration (Western digits).
String formatWorkoutDuration(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  String two(int v) => v.toString().padLeft(2, '0');
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}

/// Keys for tests.
abstract final class WorkoutTimeKeys {
  static const save = ValueKey('workoutTimeSave');
  static const startTab = ValueKey('workoutTimeStartTab');
  static const endTab = ValueKey('workoutTimeEndTab');
  static const day = ValueKey('workoutTimeDay');
  static const hour = ValueKey('workoutTimeHour');
  static const minute = ValueKey('workoutTimeMinute');
  static const error = ValueKey('workoutTimeError');
}

class _TimesSheet extends StatefulWidget {
  const _TimesSheet({required this.start, required this.end, required this.now, this.hint});

  final DateTime start;
  final DateTime? end;
  final DateTime Function() now;
  final String? hint;

  @override
  State<_TimesSheet> createState() => _TimesSheetState();
}

class _TimesSheetState extends State<_TimesSheet> {
  late DateTime _start = widget.start.toLocal();
  late DateTime? _end = widget.end?.toLocal();
  bool _editingEnd = false;

  bool get _hasEnd => widget.end != null;

  String? _error(AppLocalizations l, DateTime now) {
    if (_start.isAfter(now) || (_end?.isAfter(now) ?? false)) return l.commonTimeFuture;
    if (_end != null && !_start.isBefore(_end!)) return l.commonTimeOrder;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final now = widget.now().toLocal();
    final error = _error(l, now);
    final value = _editingEnd ? _end! : _start;
    final duration = (_end ?? now).difference(_start);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _hasEnd ? l.commonTimeEditTitle : l.commonTimeStartTitle,
              style: AzmType.cardTitle.copyWith(color: c.textPrimary),
            ),
            if (widget.hint != null) ...[
              const SizedBox(height: AzmSpace.xxs),
              Text(widget.hint!, style: AzmType.secondary.copyWith(color: c.textSecondary)),
            ],
            const SizedBox(height: AzmSpace.md),
            if (_hasEnd)
              Row(
                children: [
                  Expanded(
                    child: _Tab(
                      key: WorkoutTimeKeys.startTab,
                      label: l.commonTimeStart,
                      value: _stamp(context, _start),
                      selected: !_editingEnd,
                      onTap: () => setState(() => _editingEnd = false),
                    ),
                  ),
                  const SizedBox(width: AzmSpace.xs),
                  Expanded(
                    child: _Tab(
                      key: WorkoutTimeKeys.endTab,
                      label: l.commonTimeEnd,
                      value: _stamp(context, _end!),
                      selected: _editingEnd,
                      onTap: () => setState(() => _editingEnd = true),
                    ),
                  ),
                ],
              ),
            if (_hasEnd) const SizedBox(height: AzmSpace.xs),
            _Wheels(
              // Re-create the wheels when switching start ⇄ end.
              key: ValueKey(_editingEnd),
              value: value,
              first: _firstDay(now),
              last: DateTime(now.year, now.month, now.day),
              onChanged: (v) => setState(() => _editingEnd ? _end = v : _start = v),
            ),
            const SizedBox(height: AzmSpace.xs),
            Text(
              error ?? l.commonTimeDuration(formatWorkoutDuration(duration)),
              key: error == null ? null : WorkoutTimeKeys.error,
              textAlign: TextAlign.center,
              style: AzmType.secondaryStrong.copyWith(color: error == null ? c.textSecondary : c.destructiveText),
            ),
            const SizedBox(height: AzmSpace.md),
            AzmPressable(
              key: WorkoutTimeKeys.save,
              onTap: error == null ? _save : null,
              semanticLabel: l.commonTimeSave,
              child: ExcludeSemantics(
                child: Container(
                  height: AzmSize.buttonCompact,
                  alignment: AlignmentDirectional.center,
                  decoration: BoxDecoration(
                    color: error == null ? c.accent : c.actionDisabled,
                    borderRadius: BorderRadius.circular(AzmRadius.button),
                  ),
                  child: Text(
                    l.commonTimeSave,
                    style: AzmType.button.copyWith(color: error == null ? c.onAccent : c.textTertiary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Oldest day on the wheel: 30 days back, or a week before the workout's
  /// original start when that is older.
  DateTime _firstDay(DateTime now) {
    final monthBack = DateTime(now.year, now.month, now.day - 30);
    final s = widget.start.toLocal();
    final weekBefore = DateTime(s.year, s.month, s.day - 7);
    return weekBefore.isBefore(monthBack) ? weekBefore : monthBack;
  }

  void _save() {
    final start = _start.toUtc();
    if (_hasEnd) {
      Navigator.pop(context, (start: start, end: _end!.toUtc()));
    } else {
      Navigator.pop(context, start);
    }
  }
}

String _stamp(BuildContext context, DateTime local) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  return (DateFormat.MMMd(tag).add_Hm()..useNativeDigits = false).format(local);
}

class _Tab extends StatelessWidget {
  const _Tab({super.key, required this.label, required this.value, required this.selected, required this.onTap});

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$label $value',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: AzmSize.touchCompact),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md, vertical: AzmSpace.xxs),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.fill,
            borderRadius: BorderRadius.circular(AzmRadius.input),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: AzmType.small.copyWith(color: selected ? c.accent : c.textSecondary)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AzmType.controlLabel.copyWith(color: c.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Day · hour · minute wheels. Hour and minute always read `hh : mm`
/// (digits are left-to-right in Arabic too); the day wheel sits at the start.
class _Wheels extends StatefulWidget {
  const _Wheels({super.key, required this.value, required this.first, required this.last, required this.onChanged});

  final DateTime value;
  final DateTime first;
  final DateTime last;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_Wheels> createState() => _WheelsState();
}

class _WheelsState extends State<_Wheels> {
  late int _day = _dayIndex(widget.value);
  late int _hour = widget.value.hour;
  late int _minute = widget.value.minute;
  late final _dayCtl = FixedExtentScrollController(initialItem: _day);
  late final _hourCtl = FixedExtentScrollController(initialItem: _hour);
  late final _minuteCtl = FixedExtentScrollController(initialItem: _minute);

  int get _days => DateUtils.dateOnly(widget.last).difference(DateUtils.dateOnly(widget.first)).inDays + 1;

  int _dayIndex(DateTime v) =>
      DateUtils.dateOnly(v).difference(DateUtils.dateOnly(widget.first)).inDays.clamp(0, _days - 1);

  DateTime _dayAt(int i) => DateTime(widget.first.year, widget.first.month, widget.first.day + i);

  @override
  void dispose() {
    _dayCtl.dispose();
    _hourCtl.dispose();
    _minuteCtl.dispose();
    super.dispose();
  }

  void _emit() {
    final d = _dayAt(_day);
    widget.onChanged(DateTime(d.year, d.month, d.day, _hour, _minute));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final tag = Localizations.localeOf(context).toLanguageTag();
    final dayFormat = DateFormat.MMMEd(tag)..useNativeDigits = false;
    final style = AzmType.rowNumberCompact.copyWith(color: c.textPrimary);
    String two(int v) => v.toString().padLeft(2, '0');

    Widget wheel({
      required Key key,
      required String label,
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) text,
      required ValueChanged<int> onSelected,
    }) =>
        Semantics(
          label: label,
          child: CupertinoPicker.builder(
            key: key,
            scrollController: controller,
            itemExtent: AzmSize.touchCompact,
            onSelectedItemChanged: (i) {
              onSelected(i);
              _emit();
            },
            childCount: count,
            itemBuilder: (_, i) => Center(child: Text(text(i), style: style, maxLines: 1)),
          ),
        );

    final lastIndex = _days - 1;
    final hour = wheel(
      key: WorkoutTimeKeys.hour,
      label: l.commonTimeHour,
      controller: _hourCtl,
      count: 24,
      text: two,
      onSelected: (i) => _hour = i,
    );
    final minute = wheel(
      key: WorkoutTimeKeys.minute,
      label: l.commonTimeMinute,
      controller: _minuteCtl,
      count: 60,
      text: two,
      onSelected: (i) => _minute = i,
    );
    // hh : mm keeps its reading order in both languages (like the digits).
    final rtl = AlignmentDirectional.centerStart.resolve(Directionality.of(context)).x > 0;
    final colon = Text(':', style: style);
    final time = rtl
        ? [Expanded(child: minute), colon, Expanded(child: hour)]
        : [Expanded(child: hour), colon, Expanded(child: minute)];

    return SizedBox(
      height: AzmSize.touchCompact * 4,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: wheel(
              key: WorkoutTimeKeys.day,
              label: l.commonTimeDay,
              controller: _dayCtl,
              count: _days,
              text: (i) => i == lastIndex
                  ? l.commonTimeToday
                  : i == lastIndex - 1
                      ? l.commonTimeYesterday
                      : dayFormat.format(_dayAt(i)),
              onSelected: (i) => _day = i,
            ),
          ),
          const SizedBox(width: AzmSpace.xs),
          ...time,
        ],
      ),
    );
  }
}
