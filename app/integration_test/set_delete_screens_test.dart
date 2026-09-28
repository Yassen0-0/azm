// Parity screenshots of deleting a set (CLAUDE.md → Platform Parity Rule).
//   tools/screenshots.sh set_delete
// Seeds the ON-DEVICE database of the test emulator/simulator: step 1 wipes
// all workouts, then an active workout (bench: W ✓, 60×8 ✓, 62.5×6 ✓,
// 62.5×5; squat: one set) and a routine are written; teardown removes them.
import 'dart:async';
import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/set_row.dart';
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

const _bench = '0025';
const _squat = '0043';
const _routineName = 'Push · screenshot seed';

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

AppLocalizations _l10n(ProviderContainer c) =>
    lookupAppLocalizations(c.read(appSettingsProvider).forcedLocale ?? AzmLocales.en);

bool _rtl(WidgetTester tester) => Directionality.of(tester.element(find.byType(Scaffold).first)) == TextDirection.rtl;

/// Toward the START edge: left in English, right in Arabic.
Offset _toStart(WidgetTester tester, double dx) => Offset(_rtl(tester) ? dx : -dx, 0);

Future<void> _clearSnackBars(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
  await _pumpFor(tester, 300);
}

Future<void> _wipe(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await c.read(restTimerProvider.notifier).skip();
  await db.delete(db.workouts).go(); // cascades to exercises + sets
  await (db.delete(db.routines)..where((r) => r.name.equals(_routineName))).go();
  await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
  await db.writeSetting(WorkoutSettingsKeys.exactAlarmsAsked, jsonEncode(true));
}

/// Bench: W 40×12 ✓, 60×8 ✓, 62.5×6 ✓, 62.5×5 (no ✓). Squat: 100×5 (no ✓).
Future<List<String>> _seedActive(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  final repo = c.read(workoutRepositoryProvider);
  final id = await repo.startEmpty(_l10n(c).workoutNameEvening);
  await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
    WorkoutsCompanion(startedAt: Value(DateTime.now().toUtc().subtract(const Duration(minutes: 18, seconds: 12)))),
  );
  await repo.addExercises(id, [_bench, _squat]);
  var d = (await repo.loadDetail(id))!;
  for (var i = 0; i < 3; i++) {
    await repo.addSet(d.exercises[0].entry.id);
  }
  d = (await repo.loadDetail(id))!;
  final b = d.exercises[0].sets;
  await repo.updateSet(b[0].id, type: SetType.warmup);
  await repo.setCompleted(b[0].id, true, weightKg: 40, reps: 12);
  await repo.setCompleted(b[1].id, true, weightKg: 60, reps: 8);
  await repo.setCompleted(b[2].id, true, weightKg: 62.5, reps: 6);
  await repo.updateSet(b[3].id, weightKg: 62.5, reps: 5);
  await repo.updateSet(d.exercises[1].sets.single.id, weightKg: 100, reps: 5);
  return [for (final s in b) s.id];
}

Future<void> _openActive(WidgetTester tester, GoRouter router) async {
  unawaited(router.push(AppRoutes.activeWorkout));
  await _pumpFor(tester);
}

/// Drags set [id] toward the START edge by [fraction] of the row width, in
/// small steps like a finger, and (unless [release]) keeps the finger down.
Future<TestGesture?> _drag(WidgetTester tester, String id, double fraction, {bool release = false}) async {
  final width = tester.getSize(find.byKey(SetRow.rowKey(id))).width;
  final g = await tester.startGesture(tester.getCenter(find.byKey(ValueKey('set-reps-$id'))));
  const steps = 24;
  for (var i = 0; i < steps; i++) {
    await g.moveBy(_toStart(tester, width * fraction / steps));
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (!release) return g;
  await tester.pump(const Duration(milliseconds: 120)); // finger rests: no fling
  await g.up();
  await _pumpFor(tester, 600);
  return null;
}

void main() {
  ActiveWorkoutBarSlot.autoResume = false;
  TestGesture? held;
  var bench = <String>[];

  Future<void> release(WidgetTester tester) async {
    await held?.cancel();
    held = null;
    await _pumpFor(tester, 400);
  }

  runScreenshotSuite('set_delete', [
    // Mid-swipe (~45 %): the whole row follows the finger; the red panel
    // grows from the END edge to the screen edge with "Delete" + trash.
    ScreenStep('swipe_mid', (tester, c, router) async {
      await _wipe(c);
      addTearDown(() => _wipe(c));
      bench = await _seedActive(c);
      await _openActive(tester, router);
      held = await _drag(tester, bench[2], 0.45);
    }),
    // Past 60 %: released here it deletes (light haptic at the threshold).
    ScreenStep('swipe_past_threshold', (tester, c, router) async {
      await release(tester);
      await _openActive(tester, router);
      held = await _drag(tester, bench[2], 0.7);
    }),
    // Released after ~35 %: the row rests open on the Delete button.
    ScreenStep('swipe_open', (tester, c, router) async {
      await release(tester);
      await _openActive(tester, router);
      await _drag(tester, bench[2], 0.35, release: true);
    }),
    // Long-press fallback: set menu → Delete set.
    ScreenStep('long_press_menu', (tester, c, router) async {
      await _openActive(tester, router);
      await tester.longPress(find.byKey(SetRow.rowKey(bench[2])));
    }),
    // Full swipe: slides out, the height collapses, the rest renumber
    // (1, 2), Lifted drops, Undo for ~4 s.
    ScreenStep('deleted_undo', (tester, c, router) async {
      await _openActive(tester, router);
      await _drag(tester, bench[2], 0.75, release: true);
      await _pumpFor(tester, 600);
    }),
    // The last set of an exercise, completed or not, deletes the same way.
    ScreenStep('last_set_deleted', (tester, c, router) async {
      await _clearSnackBars(tester);
      await _openActive(tester, router);
      final repo = c.read(workoutRepositoryProvider);
      final d = (await repo.loadDetail((await repo.active())!.id))!;
      final squatSet = d.exercises[1].sets.single.id;
      final row = find.byKey(SetRow.rowKey(squatSet));
      await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
      await _pumpFor(tester, 300);
      await tester.longPress(row);
      await _pumpFor(tester, 600);
      await tester.tap(find.byKey(SetRow.menuDeleteKey));
      await _pumpFor(tester, 900);
    }),
    // Routine editor: same swipe, same Undo.
    ScreenStep('routine_editor_deleted', (tester, c, router) async {
      await _clearSnackBars(tester);
      final r = c.read(routineRepositoryProvider);
      final id = await r.create(name: _routineName);
      await r.addExercises(id, [_bench]);
      final sets = (await r.loadDetail(id))!.exercises.single.sets;
      unawaited(router.push(AppRoutes.routineEditorFor(id)));
      await _pumpFor(tester);
      await _drag(tester, sets.first.id, 0.75, release: true);
      await _pumpFor(tester, 600);
    }),
  ]);
}
