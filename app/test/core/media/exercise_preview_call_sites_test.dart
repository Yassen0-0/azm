// Every list that shows an exercise thumbnail opens the quick preview when the
// thumbnail is tapped (library, picker, active workout, routine editor, past
// workout, stats records), in the real app with its router, in ar + en.
import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/media/exercise_media.dart';
import 'package:azm/core/media/exercise_preview_sheet.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/workout/workout_test_helpers.dart';

/// Timers tick in the workout screens, so pump fixed fake time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<GoRouter> pumpApp(WidgetTester tester, LanguagePref lang) async {
    tester.view.physicalSize = const Size(1170, 2532); // tall phone: no scrolling needed
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = openTestDb();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(FakeRestAlarm()),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
    ]);
    await insertCatalog(db, testCatalog);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await _settle(tester);
    return container.read(appRouterProvider);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close()); // awaiting close() in the fake-async zone never completes
    await tester.pump(const Duration(seconds: 1));
  }

  /// Taps the thumbnail of 0025, checks the sheet, closes it again.
  Future<void> expectPreview(WidgetTester tester, String where, String name) async {
    final thumb = find.byKey(ExerciseThumbnail.previewKey('0025')).hitTestable();
    expect(thumb, findsWidgets, reason: '$where: thumbnail on screen');
    await tester.tap(thumb.first);
    await _settle(tester);
    final sheet = find.byType(ExercisePreviewSheet);
    expect(sheet, findsOneWidget, reason: '$where: preview opened');
    expect(find.descendant(of: sheet, matching: find.text(isolateName(name))), findsOneWidget, reason: where);
    Navigator.of(tester.element(sheet)).pop();
    await _settle(tester);
    expect(sheet, findsNothing, reason: '$where: preview closed');
  }

  for (final (lang, name) in [(LanguagePref.ar, 'ضغط بار مستوي'), (LanguagePref.en, 'Barbell Bench Press')]) {
    testWidgets('thumbnail → preview everywhere (${lang.name})', (tester) async {
      final router = await pumpApp(tester, lang);
      final pastId = await insertFinishedWorkout(
        db,
        startedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
        exerciseId: '0025',
        sets: [(60, 8, SetType.normal)],
      );

      router.go(AppRoutes.exercises);
      await _settle(tester);
      await expectPreview(tester, 'library', name);
      expect(router.state.uri.path, AppRoutes.exercises, reason: 'library row tap (detail) not triggered');

      unawaited(router.push(AppRoutes.exercisePicker));
      await _settle(tester);
      await expectPreview(tester, 'picker', name);
      final pickerCard = tester.widget<ExerciseCard>(find.byKey(const ValueKey('0025')));
      expect(pickerCard.selectionIndex, isNull, reason: 'picker: the thumbnail must not select the row');
      router.pop();
      await _settle(tester);

      final workouts = container.read(workoutRepositoryProvider);
      final wId = await workouts.startEmpty('Evening');
      await workouts.addExercises(wId, ['0025']);
      unawaited(router.push(AppRoutes.activeWorkout));
      await _settle(tester);
      await expectPreview(tester, 'active workout', name);
      router.pop();
      await _settle(tester);
      await workouts.discard(wId);
      await _settle(tester);

      final routines = container.read(routineRepositoryProvider);
      final rId = await routines.create(name: 'Push');
      await routines.addExercises(rId, ['0025']);
      unawaited(router.push(AppRoutes.routineEditorFor(rId)));
      await _settle(tester);
      await expectPreview(tester, 'routine editor', name);
      router.pop();
      await _settle(tester);

      unawaited(router.push(AppRoutes.pastWorkoutFor(pastId)));
      await _settle(tester);
      await expectPreview(tester, 'past workout', name);
      router.pop();
      await _settle(tester);

      unawaited(router.push(AppRoutes.stats));
      await _settle(tester);
      await expectPreview(tester, 'stats records', name);
      router.pop();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      await tearDownApp(tester);
    });
  }
}
