import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

void main() {
  late AppDatabase db;

  setUp(() async => db = await openCatalogDb());
  tearDown(() => db.close());

  Future<void> openLibrary(WidgetTester tester, LanguagePref lang) async {
    useTallScreen(tester);
    final container = await pumpAzm(tester, db, lang);
    container.read(appRouterProvider).go(AppRoutes.exercises);
    await settle(tester);
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await settle(tester);
  }

  testWidgets('shows the whole catalog by default with a count', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    expect(find.text('1324 exercises'), findsOneWidget);
    expect(find.byType(ExerciseCard), findsWidgets);
  });

  testWidgets('Arabic formal name, Egyptian slang and English all find bench press first', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    for (final q in ['ضغط بار مستوي', 'بنش', 'barbell bench press', 'رفرفه جانبي']) {
      await search(tester, q);
      expect(cardIds().first, q == 'رفرفه جانبي' ? '0334' : '0025', reason: q);
    }
  });

  testWidgets('Arabic UI: Arabic primary + English secondary; English-only rows show one name', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    await search(tester, 'بنش');
    final card = find.byType(ExerciseCard).first;
    expect(find.descendant(of: card, matching: find.text(isolateName('ضغط بار مستوي'))), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text(isolateName('Barbell Bench Press'))), findsOneWidget);

    // 0001 "3/4 Sit-Up" has no Arabic name → only the English name.
    await search(tester, '3/4 sit');
    final only = find.byType(ExerciseCard).first;
    expect(cardIds().first, '0001');
    expect(find.descendant(of: only, matching: find.byType(Text)), findsOneWidget);
  });

  testWidgets('English UI: English primary + Arabic secondary', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await search(tester, 'bench');
    final card = find.byKey(const ValueKey('0025'));
    expect(find.descendant(of: card, matching: find.text(isolateName('Barbell Bench Press'))), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text(isolateName('ضغط بار مستوي'))), findsOneWidget);
  });

  testWidgets('muscle chip filters by target; "All" resets', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await tester.tap(find.text('Biceps').first);
    await settle(tester);
    expect(find.text('151 exercises'), findsOneWidget);
    final targets = (await db.select(db.exercises).get())
        .where((e) => cardIds().contains(e.id))
        .map((e) => e.target)
        .toSet();
    expect(targets, {'biceps'});

    await tester.tap(find.text('All'));
    await settle(tester);
    expect(find.text('1324 exercises'), findsOneWidget);
  });

  testWidgets('equipment sheet filters; the pill removes the filter', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await tester.tap(find.bySemanticsLabel('Equipment'));
    await settle(tester);
    expect(find.text('Filter by equipment'), findsOneWidget);
    await tester.tap(find.text('Barbell'));
    await settle(tester);
    expect(find.text('Filter by equipment'), findsNothing);
    expect(find.text('154 exercises'), findsOneWidget);

    // Combined with a search and a muscle.
    await tester.tap(find.text('Chest').first);
    await settle(tester);
    await search(tester, 'bench');
    expect(cardIds(), contains('0025'));

    await tester.tap(find.bySemanticsLabel('Remove filter Barbell'));
    await settle(tester);
    expect(find.bySemanticsLabel('Remove filter Barbell'), findsNothing);
  });

  testWidgets('no results → message and "Clear filters" resets everything', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await search(tester, 'zzzz nothing');
    expect(find.text('No exercises found'), findsOneWidget);
    expect(find.byType(ExerciseCard), findsNothing);
    await tester.tap(find.text('Clear filters'));
    await settle(tester);
    expect(find.text('1324 exercises'), findsOneWidget);
  });

  testWidgets('records show a 🏆 badge with the heaviest weight', (tester) async {
    await seedWorkout(
      db,
      exerciseId: '0025',
      startedAt: DateTime.utc(2026, 9, 1),
      sets: [
        (SetType.warmup, 120, 5, true), // warm-ups never count
        (SetType.normal, 80, 5, true),
      ],
    );
    await openLibrary(tester, LanguagePref.en);
    await search(tester, 'barbell bench press');
    expect(find.text('🏆 ${isolateName('80 kg')}'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Your record: ${isolateName('80 kg')}')), findsOneWidget);
  });

  testWidgets('tapping a row opens the detail', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await search(tester, 'barbell bench press');
    await tester.tap(find.byKey(const ValueKey('0025')));
    await settle(tester);
    expect(find.text('Target muscle'), findsOneWidget);
  });
}
