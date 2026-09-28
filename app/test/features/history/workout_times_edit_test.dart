import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/workout_time_sheet.dart';
import 'package:azm/features/history/ui/past_workout_screen.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'history_test_helpers.dart';

/// Editable workout time (PLAN §14): a finished workout's start + end from
/// the past workout menu and the summary; end after start, nothing in the
/// future; history follows.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late String w;
  // Yesterday 10:00–10:55 local.
  final y = DateTime.now().subtract(const Duration(days: 1));
  final start = DateTime(y.year, y.month, y.day, 10).toUtc();

  Future<void> pumpApp(WidgetTester tester, LanguagePref lang) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = openTestDb();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
    ]);
    await insertCatalog(db, testCatalog);
    w = await seedWorkout(db, name: 'Push', startedAt: start, exercises: {'0025': [n(60, 8)]});
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> hourWheel(WidgetTester tester, int steps) async {
    await tester.drag(find.byKey(WorkoutTimeKeys.hour), Offset(0, -44.0 * steps));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
  }

  for (final lang in [LanguagePref.en, LanguagePref.ar]) {
    testWidgets('past workout menu → Edit time: end after start, saved, history follows (${lang.name})', (tester) async {
      await pumpApp(tester, lang);
      container.read(appRouterProvider).push(AppRoutes.pastWorkoutFor(w));
      await settle(tester);
      await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('pastWorkoutEditTime')));
      await settle(tester);
      expect(find.text(lang == LanguagePref.en ? 'Edit workout time' : 'عدّل وقت التمرين'), findsOneWidget);

      // Start 10:00 → 12:00 is after the end (10:55): error, Save disabled.
      await hourWheel(tester, 2);
      expect(find.text(lang == LanguagePref.en ? 'The end must be after the start' : 'النهاية لازم تبقى بعد البداية'),
          findsOneWidget);
      await hourWheel(tester, -2);
      expect(find.byKey(WorkoutTimeKeys.error), findsNothing);

      // End 10:55 → 11:55.
      await tester.tap(find.byKey(WorkoutTimeKeys.endTab));
      await settle(tester);
      await hourWheel(tester, 1);
      await tester.tap(find.byKey(WorkoutTimeKeys.save));
      await settle(tester);
      final row = await (db.select(db.workouts)..where((x) => x.id.equals(w))).getSingle();
      expect(row.startedAt, start);
      expect(row.endedAt, start.add(const Duration(hours: 1, minutes: 55)));
      expect(find.text('Edit workout time'), findsNothing);
      await tearDownApp(tester);
    });
  }

  testWidgets('summary → Edit time moves start + end', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    container.read(appRouterProvider).go(AppRoutes.workoutSummaryFor(w));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('summaryEditTime')));
    await settle(tester);
    await hourWheel(tester, -1); // start 09:00
    await tester.tap(find.byKey(WorkoutTimeKeys.save));
    await settle(tester);
    final row = await (db.select(db.workouts)..where((x) => x.id.equals(w))).getSingle();
    expect(row.startedAt, start.subtract(const Duration(hours: 1)));
    expect(find.text('1:55:00'), findsOneWidget); // summary duration follows
    await tearDownApp(tester);
  });
}
