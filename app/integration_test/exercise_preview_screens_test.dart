// Parity screenshots of the exercise quick preview (CLAUDE.md → Platform
// Parity Rule): tapping a list thumbnail opens a sheet with the looping GIF,
// from every list that shows thumbnails, in ar + en on both platforms.
//   AZM_DEVICE_SET=A tools/screenshots.sh exercise_preview
//
// Committed screenshots come from normal dev builds, which show NO media
// (fallback icon): screenshots that show Gym visual media are never committed
// (docs/LICENSES.md). When media IS configured (local check with
// tools/serve_media_dev.dart + AZM_MEDIA_BASE_URL/AZM_MEDIA_ALLOW_ALL and
// AZM_SCREENSHOT_DIR pointing into .tooling/tmp), every preview also asserts
// ON THE DEVICE that new GIF frames keep arriving, and `detail_loop` checks
// that 0053 (a GIF without a loop block, 4.5 s per cycle) is still animating
// after its first cycle.
//
// Seeds the ON-DEVICE database (dedicated test devices only): wipes workouts
// and routines, then a finished workout, an active workout and a routine,
// each with bench press (0025).
import 'dart:async';
import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_repository.dart';
import 'package:azm/core/media/exercise_media.dart';
import 'package:azm/core/media/exercise_preview_sheet.dart';
import 'package:azm/core/media/media_resolver.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
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

const _seedName = 'Preview · screenshot seed';

// ignore: avoid_print
void _log(String m) => print('[preview] $m');

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Waits (max 20 s) until [f] is on screen and hit-testable.
Future<void> _waitFor(WidgetTester tester, Finder f) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (f.hitTestable().evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(f.hitTestable(), findsWidgets, reason: 'not on screen after 20 s: $f');
}

/// Any tappable (preview-enabled) thumbnail, or exercise [id]'s.
Finder _thumb([String? id]) => id != null
    ? find.byKey(ExerciseThumbnail.previewKey(id))
    : find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('exercise-thumbnail-preview-'),
      );

/// Distinct GIF frames painted inside [scope] during [d] of real time, and how
/// many of them arrived after [after].
Future<({int frames, int late})> _frames(WidgetTester tester, Finder scope, Duration d, {Duration? after}) async {
  final seen = <int>{};
  var late = 0;
  final start = DateTime.now();
  while (DateTime.now().difference(start) < d) {
    await tester.pump(const Duration(milliseconds: 40));
    final raw = find.descendant(of: scope, matching: find.byType(RawImage));
    if (raw.evaluate().isEmpty) continue;
    final image = tester.widget<RawImage>(raw.first).image;
    if (image != null && seen.add(identityHashCode(image)) && after != null) {
      if (DateTime.now().difference(start) > after) late++;
    }
  }
  return (frames: seen.length, late: late);
}

Future<bool> _hasMedia(ProviderContainer c, String id) async {
  final e = await c.read(catalogRepositoryProvider).exercise(id);
  return e != null && c.read(mediaResolverProvider).gifFor(e) != null;
}

/// Taps a thumbnail, waits for the sheet; with media, checks it animates.
Future<void> _openPreview(WidgetTester tester, ProviderContainer c, String where, [String? id]) async {
  final thumb = _thumb(id);
  await _waitFor(tester, thumb);
  final key = tester.widget(thumb.hitTestable().first).key! as ValueKey<String>;
  await tester.tap(thumb.hitTestable().first);
  await _pumpFor(tester, 600);
  final sheet = find.byType(ExercisePreviewSheet);
  expect(sheet, findsOneWidget, reason: '$where: preview sheet');
  final exId = key.value.substring('exercise-thumbnail-preview-'.length);
  if (await _hasMedia(c, exId)) {
    final r = await _frames(tester, sheet, const Duration(milliseconds: 2500));
    _log('$where ($exId): ${r.frames} distinct GIF frames in 2.5 s');
    expect(r.frames, greaterThan(1), reason: '$where: the GIF must animate');
  }
}

Future<void> _wipeAndSeed(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await c.read(restTimerProvider.notifier).skip();
  await db.delete(db.routines).go();
  await db.delete(db.workouts).go();
  await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
  await db.writeSetting(WorkoutSettingsKeys.exactAlarmsAsked, jsonEncode(true));

  // Finished workout two days ago (past workout + stats records).
  final started = DateTime.now().toUtc().subtract(const Duration(days: 2));
  final wId = newUuid();
  await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        id: Value(wId),
        name: _seedName,
        startedAt: Value(started),
        endedAt: Value(started.add(const Duration(minutes: 50))),
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
          weightKg: const Value(60),
          reps: const Value(8),
          completedAt: Value(started.add(Duration(minutes: 5 * (i + 1)))),
        ));
  }

  final routines = c.read(routineRepositoryProvider);
  final rId = await routines.create(name: _seedName);
  await routines.addExercises(rId, ['0025', '0043']);
}

Future<String> _pastId(ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  return (await (db.select(db.workouts)..where((w) => w.name.equals(_seedName))).getSingle()).id;
}

Future<String> _routineId(ProviderContainer c) async =>
    (await c.read(routineRepositoryProvider).loadRoutines()).firstWhere((r) => r.routine.name == _seedName).routine.id;

Future<void> _push(WidgetTester tester, GoRouter router, String location) async {
  unawaited(router.push(location));
  await _pumpFor(tester);
}

void main() {
  // The suite starts a workout; don't auto-open it on each launch.
  ActiveWorkoutBarSlot.autoResume = false;

  runScreenshotSuite('exercise_preview', [
    ScreenStep('library', (tester, c, router) async {
      await _wipeAndSeed(c);
      router.go(AppRoutes.exercises);
      await _pumpFor(tester);
      await tester.enterText(find.byType(TextField).first, 'barbell bench press');
      await _pumpFor(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await _pumpFor(tester);
      await _openPreview(tester, c, 'library', '0025');
    }),
    ScreenStep('picker', (tester, c, router) async {
      await _push(tester, router, AppRoutes.exercisePicker);
      await _openPreview(tester, c, 'picker');
    }),
    ScreenStep('active_workout', (tester, c, router) async {
      final repo = c.read(workoutRepositoryProvider);
      final id = await repo.startEmpty(_seedName);
      await repo.addExercises(id, ['0025', '0043']);
      await _push(tester, router, AppRoutes.activeWorkout);
      await _openPreview(tester, c, 'active workout', '0025');
    }),
    ScreenStep('routine_editor', (tester, c, router) async {
      final active = await c.read(workoutRepositoryProvider).watchActive().first;
      if (active != null) await c.read(workoutRepositoryProvider).discard(active.id);
      await _push(tester, router, AppRoutes.routineEditorFor(await _routineId(c)));
      await _openPreview(tester, c, 'routine editor', '0025');
    }),
    ScreenStep('program', (tester, c, router) async {
      await _push(tester, router, AppRoutes.programFor('ppl'));
      await _openPreview(tester, c, 'program');
    }),
    ScreenStep('past_workout', (tester, c, router) async {
      await _push(tester, router, AppRoutes.pastWorkoutFor(await _pastId(c)));
      await _openPreview(tester, c, 'past workout', '0025');
    }),
    ScreenStep('stats', (tester, c, router) async {
      await _push(tester, router, AppRoutes.stats);
      await _openPreview(tester, c, 'stats', '0025');
    }),
    ScreenStep('detail_loop', (tester, c, router) async {
      // 0053: no NETSCAPE loop block ("play once"), 18 frames, 4.5 s a cycle.
      await _push(tester, router, AppRoutes.exercise('0053'));
      if (await _hasMedia(c, '0053')) {
        final r = await _frames(
          tester,
          find.byType(ExerciseAnimation),
          const Duration(seconds: 11),
          after: const Duration(seconds: 6),
        );
        _log('detail 0053: ${r.frames} distinct frames in 11 s, ${r.late} after the first cycle');
        expect(r.late, greaterThan(0), reason: 'the play-once GIF must keep looping on the detail screen');
      }
    }),
  ]);
}
