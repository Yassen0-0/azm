// Parity screenshots of the history feature (CLAUDE.md → Platform Parity Rule).
//   AZM_DEVICE_SET=B tools/screenshots.sh history
// Seeds the ON-DEVICE database of the dedicated test emulator/simulator:
// step 1 wipes all workouts (empty state), step 2 writes 8 weeks of finished
// Upper/Lower workouts (3 a week, progressive weights → PRs, warm-up and drop
// sets, 16 bench sessions so the exercise detail offers "See all history").
import 'dart:async';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/features/history/ui/exercise_history_link_slot.dart';
import 'package:azm/features/history/ui/history_workout_card.dart';
import 'package:azm/features/history/ui/past_workout_screen.dart';
import 'package:azm/features/history/ui/stats_screen.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

AppLocalizations _l10n(ProviderContainer c) =>
    lookupAppLocalizations(c.read(appSettingsProvider).forcedLocale ?? AzmLocales.en);

bool _ar(ProviderContainer c) => _l10n(c).localeName == 'ar';

Future<void> _wipe(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await db.delete(db.workouts).go(); // cascades to exercises + sets
}

typedef _Set = (double kg, int reps, SetType type);

/// id of the most recent seeded workout (for the detail screens).
String? _latest;

Future<void> _seed(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await _wipe(c);
  // One transaction: the History tab sees the whole seed in one emission.
  await db.transaction(() => _seedRows(c, db));
}

Future<void> _seedRows(ProviderContainer c, AppDatabase db) async {
  final ar = _ar(c);
  final today = DateTime.now();

  Future<String> workout(DateTime localStart, String name, Duration length, Map<String, List<_Set>> exercises) async {
    final id = newUuid();
    final start = localStart.toUtc();
    await db.into(db.workouts).insert(WorkoutsCompanion.insert(
          id: Value(id),
          name: name,
          startedAt: Value(start),
          endedAt: Value(start.add(length)),
          status: const Value(WorkoutStatus.finished),
        ));
    var sort = 0;
    for (final e in exercises.entries) {
      final weId = newUuid();
      await db.into(db.workoutExercises).insert(
            WorkoutExercisesCompanion.insert(id: Value(weId), workoutId: id, exerciseId: e.key, sort: Value(sort++)),
          );
      for (var i = 0; i < e.value.length; i++) {
        final s = e.value[i];
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              workoutExerciseId: weId,
              sort: Value(i),
              type: Value(s.$3),
              weightKg: Value(s.$1),
              reps: Value(s.$2),
              completedAt: Value(start.add(Duration(minutes: 4 * (sort * 4 + i + 1)))),
            ));
      }
    }
    return id;
  }

  _Set n(double kg, int reps) => (kg, reps, SetType.normal);
  _Set w(double kg, int reps) => (kg, reps, SetType.warmup);
  _Set d(double kg, int reps) => (kg, reps, SetType.drop);

  // 24 workouts, oldest first: days ago = 1 + 7i + {4, 2, 0}.
  final ages = [for (var i = 7; i >= 0; i--) ...[1 + 7 * i + 4, 1 + 7 * i + 2, 1 + 7 * i]];
  var upper = 0, lower = 0;
  for (final (j, age) in ages.indexed) {
    final day = DateTime(today.year, today.month, today.day - age, 18, 30);
    final isLower = j % 3 == 1;
    if (isLower) {
      final p = 2.5 * lower++;
      await workout(day, ar ? 'تمرين سفلي' : 'Lower body', Duration(minutes: 62 + j % 7), {
        '0043': [w(60, 8), n(90 + p, 5), n(90 + p, 5), n(90 + p, 5)],
        '0085': [n(70 + p, 8), n(70 + p, 8), n(70 + p, 8)],
        '0739': [n(160 + 2 * p, 10), n(160 + 2 * p, 10), n(160 + 2 * p, 10)],
        '0605': [n(50, 12), n(50, 12), n(50, 12)],
      });
    } else {
      final p = 1.25 * upper++;
      _latest = await workout(day, ar ? 'تمرين علوي' : 'Upper body', Duration(minutes: 51 + j % 9), {
        '0025': [w(40, 12), n(60 + p, 8), n(60 + p, 8), n(60 + p, 7)],
        '0027': [n(55 + p, 10), n(55 + p, 10), n(55 + p, 9)],
        '0405': [n(18, 10), n(18, 10), n(18, 9)],
        '0294': [n(12.5, 12), n(12.5, 10), d(8, 12)],
      });
    }
  }
}

Future<void> _open(WidgetTester tester, GoRouter router, String location) async {
  unawaited(router.push(location));
  await _pumpFor(tester);
}

Future<void> _waitFor(WidgetTester tester, Finder f, {int maxMs = 20000}) async {
  for (var t = 0; t < maxMs && f.evaluate().isEmpty; t += 100) {
    await _pumpFor(tester, 100);
  }
  expect(f, findsWidgets);
}

Future<void> _reveal(WidgetTester tester, Finder f) async {
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.1);
  await _pumpFor(tester, 400);
}

void main() {
  runScreenshotSuite('history', [
    ScreenStep('empty', (tester, c, router) async {
      await _wipe(c);
      router.go(AppRoutes.history);
    }),
    ScreenStep('list', (tester, c, router) async {
      await _seed(c);
      router.go(AppRoutes.history);
      // The first emission after a big seed can take seconds on a loaded
      // emulator: wait (max 20 s) until the cards are there.
      await _waitFor(tester, find.byType(HistoryWorkoutCard));
    }),
    ScreenStep('calendar', (tester, c, router) async {
      await tester.tap(find.text(_l10n(c).historyViewCalendar));
    }),
    ScreenStep('past_workout', (tester, c, router) => _open(tester, router, AppRoutes.pastWorkoutFor(_latest!))),
    ScreenStep('past_workout_keypad', (tester, c, router) async {
      await _open(tester, router, AppRoutes.pastWorkoutFor(_latest!));
      // Reps of the first working bench set.
      final row = find.byType(SetRow).at(1);
      await tester.tap(find.descendant(of: row, matching: find.text('8')).last);
    }),
    ScreenStep('past_workout_menu', (tester, c, router) async {
      await _open(tester, router, AppRoutes.pastWorkoutFor(_latest!));
      await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
    }),
    ScreenStep('delete_confirm', (tester, c, router) async {
      await _open(tester, router, AppRoutes.pastWorkoutFor(_latest!));
      await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
      await _pumpFor(tester);
      await tester.tap(find.text(_l10n(c).historyDeleteWorkout).last);
      // Sheet out, then dialog in: give a slow emulator time for both.
      await _pumpFor(tester, 1500);
    }),
    ScreenStep('stats', (tester, c, router) => _open(tester, router, AppRoutes.stats)),
    ScreenStep('stats_records', (tester, c, router) async {
      await _open(tester, router, AppRoutes.stats);
      await _reveal(tester, find.byKey(StatsScreen.recordsKey));
    }),
    ScreenStep('exercise_detail_see_all', (tester, c, router) async {
      await _open(tester, router, AppRoutes.exercise('0025'));
      // The detail is a lazy list: scroll until the slot is built.
      await tester.scrollUntilVisible(
        find.byKey(ExerciseHistoryLinkSlot.linkKey),
        400,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
      );
      await Scrollable.ensureVisible(tester.element(find.byKey(ExerciseHistoryLinkSlot.linkKey)), alignment: 0.8);
    }),
    ScreenStep('exercise_history', (tester, c, router) => _open(tester, router, AppRoutes.exerciseHistoryFor('0025'))),
  ]);
}
