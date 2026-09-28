import 'dart:async';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/exercises/data/exercise_filters.dart';
import 'package:azm/features/exercises/ui/filter_sheet.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

/// Widget tests for the filter bar and its three sheets (library + picker).
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

  bool selected(WidgetTester tester, FilterKind k, String id) =>
      tester.widget<FilterCard>(find.byKey(FilterKeys.card(k, id))).selected;

  testWidgets('muscle sheet: three sections, multi-select with a live count, Show applies (English)', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    expect(find.text('Place'), findsOneWidget);
    expect(find.text('Muscles'), findsOneWidget); // short chip label
    expect(find.text('Equipment'), findsOneWidget);

    await openFilterSheet(tester, FilterKind.muscle);
    expect(find.text('Muscle group'), findsOneWidget); // sheet title
    expect(find.text('Upper body'), findsOneWidget);
    expect(find.text('Biceps'), findsOneWidget);
    expect(showResultsLabel(tester), 'Show 1,291 results');

    await tapFilterCard(tester, FilterKind.muscle, 'biceps');
    expect(selected(tester, FilterKind.muscle, 'biceps'), isTrue);
    expect(showResultsLabel(tester), 'Show 143 results');
    await tapFilterCard(tester, FilterKind.muscle, 'chest'); // OR within the type
    expect(showResultsLabel(tester), 'Show 301 results');
    // Nothing applies before Show.
    await tester.tap(find.byKey(FilterKeys.showResults));
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('301 exercises'), findsOneWidget);
    expect(find.bySemanticsLabel('Muscle group, 2 selected'), findsOneWidget);
    expect(find.byKey(FilterKeys.clearAll), findsOneWidget);
  });

  testWidgets('filters AND across types and with the search; "Clear filters" in a sheet; dismiss keeps them', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await applyFilter(tester, FilterKind.muscle, ['chest']);
    expect(find.text('158 exercises'), findsOneWidget);

    await openFilterSheet(tester, FilterKind.equipment);
    await tapFilterCard(tester, FilterKind.equipment, 'barbell');
    final label = showResultsLabel(tester);
    expect(label, isNot('Show 158 results'));
    await tester.tap(find.byKey(FilterKeys.showResults));
    await settle(tester);
    final chestBarbell = int.parse(RegExp(r'\d+').firstMatch(label)!.group(0)!);
    expect(find.text('$chestBarbell exercises'), findsOneWidget);
    expect(cardIds(), contains('0025')); // barbell bench press

    // + search text.
    await tester.enterText(find.byType(TextField), 'incline');
    await settle(tester);
    final incline = cardIds();
    expect(incline, isNotEmpty);
    expect(incline.length, lessThan(chestBarbell));
    expect(incline, isNot(contains('0025')));

    // A sheet's "Clear filters" empties its selection (count follows); swiping
    // it away applies nothing.
    await openFilterSheet(tester, FilterKind.equipment);
    expect(selected(tester, FilterKind.equipment, 'barbell'), isTrue);
    await tester.tap(find.byKey(FilterKeys.clear));
    await settle(tester);
    expect(selected(tester, FilterKind.equipment, 'barbell'), isFalse);
    await tester.tapAt(const Offset(20, 20)); // scrim
    await settle(tester);
    expect(cardIds(), incline);

    // The result bar's "Clear filters" resets every type (not the text).
    await tester.tap(find.byKey(FilterKeys.clearAll));
    await settle(tester);
    expect(find.byKey(FilterKeys.clearAll), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await settle(tester);
    expect(find.text('1,291 exercises'), findsOneWidget);

    // Zero results: the Show button is disabled.
    await applyFilter(tester, FilterKind.place, ['bands']);
    expect(find.text('61 exercises'), findsOneWidget);
    await openFilterSheet(tester, FilterKind.equipment);
    await tapFilterCard(tester, FilterKind.equipment, 'machine');
    expect(showResultsLabel(tester), 'No results');
    expect(tester.widget<FilledButton>(find.byKey(FilterKeys.showResults)).onPressed, isNull);
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);
    expect(find.text('61 exercises'), findsOneWidget);
  });

  testWidgets('last-used filters are remembered per screen (library ≠ picker)', (tester) async {
    await openLibrary(tester, LanguagePref.en);
    await applyFilter(tester, FilterKind.place, ['home']);
    await applyFilter(tester, FilterKind.equipment, ['dumbbell']);
    expect(find.text('281 exercises'), findsOneWidget); // every dumbbell move works at home
    expect(
      ExerciseFilters.fromJson(await readSettingJson(db, FilterScreen.library.settingsKey)),
      const ExerciseFilters(places: {'home'}, equipment: {'dumbbell'}),
    );

    // The picker has its own filters: none yet.
    final router = tester.state<NavigatorState>(find.byType(Navigator).first).context;
    final container = ProviderScope.containerOf(router);
    unawaited(container.read(appRouterProvider).push<List<String>>(AppRoutes.exercisePicker));
    await settle(tester);
    expect(find.text('1,291 exercises'), findsOneWidget);
    await applyFilter(tester, FilterKind.muscle, ['quads']);
    expect(find.text('44 exercises'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Cancel'));
    await settle(tester);

    // Opened again, the picker restores ITS last filters from the DB.
    unawaited(container.read(appRouterProvider).push<List<String>>(AppRoutes.exercisePicker));
    await settle(tester);
    expect(find.text('44 exercises'), findsOneWidget);
    expect(find.bySemanticsLabel('Muscle group, 1 selected'), findsOneWidget);
    expect(
      ExerciseFilters.fromJson(await readSettingJson(db, FilterScreen.picker.settingsKey)),
      const ExerciseFilters(muscles: {'quads'}),
    );
    await tester.tap(find.bySemanticsLabel('Cancel'));
    await settle(tester);
    // …and the library still shows its own.
    expect(find.text('281 exercises'), findsOneWidget);
    expect(find.bySemanticsLabel('Place, 1 selected'), findsOneWidget);
  });

  for (final lang in [LanguagePref.en, LanguagePref.ar]) {
    testWidgets('cards with 0 exercises are hidden (${lang.name})', (tester) async {
      await openLibrary(tester, lang);
      await openFilterSheet(tester, FilterKind.equipment);
      expect(find.byKey(FilterKeys.card(FilterKind.equipment, 'suspension_band')), findsNothing);
      expect(find.byKey(FilterKeys.card(FilterKind.equipment, 'dumbbell')), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await settle(tester);

      await openFilterSheet(tester, FilterKind.muscle);
      final list = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.byKey(FilterKeys.card(FilterKind.muscle, 'full_body')), 200, scrollable: list);
      await settle(tester);
      // The "Other" section keeps cardio + full body; the empty "other" card is gone.
      expect(find.byKey(FilterKeys.card(FilterKind.muscle, 'cardio')), findsOneWidget);
      expect(find.byKey(FilterKeys.card(FilterKind.muscle, 'other')), findsNothing);
      expect(find.text(lang == LanguagePref.en ? 'Other' : 'تاني'), findsOneWidget); // the section title only
    });
  }

  testWidgets('a remembered filter on a hidden card is dropped on restore', (tester) async {
    await db.writeSetting(
      FilterScreen.library.settingsKey,
      '{"place":[],"muscle":["other"],"equipment":["suspension_band","dumbbell"]}',
    );
    await openLibrary(tester, LanguagePref.en);
    expect(find.text('281 exercises'), findsOneWidget); // dumbbell only
    expect(find.bySemanticsLabel('Equipment, 1 selected'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Muscle group, ')), findsNothing);
  });

  testWidgets('Arabic: "امسح الفلاتر" in the result bar and in the sheet', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    await applyFilter(tester, FilterKind.muscle, ['chest']);
    expect(find.descendant(of: find.byKey(FilterKeys.clearAll), matching: find.text('امسح الفلاتر')), findsOneWidget);
    await openFilterSheet(tester, FilterKind.muscle);
    expect(find.descendant(of: find.byKey(FilterKeys.clear), matching: find.text('امسح الفلاتر')), findsOneWidget);
    expect(find.text('شيل الفلاتر'), findsNothing);
  });

  testWidgets('Arabic: Egyptian gym labels, RTL sheet, live Arabic count', (tester) async {
    await openLibrary(tester, LanguagePref.ar);
    expect(find.text('المكان'), findsOneWidget);
    expect(find.text('العضلة'), findsOneWidget);
    await openFilterSheet(tester, FilterKind.muscle);
    expect(Directionality.of(tester.element(find.text('الجزء العلوي'))), TextDirection.rtl);
    for (final label in ['بطن', 'باي', 'صدر', 'سواعد', 'ضهر', 'كتف', 'ترابيس', 'تراي']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tapFilterCard(tester, FilterKind.muscle, 'hamstrings');
    expect(find.text('خلفي'), findsOneWidget);
    expect(find.text('رجل أمامي'), findsOneWidget);
    expect(find.text('سمانة'), findsOneWidget);
    expect(find.text('مؤخرة'), findsOneWidget);
    expect(showResultsLabel(tester), 'اعرض 28 تمرين');
    await tester.tap(find.byKey(FilterKeys.showResults));
    await settle(tester);

    await openFilterSheet(tester, FilterKind.equipment);
    for (final label in ['دمبل', 'بار', 'كيتل بل', 'أحبال مقاومة']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);
    await openFilterSheet(tester, FilterKind.place);
    expect(find.text('جيم'), findsOneWidget);
    expect(find.text('البيت'), findsOneWidget);
    expect(find.text('أحبال مقاومة'), findsOneWidget);
  });
}
