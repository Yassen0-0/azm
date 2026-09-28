import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/features/history/ui/exercise_history_link_slot.dart';
import 'package:azm/features/history/ui/exercise_history_screen.dart';
import 'package:azm/features/history/ui/past_workout_screen.dart';
import 'package:azm/features/history/ui/stats_screen.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'history_test_helpers.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Text without bidi isolates / marks (numbers and names are wrapped in them).
String plain(String s) => s.replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '');

/// Text (plain) equal to [s].
Finder plainText(String s) => find.byWidgetPredicate((w) => w is Text && w.data != null && plain(w.data!) == s);

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, {LanguagePref lang = LanguagePref.en, Future<void> Function()? seed}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = openTestDb();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
    ]);
    await insertCatalog(db, testCatalog);
    if (seed != null) await seed();
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
    container.read(appRouterProvider).go(AppRoutes.history);
    await settle(tester);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  final now = DateTime.now().toUtc();

  testWidgets('empty state', (tester) async {
    await pumpApp(tester);
    expect(find.text('No workouts yet'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('list: Lifted so far, cards with PRs and best sets; calendar shows the day', (tester) async {
    late String recent;
    await pumpApp(tester, seed: () async {
      await seedWorkout(db, name: 'Push', startedAt: now.subtract(const Duration(days: 3)), exercises: {
        '0025': [n(60, 8), n(60, 8)],
      });
      recent = await seedWorkout(db, name: 'Legs', startedAt: now.subtract(const Duration(hours: 2)), exercises: {
        '0043': [warm(60, 10), n(100, 5)],
        '0025': [n(62.5, 8)],
      });
    });
    expect(find.text('Lifted so far'), findsOneWidget);
    expect(find.textContaining('2,560'), findsOneWidget); // 960 + 600 + 500 + 500
    expect(find.text('2 workouts · 5 sets'), findsOneWidget);
    expect(find.textContaining('Legs'), findsOneWidget);
    expect(find.textContaining(RegExp('^2 × .Barbell Full Squat')), findsOneWidget);
    expect(plainText('100 kg × 5'), findsOneWidget); // best set
    expect(find.textContaining('🏆 2'), findsOneWidget); // squat PR set + bench PR set

    await tester.tap(find.text('Calendar'));
    await settle(tester);
    // The latest workout day of this month is preselected (or the list hint shows).
    expect(find.textContaining('Legs'), findsWidgets);

    await tester.tap(find.text('List'));
    await settle(tester);
    await tester.tap(find.textContaining('Legs'));
    await settle(tester);
    expect(tester.widget<PastWorkoutScreen>(find.byType(PastWorkoutScreen)).workoutId, recent);
    await tearDownApp(tester);
  });

  testWidgets('past workout: keypad edit is persisted, totals recompute, delete asks first', (tester) async {
    late String w;
    await pumpApp(tester, seed: () async {
      w = await seedWorkout(db, name: 'Push', startedAt: now.subtract(const Duration(days: 1)), exercises: {
        '0025': [n(60, 8)],
      });
    });
    container.read(appRouterProvider).push(AppRoutes.pastWorkoutFor(w));
    await settle(tester);
    expect(find.byType(SetRow), findsOneWidget);
    expect(find.textContaining('480 kg'), findsOneWidget);

    // Reps cell → keypad → 1, 0 → persisted immediately.
    await tester.tap(find.descendant(of: find.byType(SetRow), matching: find.text('8')));
    await settle(tester);
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('0').last);
    await settle(tester);
    final set = (await db.select(db.workoutSets).get()).single;
    expect(set.reps, 10);
    expect(find.textContaining('600 kg'), findsOneWidget);

    // Add set: logged at once with the last values.
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Add set'));
    await settle(tester);
    expect(find.byType(SetRow), findsNWidgets(2));
    expect((await db.select(db.workoutSets).get()).where((s) => s.completedAt != null), hasLength(2));

    // Delete: confirmation first.
    await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
    await settle(tester);
    await tester.tap(find.text('Delete workout').last);
    await settle(tester);
    expect(find.text('Delete this workout?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await db.select(db.workouts).get(), hasLength(1));
    await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
    await settle(tester);
    await tester.tap(find.text('Delete workout').last);
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(await db.select(db.workouts).get(), isEmpty);
    expect(find.text('No workouts yet'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('past workout: no ✓, delete by swipe or long-press (Undo), nothing removed on leaving', (tester) async {
    late String w;
    await pumpApp(tester, seed: () async {
      w = await seedWorkout(db, name: 'Push', startedAt: now.subtract(const Duration(days: 1)), exercises: {
        '0025': [n(60, 8), n(60, 6), n(60, 5)],
      });
    });
    container.read(appRouterProvider).push(AppRoutes.pastWorkoutFor(w));
    await settle(tester);
    expect(find.byType(SetRow), findsNWidgets(3));
    // No ✓ anywhere: every set of a finished workout is done.
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    for (final row in tester.widgetList<SetRow>(find.byType(SetRow))) {
      expect(row.onToggleComplete, isNull);
    }

    // Emptying reps (keypad backspace) keeps the set: it is not silently dropped.
    final ids = await setIds(db, w, '0025');
    await tester.tap(find.byKey(ValueKey('set-reps-${ids[2]}')));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Delete digit'));
    await settle(tester);
    expect((await db.select(db.workoutSets).get()).firstWhere((s) => s.id == ids[2]).reps, 0);
    await tester.tap(find.bySemanticsLabel('Close keypad'));
    await settle(tester);

    // Swipe toward the START edge (left in English) deletes that one set;
    // Undo puts it back; a second swipe deletes it for good.
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[1]}')), const Offset(600, 0));
    await settle(tester);
    expect(find.byType(SetRow), findsNWidgets(3)); // toward the end: nothing
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[1]}')), const Offset(-600, 0));
    await settle(tester);
    expect(find.byType(SetRow), findsNWidgets(2));
    expect((await db.select(db.workoutSets).get()).map((s) => s.id).toSet(), {ids[0], ids[2]});
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.byType(SetRow), findsNWidgets(3));
    expect((await db.select(db.workoutSets).get()).map((s) => s.id).toSet(), ids.toSet());
    await tester.longPress(find.byKey(SetRow.rowKey(ids[1])));
    await settle(tester);
    await tester.tap(find.byKey(SetRow.menuDeleteKey));
    await settle(tester);
    expect(find.byType(SetRow), findsNWidgets(2));
    expect((await db.select(db.workoutSets).get()).map((s) => s.id).toSet(), {ids[0], ids[2]});

    // Leave and come back: the 0-rep set is still there, all sets still done.
    container.read(appRouterProvider).pop();
    await settle(tester);
    container.read(appRouterProvider).push(AppRoutes.pastWorkoutFor(w));
    await settle(tester);
    final rows = await db.select(db.workoutSets).get();
    expect(rows.map((s) => s.id).toSet(), {ids[0], ids[2]});
    expect(rows.every((s) => s.completedAt != null), isTrue);
    expect(find.byType(SetRow), findsNWidgets(2));
    await tearDownApp(tester);
  });

  testWidgets('Arabic: rename from the menu, RTL labels', (tester) async {
    late String w;
    await pumpApp(tester, lang: LanguagePref.ar, seed: () async {
      w = await seedWorkout(db, name: 'Push', startedAt: now.subtract(const Duration(days: 1)), exercises: {
        '0025': [n(60, 8)],
      });
    });
    expect(find.text('شِلت لحد دلوقتي'), findsOneWidget);
    container.read(appRouterProvider).push(AppRoutes.pastWorkoutFor(w));
    await settle(tester);
    await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
    await settle(tester);
    await tester.tap(find.text('غيّر الاسم'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'صدر وتراي');
    await tester.tap(find.text('حفظ'));
    await settle(tester);
    expect((await db.select(db.workouts).getSingle()).name, 'صدر وتراي');
    await tearDownApp(tester);
  });

  testWidgets('stats: totals, this week, records → exercise detail', (tester) async {
    await pumpApp(tester, seed: () async {
      await seedWorkout(db, startedAt: now.subtract(const Duration(minutes: 90)), exercises: {'0025': [n(60, 8)]});
      await seedWorkout(db, startedAt: now.subtract(const Duration(days: 30)), exercises: {'0043': [n(100, 5)]});
    });
    container.read(appRouterProvider).push(AppRoutes.stats);
    await settle(tester);
    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.text('This week: 1 workout'), findsOneWidget);
    expect(find.text('Personal records'), findsOneWidget);
    expect(find.textContaining('Barbell Bench Press'), findsOneWidget);
    expect(plainText('76 kg'), findsOneWidget); // e1RM 60×(1+8/30)
    await tearDownApp(tester);
  });

  testWidgets('"See all history" only above 10 sessions; opens the full list', (tester) async {
    Future<void> seedSessions(int count) async {
      for (var i = 0; i < count; i++) {
        await seedWorkout(db, startedAt: now.subtract(Duration(days: count - i)), exercises: {'0025': [n(50.0 + i, 5)]});
      }
    }

    await pumpApp(tester, seed: () => seedSessions(10));
    container.read(appRouterProvider).push(AppRoutes.exercise('0025'));
    await settle(tester);
    expect(find.byKey(ExerciseHistoryLinkSlot.linkKey), findsNothing);
    await seedSessions(1);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(ExerciseHistoryLinkSlot.linkKey),
      300,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    expect(find.text('See all history (11)'), findsOneWidget);
    await tester.tap(find.byKey(ExerciseHistoryLinkSlot.linkKey));
    await settle(tester);
    expect(find.byType(ExerciseHistoryScreen), findsOneWidget);
    expect(find.text('11 workouts'), findsOneWidget);
    await tearDownApp(tester);
  });
}
