import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/features/history/data/history_format.dart';
import 'package:azm/features/history/ui/history_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compact Lifted formatting', () {
    test('keeps normal totals exact, compacts big ones', () {
      expect(compactNumber(0), (number: '0', scale: CompactScale.none));
      expect(compactNumber(8450), (number: '8,450', scale: CompactScale.none));
      expect(compactNumber(99999.4), (number: '99,999', scale: CompactScale.none));
      expect(compactNumber(100000), (number: '100', scale: CompactScale.thousand));
      expect(compactNumber(450400), (number: '450', scale: CompactScale.thousand));
      expect(compactNumber(1234567), (number: '1.2', scale: CompactScale.million));
      expect(compactNumber(3000000), (number: '3', scale: CompactScale.million));
      expect(compactNumber(2.46e9), (number: '2.5', scale: CompactScale.billion));
    });

    test('rounding that reaches the next scale moves up', () {
      expect(compactNumber(999600), (number: '1', scale: CompactScale.million));
      expect(compactNumber(999960000), (number: '1', scale: CompactScale.billion));
    });

    test('Arabic and English wording, Western digits in both', () {
      final ar = lookupAppLocalizations(AzmLocales.ar);
      final en = lookupAppLocalizations(AzmLocales.en);
      expect(ar.compact(1200000), '1.2 مليون');
      expect(en.compact(1200000), '1.2M');
      expect(ar.compact(450000), '450 ألف');
      expect(en.compact(450000), '450K');
      expect(ar.compact(84500), '84,500');
      expect(ar.historyLiftedSoFar, 'شِلت لحد دلوقتي');
      expect(en.historyLiftedSoFar, 'Lifted so far');
      for (final s in [ar.compact(1234567890), ar.duration(const Duration(minutes: 75))]) {
        expect(RegExp('[٠-٩]').hasMatch(s), isFalse, reason: s);
      }
      expect(ar.duration(const Duration(minutes: 75)), '1 س 15 د');
      expect(en.duration(const Duration(minutes: 55)), '55 min');
    });
  });

  group('calendar', () {
    // Cairo in summer is UTC+3; a fixed offset keeps the test independent of the host TZ.
    DateTime cairo(DateTime utc) => utc.add(const Duration(hours: 3));

    test('groups by LOCAL day, not UTC day', () {
      final items = [
        DateTime.utc(2026, 9, 25, 21, 30), // 00:30 on the 26th in Cairo
        DateTime.utc(2026, 9, 26, 15),
        DateTime.utc(2026, 9, 25, 20, 59), // 23:59 on the 25th in Cairo
      ];
      final g = groupByLocalDay(items, (d) => d, toLocal: cairo);
      expect(g.keys, unorderedEquals([DateTime(2026, 9, 26), DateTime(2026, 9, 25)]));
      expect(g[DateTime(2026, 9, 26)], [items[0], items[1]]);
      expect(g[DateTime(2026, 9, 25)], [items[2]]);
    });

    test('week starts per locale (Saturday for Arabic, Sunday for English)', () {
      final wed = DateTime(2026, 9, 30); // a Wednesday
      expect(weekStart(wed, 6), DateTime(2026, 9, 26)); // Saturday
      expect(weekStart(wed, 0), DateTime(2026, 9, 27)); // Sunday
      expect(weekStart(DateTime(2026, 9, 26), 6), DateTime(2026, 9, 26));
      expect(weekStart(DateTime(2026, 9, 26), 0), DateTime(2026, 9, 20));
    });

    test('month grid covers whole weeks and starts on the locale week day', () {
      // September 2026 starts on a Tuesday and has 30 days.
      final sat = monthGrid(DateTime(2026, 9, 15), 6);
      expect(sat.first.take(3), [null, null, null]); // Sat, Sun, Mon
      expect(sat.first[3], DateTime(2026, 9, 1));
      expect(sat.every((w) => w.length == 7), isTrue);
      expect(sat.expand((w) => w).whereType<DateTime>().length, 30);
      final sun = monthGrid(DateTime(2026, 9, 15), 0);
      expect(sun.first[2], DateTime(2026, 9, 1));
      expect(sun.last.whereType<DateTime>().last, DateTime(2026, 9, 30));
    });
  });

  group('stats per week', () {
    test('counts workouts per local week, oldest first, current week last', () {
      DateTime utc(int d, [int h = 12]) => DateTime.utc(2026, 9, d, h);
      final weeks = workoutsPerWeek(
        [utc(26), utc(28), utc(30), utc(20), utc(1), utc(25, 22)], // 25th 22:00 UTC = 26th in Cairo
        today: DateTime(2026, 9, 30),
        firstDayOfWeek: 6,
        weeks: 3,
        toLocal: (d) => d.add(const Duration(hours: 3)),
      );
      expect([for (final w in weeks) w.start], [DateTime(2026, 9, 12), DateTime(2026, 9, 19), DateTime(2026, 9, 26)]);
      expect([for (final w in weeks) w.count], [0, 1, 4]);
    });
  });
}
