import 'dart:async';
import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/widgets/rest_timer_bar.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime.utc(2026, 9, 26, 18);

  group('remaining-time math (end timestamp, never a countdown)', () {
    test('remaining = endsAt − now, clamped at zero', () {
      final ends = t0.add(const Duration(seconds: 90));
      expect(restRemaining(ends, t0), const Duration(seconds: 90));
      expect(restRemaining(ends, t0.add(const Duration(seconds: 89, milliseconds: 500))),
          const Duration(milliseconds: 500));
      expect(restRemaining(ends, t0.add(const Duration(minutes: 5))), Duration.zero);
    });

    test('display seconds round UP (0:01 until the very end)', () {
      expect(restDisplaySeconds(const Duration(milliseconds: 1)), 1);
      expect(restDisplaySeconds(const Duration(milliseconds: 59001)), 60);
      expect(restDisplaySeconds(Duration.zero), 0);
    });

    test('±15 moves the end and the total; reaching zero ends the timer', () {
      final s = RestTimerState(endsAt: t0.add(const Duration(seconds: 90)), totalSeconds: 90, notificationId: 1);
      final now = t0.add(const Duration(seconds: 80)); // 10 s left
      final plus = adjustRest(s, 15, now)!;
      expect(plus.endsAt, t0.add(const Duration(seconds: 105)));
      expect(plus.totalSeconds, 105);
      expect(adjustRest(s, -15, now), isNull);
      expect(adjustRest(s, -10, now), isNull); // exactly now → over
      expect(adjustRest(s, -5, now)!.endsAt, t0.add(const Duration(seconds: 85)));
    });

    test('progress fraction', () {
      final s = RestTimerState(endsAt: t0.add(const Duration(seconds: 90)), totalSeconds: 90, notificationId: 1);
      expect(s.fraction(t0), 1);
      expect(s.fraction(t0.add(const Duration(seconds: 45))), 0.5);
      expect(s.fraction(t0.add(const Duration(seconds: 200))), 0);
    });

    test('clock formatting, Western digits', () {
      expect(formatClock(const Duration(seconds: 5)), '0:05');
      expect(formatClock(const Duration(seconds: 90)), '1:30');
      expect(formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(formatClock(const Duration(seconds: -3)), '0:00');
    });
  });

  group('RestTimerController', () {
    late AppDatabase db;
    late FakeRestAlarm alarm;
    late TestClock clock;

    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        restAlarmProvider.overrideWithValue(alarm),
        workoutClockProvider.overrideWithValue(clock.call),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    Future<String?> setting(String key) => db.readSetting(key);

    setUp(() {
      db = openTestDb();
      alarm = FakeRestAlarm();
      clock = TestClock(t0);
    });
    tearDown(() => db.close());

    test('start: persists the end timestamp + id, schedules the notification, asks permission once', () async {
      final c = container();
      await c.read(restTimerProvider.notifier).start(90);
      final s = c.read(restTimerProvider)!;
      expect(s.endsAt, t0.add(const Duration(seconds: 90)));
      expect(alarm.scheduled, {s.notificationId: s.endsAt});
      expect(jsonDecode((await setting(WorkoutSettingsKeys.restEndsAt))!), s.endsAt.toIso8601String());
      expect(jsonDecode((await setting(WorkoutSettingsKeys.restNotificationId))!), s.notificationId);
      expect(alarm.permissionRequests, 1);

      await c.read(restTimerProvider.notifier).start(60); // restart: old one cancelled
      expect(alarm.cancelled, [s.notificationId]);
      expect(alarm.scheduled.keys, [c.read(restTimerProvider)!.notificationId]);
      expect(alarm.permissionRequests, 1);
    });

    test('+15 / −15 move endsAt and reschedule; skip cancels and clears', () async {
      final c = container();
      final n = c.read(restTimerProvider.notifier);
      await n.start(90);
      final id = c.read(restTimerProvider)!.notificationId;

      await n.adjust(15);
      expect(c.read(restTimerProvider)!.endsAt, t0.add(const Duration(seconds: 105)));
      expect(alarm.scheduled[id], t0.add(const Duration(seconds: 105)));
      await n.adjust(-15);
      expect(alarm.scheduled[id], t0.add(const Duration(seconds: 90)));

      await n.skip();
      expect(c.read(restTimerProvider), isNull);
      expect(alarm.cancelled, contains(id));
      expect(jsonDecode((await setting(WorkoutSettingsKeys.restEndsAt))!), isNull);
    });

    test('−15 past zero ends the rest', () async {
      final c = container();
      await c.read(restTimerProvider.notifier).start(10);
      await c.read(restTimerProvider.notifier).adjust(-15);
      expect(c.read(restTimerProvider), isNull);
    });

    test('survives an app kill: a new container restores it from settings', () async {
      final c1 = container();
      await c1.read(restTimerProvider.notifier).start(90);
      final before = c1.read(restTimerProvider)!;
      c1.dispose(); // "kill"

      clock.advance(const Duration(seconds: 30));
      final c2 = container();
      c2.read(restTimerProvider);
      await pumpEventQueue();
      final after = c2.read(restTimerProvider)!;
      expect(after.endsAt, before.endsAt);
      expect(after.notificationId, before.notificationId);
      expect(after.remaining(clock.now), const Duration(seconds: 60));
    });

    test('a rest that ended while the app was dead is cleared on launch', () async {
      final c1 = container();
      await c1.read(restTimerProvider.notifier).start(90);
      c1.dispose();

      clock.advance(const Duration(minutes: 3));
      final c2 = container();
      c2.read(restTimerProvider);
      await pumpEventQueue();
      expect(c2.read(restTimerProvider), isNull);
      expect(jsonDecode((await setting(WorkoutSettingsKeys.restEndsAt))!), isNull);
    });
  });

  testWidgets('reaching zero in-app clears the timer; Android without exact alarms shows the notification now',
      (tester) async {
    final db = openTestDb();
    final alarm = FakeRestAlarm()..late = true;
    final clock = TestClock(t0);
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(alarm),
      workoutClockProvider.overrideWithValue(clock.call),
    ]);
    // Everything runs in the fake-async zone (in-memory drift completes in microtasks).
    unawaited(c.read(restTimerProvider.notifier).start(5));
    await tester.pump();
    final id = c.read(restTimerProvider)!.notificationId;

    clock.advance(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(c.read(restTimerProvider), isNull);
    expect(alarm.shown, [id]);
    expect(alarm.cancelled, [id]);

    c.dispose();
    unawaited(db.close());
    await tester.pump();
  });
}
