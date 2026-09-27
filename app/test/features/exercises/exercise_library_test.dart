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
    expect(find.text('1,291 exercises'), findsOneWidget);
    expect(find.byType(ExerciseCard), findsWidgets);
  });

  testWidgets('Arabic count uses a thousands separator and Western digits', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    expect(find.text('1,291 تمرين'), findsOneWidget);
  });

  testWidgets('Arabic formal name, Egyptian slang and English all find bench press first', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    for (final q in ['ضغط بار مستوي', 'بنش', 'barbell bench press', 'رفرفه جانبي']) {
      await search(tester, q);
      expect(cardIds().first, q == 'رفرفه جانبي' ? '0334' : '0025', reason: q);
    }
  });

  testWidgets('Arabic UI: Arabic primary + English secondary; hidden duplicates never show', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    await search(tester, 'بنش');
    final card = find.byType(ExerciseCard).first;
    expect(find.descendant(of: card, matching: find.text(isolateName('ضغط بار مستوي'))), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text(isolateName('Barbell Bench Press'))), findsOneWidget);

    // Every exercise has an Arabic name now (the English-only rule is unit-tested
    // in test/core/exercise_names_test.dart). 0735 "Sit-Up V. 2" is a hidden
    // duplicate of 0001 (data/hidden_exercises.json): searching its shared
    // Arabic name or its own English name never lists it.
    await search(tester, 'بطن تلات تربع');
    expect(cardIds(), contains('0001'));
    expect(cardIds(), isNot(contains('0735')));
    await search(tester, 'sit-up v. 2');
    expect(cardIds(), isNot(contains('0735')));
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
    await tapChip(tester, 'Biceps');
    expect(find.text('143 exercises'), findsOneWidget);
    final targets = (await db.select(db.exercises).get())
        .where((e) => cardIds().contains(e.id))
        .map((e) => e.target)
        .toSet();
    expect(targets, {'biceps'});

    await tapChip(tester, 'All');
    expect(find.text('1,291 exercises'), findsOneWidget);
  });

  testWidgets('"More" chip expands the rare muscles inline', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    expect(find.text('Spine'), findsNothing);
    await tapChip(tester, 'More');
    expect(find.text('More'), findsNothing);
    await tapChip(tester, 'Spine');
    expect(find.text('19 exercises'), findsOneWidget);
  });

  testWidgets('equipment sheet filters; the pill removes the filter', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await tester.tap(find.bySemanticsLabel('Equipment'));
    await settle(tester);
    expect(find.text('Filter by equipment'), findsOneWidget);
    await tester.tap(find.text('Barbell'));
    await settle(tester);
    expect(find.text('Filter by equipment'), findsNothing);
    expect(find.text('150 exercises'), findsOneWidget);

    // Combined with a search and a muscle.
    await tapChip(tester, 'Chest');
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
    expect(find.text('1,291 exercises'), findsOneWidget);
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
