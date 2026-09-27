import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'exercises_test_utils.dart';

void main() {
  late AppDatabase db;

  setUp(() async => db = await openCatalogDb());
  tearDown(() => db.close());

  /// Opens the picker exactly like the workout/routines features do and
  /// returns a getter for what it popped.
  Future<(GoRouter, List<String>? Function(), bool Function())> openPicker(WidgetTester tester) async {
    useTallScreen(tester);
    final container = await pumpAzm(tester, db, LanguagePref.en);
    final router = container.read(appRouterProvider);
    List<String>? result;
    var done = false;
    router.push<List<String>>(AppRoutes.exercisePicker).then((ids) {
      result = ids;
      done = true;
    });
    await settle(tester);
    return (router, () => result, () => done);
  }

  Future<void> tapExercise(WidgetTester tester, String query, String id) async {
    await tester.enterText(find.byType(TextField), query);
    await settle(tester);
    await tester.tap(find.byKey(ValueKey(id)));
    await settle(tester);
  }

  testWidgets('returns the selected ids in SELECTION order, renumbering on deselect', (tester) async {
    final (_, result, done) = await openPicker(tester);
    expect(find.text('Add exercises'), findsOneWidget);

    // Confirm is disabled with nothing selected.
    final confirm = find.byKey(const ValueKey('exercisePickerConfirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tapExercise(tester, 'barbell full squat', '0043');
    await tapExercise(tester, 'barbell bench press', '0025');
    await tapExercise(tester, 'barbell deadlift', '0032');
    await tapExercise(tester, 'rdl', '0085');
    expect(find.text('Add (4)'), findsOneWidget);

    // Deselect bench → the others move up (1 squat, 2 deadlift, 3 rdl).
    await tapExercise(tester, 'barbell bench press', '0025');
    expect(find.text('Add (3)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'rdl');
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp('Selected, number 3')), findsOneWidget);

    await tester.tap(confirm);
    await settle(tester);
    expect(done(), isTrue);
    expect(result(), ['0043', '0032', '0085']);
  });

  testWidgets('close button pops null', (tester) async {
    final (_, result, done) = await openPicker(tester);
    await tapExercise(tester, 'barbell bench press', '0025');
    await tester.tap(find.bySemanticsLabel('Cancel'));
    await settle(tester);
    expect(done(), isTrue);
    expect(result(), isNull);
  });

  testWidgets('system back pops null', (tester) async {
    final (_, result, done) = await openPicker(tester);
    await tapExercise(tester, 'barbell bench press', '0025');
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(done(), isTrue);
    expect(result(), isNull);
  });

  testWidgets('filters work in the picker and keep the selection', (tester) async {
    final (_, result, _) = await openPicker(tester);
    await tapExercise(tester, 'barbell bench press', '0025');
    await tester.enterText(find.byType(TextField), '');
    await tapChip(tester, 'Biceps');
    expect(find.text('151 exercises'), findsOneWidget);
    await tapChip(tester, 'All');
    await tapExercise(tester, 'barbell bench press', '0025'); // toggles off
    expect(find.text('Add'), findsOneWidget);
    expect(result(), isNull);
  });

  // Regression (window C's note): a second search after clearing must refresh
  // the results. Drives the field through the platform text-input channel and
  // the × button, like a user.
  testWidgets('search → clear (×) → search again → results update', (tester) async {
    await openPicker(tester);
    final field = find.byType(TextField);
    await tester.enterText(field, 'barbell bench press');
    await settle(tester);
    expect(find.byKey(const ValueKey('0025')), findsOneWidget);
    expect(find.byKey(const ValueKey('0043')), findsNothing);

    await tester.tap(find.bySemanticsLabel('Clear search'));
    await settle(tester);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.text('1324 exercises'), findsOneWidget);

    await tester.enterText(field, 'barbell full squat');
    await settle(tester);
    expect(find.byKey(const ValueKey('0043')), findsOneWidget);
    expect(find.byKey(const ValueKey('0025')), findsNothing);

    // And a third, replacing the text without clearing first.
    await tester.enterText(field, 'rdl');
    await settle(tester);
    expect(find.byKey(const ValueKey('0085')), findsOneWidget);
    expect(find.byKey(const ValueKey('0043')), findsNothing);
  });

  testWidgets('results follow the field text even when it changes without onChanged', (tester) async {
    await openPicker(tester);
    final field = find.byType(TextField);
    await tester.enterText(field, 'barbell bench press');
    await settle(tester);
    // A text change that doesn't come through onChanged (programmatic, or an
    // IME update the field doesn't report) must still refresh the list.
    tester.widget<TextField>(field).controller!.text = 'barbell full squat';
    await settle(tester);
    expect(find.byKey(const ValueKey('0043')), findsOneWidget);
    expect(find.byKey(const ValueKey('0025')), findsNothing);
  });
}
