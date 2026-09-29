import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/theme/azm_theme.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

/// pumpAndSettle never settles while timers tick (duration, rest bar), so
/// pump a fixed amount of fake time instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late FakeRestAlarm alarm;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, LanguagePref lang) async {
    db = openTestDb();
    alarm = FakeRestAlarm();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(alarm),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
    ]);
    await insertCatalog(db, testCatalog);
    await insertFinishedWorkout(
      db,
      startedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      exerciseId: '0025',
      sets: [(60, 8, SetType.normal)],
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // Awaiting close() inside the fake-async zone never completes; let it run.
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  WorkoutRepository repo() => container.read(workoutRepositoryProvider);

  testWidgets('start → log with previous → keypad → rest timer → minimize → finish → summary (English)',
      (tester) async {
    await pumpApp(tester, LanguagePref.en);

    // 1 tap: start an empty workout.
    await tester.tap(find.text('Start empty workout'));
    await settle(tester);
    expect(find.text('Add your first exercise to start logging'), findsOneWidget);
    final workoutId = (await repo().active())!.id;

    // The picker belongs to the exercises window; add exercises directly.
    await repo().addExercises(workoutId, ['0025']);
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('ضغط بار مستوي'), findsOneWidget); // secondary name
    expect(find.textContaining('60 kg × 8'), findsOneWidget); // previous

    // ✓ an empty set → filled from previous, persisted, rest timer starts.
    await tester.tap(find.bySemanticsLabel('Mark set complete'));
    await settle(tester);
    var set = (await repo().loadDetail(workoutId))!.exercises.first.sets.first;
    expect((set.weightKg, set.reps, set.completedAt != null), (60.0, 8, true));
    expect(container.read(restTimerProvider), isNotNull);
    expect(alarm.scheduled, hasLength(1));
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Add a set (copies 60 × 8), edit its weight with the keypad: 7, 0 → 70 kg.
    await tester.tap(find.text('Add set'));
    await settle(tester);
    final second = (await repo().loadDetail(workoutId))!.exercises.first.sets[1];
    await tester.tap(find.text('60').last);
    await settle(tester);
    expect(find.text('Weight (kg)'), findsOneWidget);
    await tester.tap(find.text('7').last);
    await tester.tap(find.text('0').last);
    await settle(tester);
    set = (await repo().loadDetail(workoutId))!.exercises.first.sets[1];
    expect(set.id, second.id);
    expect(set.weightKg, 70);
    await tester.tap(find.bySemanticsLabel('Close keypad'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Mark set complete').last);
    await settle(tester);

    // Header stats: Lifted 60×8 + 70×8 = 1,040; 2 sets. PR on the 70 kg set.
    expect(find.textContaining('\u20661,040'), findsOneWidget);
    expect(find.text('🏆'), findsOneWidget);

    // Skip the rest.
    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(container.read(restTimerProvider), isNull);

    // Minimize → bar above the tab bar → tap restores.
    await tester.tap(find.bySemanticsLabel('Minimize workout'));
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp('^Open workout')), findsOneWidget);
    expect(find.text('Resume workout'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Open workout')));
    await settle(tester);
    expect(find.text('Finish'), findsOneWidget);

    // Finish → confirm → summary.
    await tester.tap(find.text('Finish'));
    await settle(tester);
    expect(find.text('Finish workout?'), findsOneWidget);
    await tester.tap(find.text('Finish').last);
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('New PRs'), findsOneWidget);
    expect(find.textContaining('70 kg × 8'), findsWidgets);
    expect(find.text('Heaviest weight · Best est. 1RM · Best set volume'), findsOneWidget);
    expect(await repo().active(), isNull);

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Start empty workout'), findsOneWidget);

    await tearDownApp(tester);
  });

  testWidgets('Arabic: RTL labels, set type menu, discard with confirmation', (tester) async {
    await pumpApp(tester, LanguagePref.ar);
    await tester.tap(find.text('ابدأ تمرين فاضي'));
    await settle(tester);
    final workoutId = (await repo().active())!.id;
    await repo().addExercises(workoutId, ['0292']);
    await settle(tester);
    expect(Directionality.of(tester.element(find.text('منشار'))), TextDirection.rtl);

    // Set label → type menu → warm-up (ح, amber).
    await tester.tap(find.text('1'));
    await settle(tester);
    expect(find.text('نوع السِت'), findsOneWidget);
    await tester.tap(find.text('إحماء'));
    await settle(tester);
    expect(find.text('ح'), findsOneWidget);
    final amber = Theme.of(tester.element(find.text('ح'))).extension<AzmColors>()!.warmupText;
    expect(tester.widget<Text>(find.text('ح')).style?.color, amber);
    final s = (await repo().loadDetail(workoutId))!.exercises.first.sets.first;
    expect(s.type, SetType.warmup);

    // ✓ with nothing entered and no previous → opens the reps keypad instead.
    await tester.tap(find.bySemanticsLabel('علّم السِت خلصان'));
    await settle(tester);
    expect(find.text('عدّات'), findsWidgets);
    expect((await repo().loadDetail(workoutId))!.completedSets, 0);

    // Discard.
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await settle(tester);
    await tester.tap(find.text('إلغاء التمرين'));
    await settle(tester);
    await tester.tap(find.text('امسح'));
    await settle(tester);
    expect(await repo().active(), isNull);
    expect(await repo().loadDetail(workoutId), isNull); // deleted with its sets (cascade)
    expect(await db.select(db.workouts).get(), hasLength(1)); // only the seeded history
    expect(find.text('ابدأ تمرين فاضي'), findsOneWidget);

    await tearDownApp(tester);
  });
}
