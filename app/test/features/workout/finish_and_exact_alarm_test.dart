import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late FakeRestAlarm alarm;
  late ProviderContainer container;

  WorkoutRepository repo() => container.read(workoutRepositoryProvider);

  /// App in English with an active workout: bench (previous 60 × 8 × 2) and
  /// row (no history → one empty set).
  Future<String> pumpWorkout(WidgetTester tester, {bool late = false}) async {
    db = openTestDb();
    alarm = FakeRestAlarm()..late = late;
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(alarm),
      initialAppSettingsProvider.overrideWithValue(const AppSettings(language: LanguagePref.en)),
    ]);
    await insertCatalog(db, testCatalog);
    await insertFinishedWorkout(
      db,
      startedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      exerciseId: '0025',
      sets: [(60, 8, SetType.normal), (60, 8, SetType.normal)],
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
    await tester.tap(find.text('Start empty workout'));
    await settle(tester);
    final id = (await repo().active())!.id;
    await repo().addExercises(id, ['0025', '0292']);
    await settle(tester);
    return id;
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<List<WorkoutSet>> finishedSets(String id) async => [
        for (final e in (await repo().loadDetail(id))!.exercises) ...e.sets,
      ];

  group('finish with unticked sets', () {
    testWidgets('shows the count and "Mark all done" ticks every loggable set', (tester) async {
      final id = await pumpWorkout(tester);
      await tester.tap(find.bySemanticsLabel('Mark set complete').first); // bench set 1
      await settle(tester);

      await tester.tap(find.text('Finish'));
      await settle(tester);
      // Unticked: bench set 2 (loggable via previous) + row set 1 (empty).
      expect(find.text('2 sets have no ✓ yet.\n1 of them is empty and will be removed.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workoutFinishMarkAllDone')));
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Workout complete'), findsOneWidget);
      final sets = await finishedSets(id);
      expect(sets, hasLength(2)); // the empty row set (and its exercise) are gone
      expect(sets.every((s) => s.completedAt != null && s.weightKg == 60 && s.reps == 8), isTrue);
      await tearDownApp(tester);
    });

    testWidgets('"Remove them" keeps only the ticked sets', (tester) async {
      final id = await pumpWorkout(tester);
      await tester.tap(find.bySemanticsLabel('Mark set complete').first);
      await settle(tester);

      await tester.tap(find.text('Finish'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('workoutFinishRemoveThem')));
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Workout complete'), findsOneWidget);
      final sets = await finishedSets(id);
      expect(sets, hasLength(1));
      expect(sets.single.completedAt, isNotNull);
      await tearDownApp(tester);
    });

    testWidgets('"Remove them" with nothing ticked offers to discard instead', (tester) async {
      await pumpWorkout(tester);
      await tester.tap(find.text('Finish'));
      await settle(tester);
      expect(find.text('3 sets have no ✓ yet.\n1 of them is empty and will be removed.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workoutFinishRemoveThem')));
      await settle(tester);
      expect(find.text('No completed sets yet. Discard this workout?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await settle(tester);
      expect(await repo().active(), isNull);
      await tearDownApp(tester);
    });

    testWidgets('only empty sets unticked → no "Mark all done"', (tester) async {
      final id = await pumpWorkout(tester);
      final bench = (await repo().loadDetail(id))!.exercises.first.sets;
      for (final s in bench) {
        await repo().setCompleted(s.id, true, weightKg: 60, reps: 8);
      }
      await settle(tester);
      await tester.tap(find.text('Finish'));
      await settle(tester);
      expect(find.text('1 set has no ✓ yet.\n1 of them is empty and will be removed.'), findsOneWidget);
      expect(find.byKey(const ValueKey('workoutFinishMarkAllDone')), findsNothing);
      expect(find.byKey(const ValueKey('workoutFinishRemoveThem')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(await repo().active(), isNotNull);
      await tearDownApp(tester);
    });
  });

  group('Android exact alarms (one-time explanation)', () {
    testWidgets('first rest timer shows the sheet; "Open settings" asks the OS and reschedules; never again',
        (tester) async {
      await pumpWorkout(tester, late: true);
      await tester.tap(find.bySemanticsLabel('Mark set complete').first);
      await settle(tester);
      expect(find.text('Get the rest alert on time'), findsOneWidget);
      final scheduledBefore = Map.of(alarm.scheduled);
      await tester.tap(find.byKey(const ValueKey('workoutExactAlarmAllow')));
      await settle(tester);
      expect(alarm.exactAlarmRequests, 1);
      expect(alarm.scheduled.keys, scheduledBefore.keys); // same rest, rescheduled
      expect(await db.readSetting(WorkoutSettingsKeys.exactAlarmsAsked), 'true');

      // Second rest timer: still inexact, but never asked again automatically.
      await tester.tap(find.bySemanticsLabel('Mark set complete').first);
      await settle(tester);
      expect(find.text('Get the rest alert on time'), findsNothing);
      expect(alarm.exactAlarmRequests, 1);
      await tearDownApp(tester);
    });

    testWidgets('"Not now" keeps the inexact fallback and is remembered', (tester) async {
      await pumpWorkout(tester, late: true);
      await tester.tap(find.bySemanticsLabel('Mark set complete').first);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('workoutExactAlarmLater')));
      await settle(tester);
      expect(alarm.exactAlarmRequests, 0);
      expect(alarm.scheduled, hasLength(1)); // the rest still has its (inexact) alarm
      expect(await db.readSetting(WorkoutSettingsKeys.exactAlarmsAsked), 'true');
      await tearDownApp(tester);
    });

    testWidgets('no sheet when exact alarms are allowed or notifications are off', (tester) async {
      await pumpWorkout(tester); // late = false (iOS, or permission granted)
      await tester.tap(find.bySemanticsLabel('Mark set complete').first);
      await settle(tester);
      expect(find.text('Get the rest alert on time'), findsNothing);
      await tearDownApp(tester);

      await pumpWorkout(tester, late: true);
      alarm.enabled = false;
      await tester.tap(find.bySemanticsLabel('Mark set complete').first);
      await settle(tester);
      expect(find.text('Get the rest alert on time'), findsNothing);
      expect(await db.readSetting(WorkoutSettingsKeys.exactAlarmsAsked), isNull); // may ask later
      await tearDownApp(tester);
    });
  });
}
