import 'dart:async';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/features/exercises/ui/exercise_detail_screen.dart';
import 'package:azm/features/exercises/ui/exercise_progress_chart.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

void main() {
  late AppDatabase db;

  setUp(() async => db = await openCatalogDb());
  tearDown(() => db.close());

  Future<void> openDetail(WidgetTester tester, String id, LanguagePref lang) async {
    useTallScreen(tester);
    final container = await pumpAzm(tester, db, lang);
    unawaited(container.read(appRouterProvider).push(AppRoutes.exercise(id)));
    await settle(tester);
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200, scrollable: find.descendant(of: find.byType(ExerciseDetailScreen), matching: find.byType(Scrollable)).first);
    await settle(tester);
  }

  testWidgets('without history: names, muscles, fallback media, empty states', (tester) async {
    await openDetail(tester, '0025', LanguagePref.en);
    expect(find.text(isolateName('Barbell Bench Press')), findsWidgets); // header + title
    expect(find.text(isolateName('ضغط بار مستوي')), findsOneWidget);
    expect(find.text('Target muscle'), findsOneWidget);
    expect(find.text('Chest'), findsWidgets);
    expect(find.text('Barbell'), findsOneWidget);
    // No media configured in tests → fallback icon, and NO attribution line.
    expect(find.byIcon(Icons.fitness_center_rounded), findsWidgets);
    expect(find.textContaining('Gym visual'), findsNothing);
    // Records show the grey dash, never 0.
    expect(find.text('—'), findsNWidgets(3));
    await scrollTo(tester, find.text('The chart appears after at least two workouts.'));
    await scrollTo(tester, find.textContaining("You haven't done this exercise yet"));
    await scrollTo(tester, find.text('How to do it'));
  });

  testWidgets('Arabic UI: Arabic names first, instructions fall back to English with a note', (tester) async {
    await openDetail(tester, '0025', LanguagePref.ar);
    expect(find.text('العضلة الأساسية'), findsOneWidget);
    expect(find.text('صدر'), findsWidgets);
    await scrollTo(tester, find.text('الشرح بالإنجليزي بس لحد دلوقتي.'));
  });

  testWidgets('with history: records, chart and recent sessions', (tester) async {
    await seedWorkout(
      db,
      exerciseId: '0025',
      name: 'Push A',
      startedAt: DateTime.utc(2026, 9, 1, 10),
      sets: [(SetType.warmup, 40, 10, true), (SetType.normal, 60, 8, true), (SetType.normal, 60, 8, true)],
    );
    await seedWorkout(
      db,
      exerciseId: '0025',
      name: 'Push B',
      startedAt: DateTime.utc(2026, 9, 8, 10),
      sets: [(SetType.normal, 70, 5, true), (SetType.failure, 62.5, 7, true)],
    );
    await openDetail(tester, '0025', LanguagePref.en);

    // Heaviest 70, best e1RM 70×(1+5/30)=81.7, best set volume 60×8=480.
    expect(find.text(isolateName('70 kg'), findRichText: true), findsOneWidget);
    expect(find.text(isolateName('81.7 kg'), findRichText: true), findsOneWidget);
    expect(find.text(isolateName('480 kg'), findRichText: true), findsOneWidget);

    await scrollTo(tester, find.byType(ExerciseProgressChart));
    await scrollTo(tester, find.byKey(ExerciseDetailScreen.historyKey));
    await scrollTo(tester, find.text(isolateName('Push A')));
    expect(find.text(isolateName('Push B'), skipOffstage: false), findsOneWidget);
    // Newest first.
    expect(
      tester.getTopLeft(find.text(isolateName('Push B'), skipOffstage: false)).dy,
      lessThan(tester.getTopLeft(find.text(isolateName('Push A'))).dy),
    );
    expect(find.text('${isolateName('62.5 kg')} × 7', skipOffstage: false), findsOneWidget);
    expect(find.text('F', skipOffstage: false), findsOneWidget);
    expect(find.text('W'), findsOneWidget);
  });

  testWidgets('unknown id shows the unknown-exercise state', (tester) async {
    await openDetail(tester, '9999', LanguagePref.en);
    expect(find.text('Unknown exercise'), findsOneWidget);
  });
}
