// Parity screenshots of routines (CLAUDE.md → Platform Parity Rule). Ready
// programs are hidden (kProgramsEnabled): see programs_screens_test.dart.
//   AZM_DEVICE_SET=A tools/screenshots.sh routines
// Seeds the ON-DEVICE database of the test emulator/simulator (dedicated
// devices only): step 1 wipes routines + workouts; later steps copy a ready
// program and build a custom routine with targets.
import 'dart:async';
import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/exercises/ui/exercise_picker_screen.dart';
import 'package:azm/features/routines/data/ready_programs.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/ui/active_workout_bar_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

String _lang(ProviderContainer c) => (c.read(appSettingsProvider).forcedLocale ?? AzmLocales.en).languageCode;

Future<void> _wipe(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await c.read(restTimerProvider.notifier).skip();
  await db.delete(db.routines).go(); // cascades to exercises + sets
  await db.delete(db.workouts).go();
  await c.read(trainingSettingsWriterProvider).setWeightUnit(WeightUnit.kg);
  // No permission prompt / exact-alarm sheet over the screenshots.
  await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
  await db.writeSetting(WorkoutSettingsKeys.exactAlarmsAsked, jsonEncode(true));
}

/// Custom routine: bench (W 40×12, 3 × 60 kg × 8), squat (3 × 100 × 5, rest
/// 3:00), row (3 × 10, no weight).
Future<String> _seedCustom(ProviderContainer c) async {
  final repo = c.read(routineRepositoryProvider);
  final ar = _lang(c) == 'ar';
  final id = await repo.create(
    name: ar ? 'يوم الصدر والرجل' : 'Chest & legs',
    notes: ar ? 'زوّد 2.5 كل أسبوع' : '+2.5 kg every week',
  );
  await repo.addExercises(id, ['0025', '0043', '0292']);
  final d = (await repo.loadDetail(id))!;
  final bench = d.exercises[0], squat = d.exercises[1], row = d.exercises[2];
  await repo.updateSet(bench.sets[0].id, type: SetType.warmup, targetWeightKg: 40, targetReps: 12);
  for (final s in bench.sets.skip(1)) {
    await repo.updateSet(s.id, targetWeightKg: 60, targetReps: 8);
  }
  await repo.addSet(bench.entry.id);
  for (final s in squat.sets) {
    await repo.updateSet(s.id, targetWeightKg: 100, targetReps: 5);
  }
  await repo.setRestSeconds(squat.entry.id, 180);
  for (final s in row.sets) {
    await repo.updateSet(s.id, targetReps: 10);
  }
  return id;
}

Future<String> _customId(ProviderContainer c) async {
  final list = await c.read(routineRepositoryProvider).loadRoutines();
  final name = _lang(c) == 'ar' ? 'يوم الصدر والرجل' : 'Chest & legs';
  return list.firstWhere((r) => r.routine.name == name).routine.id;
}

void main() {
  // The suite starts a workout at the end; don't auto-open it on launch.
  ActiveWorkoutBarSlot.autoResume = false;

  runScreenshotSuite('routines', [
    ScreenStep('home_empty', (tester, c, router) async {
      await _wipe(c);
      router.go(AppRoutes.workout);
    }),
    ScreenStep('home_routines', (tester, c, router) async {
      final programs = await c.read(readyProgramsProvider.future);
      await c.read(routineRepositoryProvider).copyProgram(programs.first, languageCode: _lang(c));
      await _seedCustom(c);
      router.go(AppRoutes.workout);
    }),
    ScreenStep('routine_menu', (tester, c, router) async {
      router.go(AppRoutes.workout);
      await _pumpFor(tester);
      final menu = find.byKey(ValueKey('routine-menu-${await _customId(c)}'));
      await tester.ensureVisible(menu);
      await _pumpFor(tester, 300);
      await tester.tap(menu);
    }),
    ScreenStep('routine_detail', (tester, c, router) async {
      unawaited(router.push(AppRoutes.routineDetailFor(await _customId(c))));
    }),
    ScreenStep('editor', (tester, c, router) async {
      unawaited(router.push(AppRoutes.routineEditorFor(await _customId(c))));
    }),
    ScreenStep('editor_keypad', (tester, c, router) async {
      final id = await _customId(c);
      unawaited(router.push(AppRoutes.routineEditorFor(id)));
      await _pumpFor(tester);
      final d = (await c.read(routineRepositoryProvider).loadDetail(id))!;
      await tester.tap(find.byKey(ValueKey('set-weight-${d.exercises[0].sets[1].id}')));
      await _pumpFor(tester, 400);
      await tester.tap(find.text('6').last);
      await tester.tap(find.text('2').last);
      await tester.tap(find.text('.').last);
      await tester.tap(find.text('5').last);
    }),
    ScreenStep('rest_sheet', (tester, c, router) async {
      unawaited(router.push(AppRoutes.routineEditorFor(await _customId(c))));
      await _pumpFor(tester);
      await tester.tap(find.byIcon(Icons.timer_outlined).first);
    }),
    ScreenStep('new_routine', (tester, c, router) async {
      unawaited(router.push(AppRoutes.routineNew));
      await _pumpFor(tester);
      await tester.enterText(find.byKey(const ValueKey('routineName')), _lang(c) == 'ar' ? 'دراع' : 'Arms');
      FocusManager.instance.primaryFocus?.unfocus();
    }),
    // Real picker (exercises feature): pick two, confirm, back in the editor.
    ScreenStep('picker_return', (tester, c, router) async {
      final list = await c.read(routineRepositoryProvider).loadRoutines();
      final armsName = _lang(c) == 'ar' ? 'دراع' : 'Arms';
      final arms =
          list.where((r) => r.routine.name == armsName).firstOrNull?.routine.id ??
          await c.read(routineRepositoryProvider).create(name: armsName);
      unawaited(router.push(AppRoutes.routineEditorFor(arms)));
      await _pumpFor(tester);
      await tester.tap(find.byKey(const ValueKey('routineAddExercises')));
      await _pumpFor(tester);
      final picker = find.byType(ExercisePickerScreen);
      // One search, two picks (a second search in the same test run did not
      // refresh the results list on the emulator).
      await tester.enterText(find.descendant(of: picker, matching: find.byType(TextField)).first, 'barbell curl');
      await _pumpFor(tester, 600);
      FocusManager.instance.primaryFocus?.unfocus();
      // Wait (max 10 s) for the search results, then scroll each pick into
      // view: every row has two names now, so the 2nd pick can be below the
      // lazily built part of the list on a short screen.
      final first = find.descendant(of: picker, matching: find.byKey(const ValueKey('0031')));
      for (var i = 0; i < 50 && first.evaluate().isEmpty; i++) {
        await _pumpFor(tester, 200);
      }
      final results = find.descendant(of: picker, matching: find.byType(Scrollable)).last;
      for (final id in ['0031', '0070']) {
        final row = find.descendant(of: picker, matching: find.byKey(ValueKey(id)));
        await tester.scrollUntilVisible(row, 150, scrollable: results, maxScrolls: 40);
        await _pumpFor(tester, 300);
        await tester.tap(row.first);
        await _pumpFor(tester, 300);
      }
      await tester.tap(find.byKey(const ValueKey('exercisePickerConfirm')));
    }),
    ScreenStep('active_from_routine', (tester, c, router) async {
      final repo = c.read(routineRepositoryProvider);
      await repo.start(await _customId(c), fallbackName: '');
      unawaited(router.push(AppRoutes.activeWorkout));
    }),
  ]);
}
