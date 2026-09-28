import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/theme/azm_theme.dart';
import 'package:azm/core/widgets/workout_time_sheet.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:azm/features/workout/ui/workout_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

/// Live workout, Hevy layout (PLAN §14): top bar, stats row, exercise block
/// (accent name, notes, rest line incl. OFF, SET | PREVIOUS | KG | REPS | ✓),
/// manual rest timer, editable start time. English + Arabic.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late TestClock clock;

  WorkoutRepository repo() => container.read(workoutRepositoryProvider);

  Future<String> pumpWorkout(WidgetTester tester, LanguagePref lang) async {
    db = openTestDb();
    // Fixed wall clock (local 18:00 today) so the time wheels are predictable.
    final n = DateTime.now();
    clock = TestClock(DateTime(n.year, n.month, n.day, 18).toUtc());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(FakeRestAlarm()),
      workoutClockProvider.overrideWithValue(clock.call),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
    ]);
    await insertCatalog(db, testCatalog);
    await insertFinishedWorkout(
      db,
      startedAt: clock.now.subtract(const Duration(days: 2)),
      exerciseId: '0025',
      sets: [(60, 8, SetType.normal)],
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('workoutStartEmpty')));
    await settle(tester);
    final id = (await repo().active())!.id;
    await repo().addExercises(id, ['0025']);
    await settle(tester);
    return id;
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('layout: top bar, stats, block with accent name, notes, rest line, table (English)', (tester) async {
    final id = await pumpWorkout(tester, LanguagePref.en);
    for (final k in ['workoutMinimize', 'workoutElapsed', 'workoutTimerButton', 'workoutFinish']) {
      expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
    }
    expect(find.text('Finish'), findsOneWidget);
    for (final t in ['Duration', 'Lifted', 'Sets']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // Stats labels sit above their values.
    expect(tester.getTopLeft(find.text('Sets')).dy, lessThan(tester.getTopLeft(find.text('0').first).dy));

    final c = AzmColors.dark;
    expect(tester.widget<Text>(find.text('Barbell Bench Press')).style?.color, c.accent);
    expect(find.text('Add notes here...'), findsOneWidget);
    expect(find.text('Rest Timer: 1:30'), findsOneWidget);
    for (final h in ['SET', 'PREVIOUS', 'KG', 'REPS']) {
      expect(find.text(h), findsOneWidget, reason: h);
    }
    expect(find.textContaining('60 kg × 8'), findsOneWidget); // previous, muted
    expect(find.text('Add set'), findsOneWidget);

    // Notes are saved per exercise as you type.
    await tester.enterText(find.byType(TextField).first, 'seat 4');
    await settle(tester);
    expect((await repo().loadDetail(id))!.exercises.single.entry.notes, 'seat 4');
    await tearDownApp(tester);
  });

  testWidgets('rest line: OFF means no timer after ✓; a fixed time is used (English)', (tester) async {
    final id = await pumpWorkout(tester, LanguagePref.en);
    await tester.tap(find.text('Rest Timer: 1:30'));
    await settle(tester);
    expect(find.text('Default (1:30)'), findsOneWidget);
    await tester.tap(find.byKey(WorkoutSheetKeys.restOff));
    await settle(tester);
    expect(find.text('Rest Timer: OFF'), findsOneWidget);
    expect((await repo().loadDetail(id))!.exercises.single.restSeconds, 0);

    await tester.tap(find.bySemanticsLabel('Mark set complete').first);
    await settle(tester);
    expect((await repo().loadDetail(id))!.completedSets, 1);
    expect(container.read(restTimerProvider), isNull, reason: 'rest is OFF');

    await tester.tap(find.text('Rest Timer: OFF'));
    await settle(tester);
    await tester.tap(find.byKey(WorkoutSheetKeys.restChoice(120)));
    await settle(tester);
    expect(find.text('Rest Timer: 2:00'), findsOneWidget);
    await tester.tap(find.text('Add set'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Mark set complete').last);
    await settle(tester);
    expect(container.read(restTimerProvider)?.totalSeconds, 120);

    // Back to the default.
    await tester.tap(find.text('Rest Timer: 2:00'));
    await settle(tester);
    await tester.tap(find.byKey(WorkoutSheetKeys.restDefault));
    await settle(tester);
    expect(find.text('Rest Timer: 1:30'), findsOneWidget);
    await container.read(restTimerProvider.notifier).skip();
    await tearDownApp(tester);
  });

  testWidgets('⏱ manual rest timer: presets start a countdown, Skip stops it', (tester) async {
    await pumpWorkout(tester, LanguagePref.en);
    await tester.tap(find.byKey(const ValueKey('workoutTimerButton')));
    await settle(tester);
    expect(find.text('Start a rest countdown now.'), findsOneWidget);
    for (final s in kManualRestPresets) {
      expect(find.byKey(WorkoutSheetKeys.manualPreset(s)), findsOneWidget);
    }
    await tester.tap(find.byKey(WorkoutSheetKeys.manualPreset(60)));
    await settle(tester);
    expect(container.read(restTimerProvider)?.totalSeconds, 60);

    await tester.tap(find.byKey(const ValueKey('workoutTimerButton')));
    await settle(tester);
    expect(find.textContaining('left'), findsOneWidget);
    await tester.tap(find.byKey(WorkoutSheetKeys.manualSkip));
    await settle(tester);
    expect(container.read(restTimerProvider), isNull);
    await tearDownApp(tester);
  });

  testWidgets('tap the elapsed time → move the start back; never into the future', (tester) async {
    final id = await pumpWorkout(tester, LanguagePref.en);
    clock.advance(const Duration(minutes: 5));
    await tester.tap(find.byKey(const ValueKey('workoutElapsed')));
    await settle(tester);
    expect(find.text('When did you start?'), findsOneWidget);

    // 18 → 20 o'clock is in the future: error, Save disabled.
    await tester.drag(find.byKey(WorkoutTimeKeys.hour), const Offset(0, -88));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.byKey(WorkoutTimeKeys.error), findsOneWidget);
    expect(find.text("Can't be in the future"), findsOneWidget);
    await tester.tap(find.byKey(WorkoutTimeKeys.save));
    await settle(tester);
    expect(find.text('When did you start?'), findsOneWidget, reason: 'Save is disabled');

    // Back to 17:00 → saved; the duration follows (1 h 5 min).
    await tester.drag(find.byKey(WorkoutTimeKeys.hour), const Offset(0, 132));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.byKey(WorkoutTimeKeys.error), findsNothing);
    await tester.tap(find.byKey(WorkoutTimeKeys.save));
    await settle(tester);
    final local = clock.now.toLocal();
    final w = (await repo().loadDetail(id))!.workout;
    expect(w.startedAt, DateTime(local.year, local.month, local.day, 17).toUtc());
    expect(find.text('1:05:00'), findsWidgets);
    await tearDownApp(tester);
  });

  testWidgets('Arabic: labels, RTL mirroring of the block and the set row', (tester) async {
    await pumpWorkout(tester, LanguagePref.ar);
    expect(find.text('إنهاء'), findsOneWidget);
    expect(find.text('شِلت'), findsOneWidget);
    expect(find.text('ضيف ملاحظة...'), findsOneWidget);
    expect(find.text('الراحة: 1:30'), findsOneWidget);
    expect(find.text('ضيف سِت'), findsOneWidget);
    final name = find.text('ضغط بار مستوي');
    expect(Directionality.of(tester.element(name)), TextDirection.rtl);
    // Avatar at the start (right), ⋮ at the end (left).
    final menu = find.bySemanticsLabel('خيارات التمرين');
    expect(tester.getCenter(menu).dx, lessThan(tester.getCenter(name).dx));
    // Set number at the start (right), ✓ at the end (left).
    final check = find.bySemanticsLabel('علّم السِت خلصان');
    expect(tester.getCenter(check).dx, lessThan(tester.getCenter(find.text('1')).dx));
    // Minimize at the start (right), Finish at the end (left).
    expect(
      tester.getCenter(find.byKey(const ValueKey('workoutFinish'))).dx,
      lessThan(tester.getCenter(find.byKey(const ValueKey('workoutMinimize'))).dx),
    );
    await tearDownApp(tester);
  });
}
