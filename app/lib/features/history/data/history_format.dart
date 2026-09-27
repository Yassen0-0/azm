import '../../../core/l10n/l10n.dart';

// Pure formatting and calendar helpers of the history feature (unit-tested).
// Western digits in both languages (AzmNumbers).

/// Scale suffix of a compact number.
enum CompactScale { none, thousand, million, billion }

/// A compact number: [number] (Western digits) + [scale], e.g. ("1.2", million).
typedef CompactNumber = ({String number, CompactScale scale});

/// Compact form of a big total (the all-time Lifted):
/// - below 100,000: the full integer with separators (`84,500`), so normal
///   totals stay exact;
/// - thousands: integer thousands (`450` K);
/// - millions / billions: one decimal, trailing `.0` dropped (`1.2` M, `3` M).
/// Rounding that reaches the next scale moves up (999,999 → `1` M).
CompactNumber compactNumber(double value) {
  final v = value < 0 ? 0.0 : value;
  if (v < 100000) return (number: AzmNumbers.integer(v), scale: CompactScale.none);
  final k = (v / 1000).round();
  if (k < 1000) return (number: AzmNumbers.integer(k), scale: CompactScale.thousand);
  final m = _round1(v / 1e6);
  if (m < 1000) return (number: AzmNumbers.decimal(m), scale: CompactScale.million);
  return (number: AzmNumbers.decimal(_round1(v / 1e9)), scale: CompactScale.billion);
}

double _round1(double v) => (v * 10).roundToDouble() / 10;

/// Local calendar day (midnight, local time) of a UTC timestamp. [toLocal]
/// is injectable for tests (fixed offsets).
DateTime localDay(DateTime utc, {DateTime Function(DateTime)? toLocal}) {
  final l = (toLocal ?? (d) => d.toLocal())(utc);
  return DateTime(l.year, l.month, l.day);
}

/// Groups items by the LOCAL day of [startedAt] (newest-first order kept
/// inside a day). A workout at 00:30 Cairo time belongs to that day even
/// though it is the previous day in UTC.
Map<DateTime, List<T>> groupByLocalDay<T>(
  Iterable<T> items,
  DateTime Function(T) startedAt, {
  DateTime Function(DateTime)? toLocal,
}) {
  final out = <DateTime, List<T>>{};
  for (final item in items) {
    (out[localDay(startedAt(item), toLocal: toLocal)] ??= []).add(item);
  }
  return out;
}

/// First day of the week containing [day], for a locale whose week starts on
/// [firstDayOfWeek] (0 = Sunday … 6 = Saturday, like
/// `MaterialLocalizations.firstDayOfWeekIndex`). Egypt/Arabic: Saturday.
DateTime weekStart(DateTime day, int firstDayOfWeek) {
  final d = DateTime(day.year, day.month, day.day);
  final weekday = d.weekday % 7; // Sunday = 0
  final back = (weekday - firstDayOfWeek) % 7;
  return DateTime(d.year, d.month, d.day - back);
}

/// Workouts per week for the last [weeks] weeks, OLDEST first; the last
/// entry is the current week (containing [today]).
List<({DateTime start, int count})> workoutsPerWeek(
  Iterable<DateTime> startedAtUtc, {
  required DateTime today,
  required int firstDayOfWeek,
  int weeks = 12,
  DateTime Function(DateTime)? toLocal,
}) {
  final current = weekStart(today, firstDayOfWeek);
  final starts = [
    for (var i = weeks - 1; i >= 0; i--) DateTime(current.year, current.month, current.day - 7 * i),
  ];
  final counts = {for (final s in starts) s: 0};
  for (final t in startedAtUtc) {
    final w = weekStart(localDay(t, toLocal: toLocal), firstDayOfWeek);
    if (counts.containsKey(w)) counts[w] = counts[w]! + 1;
  }
  return [for (final s in starts) (start: s, count: counts[s]!)];
}

/// Month grid for a calendar: whole weeks (rows of 7) covering [month], each
/// cell a local day or null outside the month. Columns start at
/// [firstDayOfWeek] (0 = Sunday … 6 = Saturday).
List<List<DateTime?>> monthGrid(DateTime month, int firstDayOfWeek) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final lead = (first.weekday % 7 - firstDayOfWeek) % 7;
  final cells = <DateTime?>[
    for (var i = 0; i < lead; i++) null,
    for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return [for (var r = 0; r < cells.length; r += 7) cells.sublist(r, r + 7)];
}
