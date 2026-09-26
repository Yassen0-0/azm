// Parity screenshots of the workout feature (CLAUDE.md → Platform Parity Rule).
//   AZM_DEVICE_SET=B tools/screenshots.sh workout
// Seeds the ON-DEVICE database of the test emulator/simulator: step 1 wipes
// all workouts, then a finished "last time" workout + an active workout with
// warm-up / normal / drop / failure sets, some ✓ and a PR are written.
import 'dart:async';
import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:azm/features/workout/ui/active_workout_bar_slot.dart';
import 'package:azm/features/workout/ui/active_workout_screen.dart';
import 'package:azm/features/workout/ui/workout_sheets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screenshot_harness.dart';

const _bench = '0025';
const _squat = '0043';

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

AppLocalizations _l10n(ProviderContainer c) =>
    lookupAppLocalizations(c.read(appSettingsProvider).forcedLocale ?? AzmLocales.en);

Future<void> _wipe(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await c.read(restTimerProvider.notifier).skip();
  await db.delete(db.workouts).go(); // cascades to exercises + sets
  // No permission prompt / exact-alarm sheet over the screenshots.
  await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
  await db.writeSetting(WorkoutSettingsKeys.exactAlarmsAsked, jsonEncode(true));
}

/// A finished workout two days ago: bench 40×12 (W), 60×8, 60×8; squat 100×5 ×3.
Future<void> _seedHistory(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  final started = DateTime.now().toUtc().subtract(const Duration(days: 2));
  final wId = newUuid();
  await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        id: Value(wId),
        name: _l10n(c).workoutNameEvening,
        startedAt: Value(started),
        endedAt: Value(started.add(const Duration(minutes: 55))),
        status: const Value(WorkoutStatus.finished),
      ));
  Future<void> ex(String exId, int sort, List<(double, int, SetType)> sets) async {
    final weId = newUuid();
    await db.into(db.workoutExercises).insert(
          WorkoutExercisesCompanion.insert(id: Value(weId), workoutId: wId, exerciseId: exId, sort: Value(sort)),
        );
    for (var i = 0; i < sets.length; i++) {
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            workoutExerciseId: weId,
            sort: Value(i),
            type: Value(sets[i].$3),
            weightKg: Value(sets[i].$1),
            reps: Value(sets[i].$2),
            completedAt: Value(started.add(Duration(minutes: 5 * (i + 1)))),
          ));
    }
  }

  await ex(_bench, 0, [(40, 12, SetType.warmup), (60, 8, SetType.normal), (60, 8, SetType.normal)]);
  await ex(_squat, 1, [(100, 5, SetType.normal), (100, 5, SetType.normal), (100, 5, SetType.normal)]);
}

/// Active workout started 23 min ago. Bench: W 40×12 ✓, 62.5×8 ✓ (PR), empty
/// (hints from last time), drop 50×10. Squat: 100×5 ✓, failure set empty.
Future<String> _seedActive(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  final repo = c.read(workoutRepositoryProvider);
  final id = await repo.startEmpty(_l10n(c).workoutNameEvening);
  await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
    WorkoutsCompanion(startedAt: Value(DateTime.now().toUtc().subtract(const Duration(minutes: 23, seconds: 41)))),
  );
  await repo.addExercises(id, [_bench, _squat]);
  var d = (await repo.loadDetail(id))!;
  await repo.addSet(d.exercises[0].entry.id); // 4th bench set
  d = (await repo.loadDetail(id))!;
  final bench = d.exercises[0].sets;
  final squat = d.exercises[1].sets;
  await repo.setCompleted(bench[0].id, true, weightKg: 40, reps: 12);
  await repo.setCompleted(bench[1].id, true, weightKg: 62.5, reps: 8);
  await repo.updateSet(bench[3].id, type: SetType.drop, weightKg: 50, reps: 10);
  await repo.setCompleted(squat[0].id, true, weightKg: 100, reps: 5);
  await repo.updateSet(squat[2].id, type: SetType.failure);
  return id;
}

Future<void> _openActive(WidgetTester tester, GoRouter router) async {
  unawaited(router.push(AppRoutes.activeWorkout));
  await _pumpFor(tester);
}

void main() {
  // The suite seeds an active workout; don't auto-open it on each launch.
  ActiveWorkoutBarSlot.autoResume = false;

  runScreenshotSuite('workout', [
    ScreenStep('home', (tester, c, router) async {
      await _wipe(c);
      router.go(AppRoutes.workout);
    }),
    ScreenStep('active_workout', (tester, c, router) async {
      await _seedHistory(c);
      await _seedActive(c);
      await _openActive(tester, router);
    }),
    ScreenStep('set_type_menu', (tester, c, router) async {
      await _openActive(tester, router);
      await tester.tap(find.descendant(of: find.byType(SetRow).at(2), matching: find.text('2')));
    }),
    ScreenStep('keypad', (tester, c, router) async {
      await _openActive(tester, router);
      // Weight cell of bench set 3 (shows last time's 60 as a hint), then 6, 5.
      await tester.tap(find.descendant(of: find.byType(SetRow).at(2), matching: find.text('60')));
      await _pumpFor(tester, 400);
      await tester.tap(find.text('6').last);
      await tester.tap(find.text('5').last);
    }),
    ScreenStep('rest_timer', (tester, c, router) async {
      await c.read(restTimerProvider.notifier).start(120);
      await _openActive(tester, router);
    }),
    ScreenStep('minimized_bar', (tester, c, router) async {
      router.go(AppRoutes.history);
    }),
    // Bench set 3, squat sets 2 + 3 have no ✓ (the failure set is empty).
    ScreenStep('finish_unticked_dialog', (tester, c, router) async {
      await _openActive(tester, router);
      await tester.tap(find.text(_l10n(c).workoutFinish));
    }),
    // Android-only in real use (exact alarms not allowed); rendered on both
    // platforms here for layout parity.
    ScreenStep('exact_alarm_sheet', (tester, c, router) async {
      await _openActive(tester, router);
      unawaited(showExactAlarmSheet(tester.element(find.byType(ActiveWorkoutScreen))));
    }),
    ScreenStep('summary', (tester, c, router) async {
      final repo = c.read(workoutRepositoryProvider);
      final id = (await repo.active())!.id;
      await c.read(restTimerProvider.notifier).skip();
      final d = (await repo.loadDetail(id))!;
      final bench = d.exercises[0].sets;
      final squat = d.exercises[1].sets;
      await repo.setCompleted(bench[2].id, true, weightKg: 65, reps: 6);
      await repo.setCompleted(bench[3].id, true);
      await repo.setCompleted(squat[1].id, true, weightKg: 100, reps: 5);
      await repo.setCompleted(squat[2].id, true, weightKg: 100, reps: 4);
      await (c.read(appDatabaseProvider).update(c.read(appDatabaseProvider).workouts)
            ..where((w) => w.id.equals(id)))
          .write(WorkoutsCompanion(startedAt: Value(DateTime.now().toUtc().subtract(const Duration(minutes: 52, seconds: 8)))));
      await repo.finish(id);
      router.go(AppRoutes.workoutSummaryFor(id));
    }),
  ]);
}
