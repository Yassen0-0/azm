import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/core/widgets/set_undo.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_test_helpers.dart';

/// pumpAndSettle never settles while timers tick (duration, rest bar), so
/// pump a fixed amount of fake time instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Delete a set during a workout (SPEC → Live workout logging): swipe toward
/// the START edge or long-press → "Delete set"; Undo for ~4 s; the remaining
/// sets renumber; Lifted / sets / PRs recompute; nothing counts a deleted set.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, LanguagePref lang) async {
    db = openTestDb();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(FakeRestAlarm()),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
    ]);
    await insertCatalog(db, testCatalog);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  WorkoutRepository repo() => container.read(workoutRepositoryProvider);

  /// Active workout, bench press with sets (weight, reps, ✓) in order.
  Future<(String, List<String>)> startWith(WidgetTester tester, List<(double, int, bool)> sets, {String start = 'Start workout'}) async {
    await tester.tap(find.text(start));
    await settle(tester);
    final w = (await repo().active())!.id;
    await repo().addExercises(w, ['0025']);
    final we = (await repo().loadDetail(w))!.exercises.first;
    for (var i = 1; i < sets.length; i++) {
      await repo().addSet(we.entry.id);
    }
    final ids = [for (final s in (await repo().loadDetail(w))!.exercises.first.sets) s.id];
    for (var i = 0; i < sets.length; i++) {
      await repo().updateSet(ids[i], weightKg: sets[i].$1, reps: sets[i].$2);
      if (sets[i].$3) await repo().setCompleted(ids[i], true);
    }
    await settle(tester);
    return (w, ids);
  }

  Future<List<String>> dbSetIds(String workoutId) async =>
      [for (final s in (await repo().loadDetail(workoutId))!.exercises.first.sets) s.id];

  /// Set labels as shown, top to bottom.
  List<String> labels(WidgetTester tester) => [for (final r in tester.widgetList<SetRow>(find.byType(SetRow))) r.label];

  testWidgets('swipe left deletes a ✓ set: renumbers, Lifted + sets update, Undo restores it (English)', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    final (w, ids) = await startWith(tester, [(100, 10, true), (60, 5, true), (80, 8, false)]);
    expect(labels(tester), ['1', '2', '3']);
    expect(find.text('1,300'), findsOneWidget); // Lifted: 100×10 + 60×5
    final deleted = (await repo().loadDetail(w))!.exercises.first.sets[1];

    // Toward the END edge (right in English): nothing happens.
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[1]}')), const Offset(600, 0));
    await settle(tester);
    expect(await dbSetIds(w), ids);

    // Toward the START edge (left in English): deleted at once.
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[1]}')), const Offset(-600, 0));
    await settle(tester);
    await settle(tester); // Lifted counts to its new value (600 ms)
    expect(await dbSetIds(w), [ids[0], ids[2]]);
    expect(labels(tester), ['1', '2']); // renumbered
    expect(find.text('1,000'), findsOneWidget); // live Lifted
    final d = (await repo().loadDetail(w))!;
    expect(d.completedSets, 1);
    expect(d.liftedTotalKg, 1000);
    expect(find.byKey(setDeletedSnackBarKey), findsOneWidget);
    expect(find.text('Set deleted'), findsOneWidget);

    // Undo: the same row comes back in its place, with its values and ✓.
    await tester.tap(find.text('Undo'));
    await settle(tester);
    await settle(tester);
    expect(await dbSetIds(w), ids);
    final back = (await repo().loadDetail(w))!.exercises.first.sets[1];
    expect(back, deleted);
    expect(labels(tester), ['1', '2', '3']);
    expect(find.text('1,300'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('the undo snackbar goes away on its own after ~4 s; the delete stays', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    final (w, ids) = await startWith(tester, [(60, 8, false), (60, 8, false)]);
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[0]}')), const Offset(-600, 0));
    await settle(tester);
    expect(find.byKey(setDeletedSnackBarKey), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(setDeletedSnackBarKey), findsNothing);
    expect(await dbSetIds(w), [ids[1]]);
    expect(labels(tester), ['1']);
    await tearDownApp(tester);
  });

  testWidgets('Arabic (RTL): swipe right deletes; long-press menu deletes the LAST set; Undo', (tester) async {
    await pumpApp(tester, LanguagePref.ar);
    final (w, ids) = await startWith(tester, [(60, 8, false), (50, 6, true)], start: 'ابدأ تمرين');
    expect(labels(tester), ['1', '2']);

    // Toward the end edge (LEFT in Arabic): nothing.
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[0]}')), const Offset(-600, 0));
    await settle(tester);
    expect(await dbSetIds(w), ids);
    // Toward the start edge (RIGHT in Arabic): deleted.
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[0]}')), const Offset(600, 0));
    await settle(tester);
    expect(await dbSetIds(w), [ids[1]]);
    expect(labels(tester), ['1']);
    expect(find.text('السِت اتمسح'), findsOneWidget);

    // The last remaining (✓) set, through the long-press menu.
    await tester.longPress(find.byKey(SetRow.rowKey(ids[1])));
    await settle(tester);
    expect(find.text('امسح السِت'), findsOneWidget);
    await tester.tap(find.byKey(SetRow.menuDeleteKey));
    await settle(tester);
    final d = (await repo().loadDetail(w))!;
    expect(d.exercises, hasLength(1)); // the exercise stays, with "Add set"
    expect(d.exercises.first.sets, isEmpty);
    expect(d.completedSets, 0);
    expect(find.byType(SetRow), findsNothing);

    await tester.tap(find.text('تراجع'));
    await settle(tester);
    expect(await dbSetIds(w), [ids[1]]);
    expect((await repo().loadDetail(w))!.completedSets, 1);
    expect(find.byType(SetRow), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('deleting the set on the keypad closes the keypad', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    final (w, ids) = await startWith(tester, [(60, 8, false), (70, 8, false)]);
    await tester.tap(find.byKey(ValueKey('set-reps-${ids[1]}')));
    await settle(tester);
    expect(find.bySemanticsLabel('Close keypad'), findsOneWidget);
    await tester.drag(find.byKey(ValueKey('set-weight-${ids[1]}')), const Offset(-600, 0));
    await settle(tester);
    expect(find.bySemanticsLabel('Close keypad'), findsNothing);
    expect(await dbSetIds(w), [ids[0]]);
    await tearDownApp(tester);
  });

  group('repository', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    final t0 = DateTime.utc(2026, 9, 1, 10);

    setUp(() async {
      db = openTestDb();
      repo = WorkoutRepository(db, clock: () => t0.add(const Duration(days: 10)));
      await insertCatalog(db, testCatalog);
    });
    tearDown(() => db.close());

    test('a deleted set never counts: not in PR bests, "previous" or Lifted; undo brings it back', () async {
      final past = await insertFinishedWorkout(db, startedAt: t0, exerciseId: '0025', sets: [
        (100, 5, SetType.normal),
        (140, 3, SetType.normal), // the record
      ]);
      final record = (await (db.select(db.workoutSets)..where((s) => s.weightKg.equals(140))).getSingle());
      Future<double> best() async =>
          (await repo.prBests(['0025'], before: t0.add(const Duration(days: 5))))['0025']!.heaviestKg;
      expect(await best(), 140);

      await repo.deleteSet(record.id);
      expect(await best(), 100);
      final prev = await repo.previousSets(['0025'], before: t0.add(const Duration(days: 5)));
      expect(prev['0025']!.map((s) => s.weightKg), [100]);
      expect((await repo.loadDetail(past))!.liftedTotalKg, 500);

      expect(await repo.restoreSet(record, status: WorkoutStatus.finished), isTrue);
      expect(await best(), 140);
      expect((await repo.loadDetail(past))!.liftedTotalKg, 920);
    });

    test('undo is refused once the workout is no longer active (finished / discarded)', () async {
      final w = await repo.startEmpty('W');
      await repo.addExercises(w, ['0025']);
      final we = (await repo.loadDetail(w))!.exercises.first;
      await repo.addSet(we.entry.id);
      final sets = (await repo.loadDetail(w))!.exercises.first.sets;
      await repo.setCompleted(sets[0].id, true, weightKg: 60, reps: 8);
      final gone = (await repo.loadDetail(w))!.exercises.first.sets[1];
      await repo.deleteSet(gone.id);
      expect(await repo.finish(w), isTrue);
      expect(await repo.restoreSet(gone, status: WorkoutStatus.active), isFalse);
      expect((await repo.loadDetail(w))!.allSets.map((s) => s.id), [sets[0].id]);

      await repo.discard(w);
      expect(await repo.restoreSet(gone), isFalse); // its exercise is gone
    });

    test('undo keeps the order when a new set took the deleted position', () async {
      final w = await repo.startEmpty('W');
      await repo.addExercises(w, ['0025']);
      final weId = (await repo.loadDetail(w))!.exercises.first.entry.id;
      await repo.addSet(weId);
      await repo.addSet(weId);
      final before = (await repo.loadDetail(w))!.exercises.first.sets;
      await repo.deleteSet(before[2].id);
      await repo.addSet(weId); // takes sort 2 again
      final added = (await repo.loadDetail(w))!.exercises.first.sets.last;
      expect(await repo.restoreSet(before[2], status: WorkoutStatus.active), isTrue);
      final after = (await repo.loadDetail(w))!.exercises.first.sets.map((s) => s.id).toList();
      expect(after, [before[0].id, before[1].id, before[2].id, added.id]);
      // Restoring twice is a no-op.
      expect(await repo.restoreSet(before[2], status: WorkoutStatus.active), isFalse);
    });

    test('deleting every set leaves the exercise; finish drops it', () async {
      final w = await repo.startEmpty('W');
      await repo.addExercises(w, ['0025', '0043']);
      final d = (await repo.loadDetail(w))!;
      await repo.setCompleted(d.exercises[1].sets.single.id, true, weightKg: 100, reps: 5);
      await repo.deleteSet(d.exercises[0].sets.single.id);
      final after = (await repo.loadDetail(w))!;
      expect(after.exercises.map((e) => e.sets.length), [0, 1]);
      expect(await repo.finish(w), isTrue);
      expect((await repo.loadDetail(w))!.exercises.map((e) => e.entry.exerciseId), ['0043']);
      expect(
        await (db.select(db.workoutSets)..where((s) => s.id.equals(d.exercises[0].sets.single.id))).get(),
        isEmpty,
      );
    });
  });
}
