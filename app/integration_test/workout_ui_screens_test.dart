// Parity screenshots of the Hevy-density UI overhaul (PLAN §14, CLAUDE.md →
// Platform Parity Rule): Workout tab, routine detail, live workout (pre-filled
// muted values, notes, rest line incl. OFF, sheets), editable times.
//   AZM_DEVICE_SET=A tools/screenshots.sh workout_ui
// Seeds the ON-DEVICE database of the test device: wipes workouts + routines.
import 'dart:async';
import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/history/ui/past_workout_screen.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:azm/features/workout/ui/active_workout_bar_slot.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

AppLocalizations _l10n(ProviderContainer c) =>
    lookupAppLocalizations(c.read(appSettingsProvider).forcedLocale ?? AzmLocales.en);

String? _routineId;

/// Wipes workouts + routines; seeds last week's workout and an "Upper day"
/// routine (Decline-style press 3 × 15 kg × 8, row, pulldown).
Future<void> _seed(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await c.read(restTimerProvider.notifier).skip();
  await db.delete(db.workouts).go();
  await db.delete(db.routines).go();
  await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
  await db.writeSetting(WorkoutSettingsKeys.exactAlarmsAsked, jsonEncode(true));
  final l = _l10n(c);

  final started = DateTime.now().toUtc().subtract(const Duration(days: 7));
  final wId = newUuid();
  await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        id: Value(wId),
        name: l.workoutNameEvening,
        startedAt: Value(started),
        endedAt: Value(started.add(const Duration(minutes: 52))),
        status: const Value(WorkoutStatus.finished),
      ));
  final weId = newUuid();
  await db.into(db.workoutExercises).insert(
        WorkoutExercisesCompanion.insert(id: Value(weId), workoutId: wId, exerciseId: '0025'),
      );
  for (var i = 0; i < 3; i++) {
    await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
          workoutExerciseId: weId,
          sort: Value(i),
          weightKg: const Value(15),
          reps: const Value(8),
          completedAt: Value(started.add(Duration(minutes: i + 1))),
        ));
  }

  final routines = c.read(routineRepositoryProvider);
  final rid = await routines.create(name: l.workoutNameEvening);
  await routines.addExercises(rid, ['0025', '0292', '0150']);
  final d = (await routines.loadDetail(rid))!;
  for (final e in d.exercises) {
    for (final s in e.sets) {
      await routines.updateSet(s.id, targetWeightKg: 25, targetReps: 8);
    }
  }
  _routineId = rid;
}

Future<void> _push(WidgetTester tester, GoRouter router, String location) async {
  unawaited(router.push(location));
  await _pumpFor(tester);
}

Future<WorkoutDetail> _active(ProviderContainer c) async {
  final repo = c.read(workoutRepositoryProvider);
  final w = await repo.active();
  if (w != null) return (await repo.loadDetail(w.id))!;
  final r = await c.read(routineRepositoryProvider).start(_routineId!, fallbackName: 'x');
  await (c.read(appDatabaseProvider).update(c.read(appDatabaseProvider).workouts)
        ..where((x) => x.id.equals(r.workoutId)))
      .write(WorkoutsCompanion(startedAt: Value(DateTime.now().toUtc().subtract(const Duration(minutes: 12)))));
  return (await repo.loadDetail(r.workoutId))!;
}

void main() {
  ActiveWorkoutBarSlot.autoResume = false;

  runScreenshotSuite('workout_ui', [
    ScreenStep('workout_tab', (tester, c, router) async {
      await _seed(c);
      router.go(AppRoutes.workout);
    }),
    ScreenStep('routine_detail', (tester, c, router) => _push(tester, router, AppRoutes.routineDetailFor(_routineId!))),
    ScreenStep('active_prefilled', (tester, c, router) async {
      await _active(c);
      await _push(tester, router, AppRoutes.activeWorkout);
    }),
    ScreenStep('active_logged_notes_rest_off', (tester, c, router) async {
      final d = await _active(c);
      final repo = c.read(workoutRepositoryProvider);
      final bench = d.exercises.first;
      await repo.setExerciseNotes(bench.entry.id, _l10n(c).workoutNameEvening);
      await repo.setExerciseRest(d.exercises[1].entry.id, 0);
      await repo.setCompleted(bench.sets[0].id, true, weightKg: 25, reps: 8);
      await repo.updateSet(bench.sets[1].id, weightKg: 27.5, reps: 8);
      await _push(tester, router, AppRoutes.activeWorkout);
    }),
    ScreenStep('rest_picker', (tester, c, router) async {
      final d = await _active(c);
      await _push(tester, router, AppRoutes.activeWorkout);
      await tester.tap(find.byKey(ValueKey('exercise-rest-${d.exercises.first.entry.id}')));
    }),
    ScreenStep('manual_timer', (tester, c, router) async {
      await _active(c);
      await _push(tester, router, AppRoutes.activeWorkout);
      await tester.tap(find.byKey(const ValueKey('workoutTimerButton')));
    }),
    ScreenStep('start_time_sheet', (tester, c, router) async {
      await _active(c);
      await _push(tester, router, AppRoutes.activeWorkout);
      await tester.tap(find.byKey(const ValueKey('workoutElapsed')));
    }),
    ScreenStep('summary_edit_time', (tester, c, router) async {
      final d = await _active(c);
      final repo = c.read(workoutRepositoryProvider);
      await repo.finish(d.workout.id);
      router.go(AppRoutes.workoutSummaryFor(d.workout.id));
      await _pumpFor(tester);
      await tester.tap(find.byKey(const ValueKey('summaryEditTime')));
    }),
    ScreenStep('past_workout_time_sheet', (tester, c, router) async {
      final db = c.read(appDatabaseProvider);
      final last = await (db.select(db.workouts)..where((w) => w.status.equalsValue(WorkoutStatus.finished))).get();
      last.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      await _push(tester, router, AppRoutes.pastWorkoutFor(last.first.id));
      await tester.tap(find.byKey(PastWorkoutScreen.menuKey));
      await _pumpFor(tester, 500);
      await tester.tap(find.byKey(const ValueKey('pastWorkoutEditTime')));
    }),
  ]);
}
