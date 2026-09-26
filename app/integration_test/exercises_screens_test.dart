// Screens of the exercises feature (library, equipment sheet, picker, detail),
// captured by tools/screenshots.sh exercises on both platforms in ar + en.
// Also measures catalog search latency ON THE DEVICE ([perf] lines; run
// `flutter drive` directly to see them, screenshots.sh filters the output).
import 'dart:async' show unawaited;

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_repository.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/core/widgets/muscle_chips.dart';
import 'package:azm/features/exercises/data/exercise_library.dart';
import 'package:azm/features/exercises/data/exercise_search_index.dart';
import 'package:azm/features/exercises/ui/exercise_detail_screen.dart';
import 'package:azm/features/exercises/ui/exercise_progress_chart.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_harness.dart';

// ignore: avoid_print
void _log(String m) => print('[perf] $m');

/// Marks seeded workouts so they can be removed again.
const _seedName = 'Push · screenshot seed';

List<String> _visibleCardIds(WidgetTester tester) => [
  for (final e in find.byType(ExerciseCard).hitTestable().evaluate()) (e.widget as ExerciseCard).exercise.id,
];

Future<void> _pumpFor(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Jumps the muscle chip row to its start or end.
Future<void> _chipsTo(WidgetTester tester, {required bool end}) async {
  final row = find.descendant(of: find.byType(MuscleChips), matching: find.byType(Scrollable)).first;
  final p = tester.state<ScrollableState>(row).position;
  p.jumpTo(end ? p.maxScrollExtent : 0);
  await _pumpFor(tester);
}

Future<void> _typeSearch(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await _pumpFor(tester);
  // Hide the (test) keyboard so the list is visible.
  FocusManager.instance.primaryFocus?.unfocus();
  await _pumpFor(tester);
}

Future<void> _measureSearch(ProviderContainer container) async {
  final repo = container.read(catalogRepositoryProvider);
  final cases = <ExerciseQuery>[
    const ExerciseQuery(),
    const ExerciseQuery(text: 'بنش'),
    const ExerciseQuery(text: 'ضغط بار'),
    const ExerciseQuery(text: 'barbell bench press'),
    const ExerciseQuery(text: 'a'),
    const ExerciseQuery(text: 'ر'),
    const ExerciseQuery(text: 'curl', target: 'biceps'),
    const ExerciseQuery(target: 'pectorals', equipment: 'barbell'),
  ];
  final load = Stopwatch()..start();
  final index = await ExerciseSearchIndex.load(repo);
  _log('index load (once per app run): ${load.elapsedMilliseconds} ms, ${index.length} rows');

  var worst = 0;
  for (final q in cases) {
    index.search(q); // warm-up (debug builds JIT-compile on first use)
    final times = <int>[];
    var n = 0;
    for (var i = 0; i < 5; i++) {
      final sw = Stopwatch()..start();
      n = index.search(q).length;
      times.add(sw.elapsedMicroseconds);
    }
    times.sort();
    if (times.last > worst) worst = times.last;
    final repoSw = Stopwatch()..start();
    await repo.search(q.text, target: q.target, equipment: q.equipment);
    _log(
      'search "${q.text}" target=${q.target} equipment=${q.equipment} → $n rows: '
      'index median ${(times[2] / 1000).toStringAsFixed(2)} ms, max ${(times.last / 1000).toStringAsFixed(2)} ms '
      '(repository ${repoSw.elapsedMilliseconds} ms)',
    );
  }
  _log('WORST index query ${(worst / 1000).toStringAsFixed(2)} ms (budget 50 ms)');
  expect(worst, lessThan(50000), reason: 'search must stay under 50 ms');
}

Future<void> _removeSeed(AppDatabase db) => (db.delete(db.workouts)..where((w) => w.name.equals(_seedName))).go();

Future<void> _seedHistory(AppDatabase db) async {
  await _removeSeed(db);
  final now = DateTime.now().toUtc();
  final sessions = <List<(SetType, double, int)>>[
    [(SetType.warmup, 40, 10), (SetType.normal, 60, 8), (SetType.normal, 60, 8), (SetType.normal, 60, 7)],
    [(SetType.warmup, 40, 10), (SetType.normal, 62.5, 8), (SetType.normal, 62.5, 7), (SetType.drop, 50, 10)],
    [(SetType.warmup, 40, 10), (SetType.normal, 65, 6), (SetType.normal, 65, 6), (SetType.normal, 62.5, 8)],
    [(SetType.warmup, 45, 8), (SetType.normal, 70, 5), (SetType.normal, 67.5, 6), (SetType.failure, 60, 9)],
  ];
  for (final (i, sets) in sessions.indexed) {
    final started = now.subtract(Duration(days: 7 * (sessions.length - i)));
    final w = await db
        .into(db.workouts)
        .insertReturning(
          WorkoutsCompanion.insert(
            name: _seedName,
            startedAt: Value(started),
            endedAt: Value(started.add(const Duration(hours: 1))),
            status: const Value(WorkoutStatus.finished),
          ),
        );
    final we = await db
        .into(db.workoutExercises)
        .insertReturning(WorkoutExercisesCompanion.insert(workoutId: w.id, exerciseId: '0025'));
    for (final (j, (type, kg, reps)) in sets.indexed) {
      await db
          .into(db.workoutSets)
          .insert(
            WorkoutSetsCompanion.insert(
              workoutExerciseId: we.id,
              sort: Value(j),
              type: Value(type),
              weightKg: Value(kg),
              reps: Value(reps),
              completedAt: Value(started.add(Duration(minutes: j + 1))),
            ),
          );
    }
  }
}

void main() => runScreenshotSuite('exercises', [
  ScreenStep('library', (tester, container, router) async {
    await _removeSeed(container.read(appDatabaseProvider));
    await _measureSearch(container);
    router.go(AppRoutes.exercises);
  }),
  ScreenStep('library_more_muscles', (tester, container, router) async {
    final ar = Localizations.localeOf(tester.element(find.byType(TextField).first)).languageCode == 'ar';
    await _chipsTo(tester, end: true);
    await tester.tap(find.text(ar ? 'المزيد' : 'More'));
    await _pumpFor(tester, 20);
    // Show the expanded rare muscles; jump twice because the first jump uses
    // an extent estimated before the new chips were laid out.
    await _chipsTo(tester, end: true);
    await _chipsTo(tester, end: true);
  }),
  ScreenStep('library_search_ar', (tester, container, router) async {
    await _chipsTo(tester, end: false);
    await _typeSearch(tester, 'بنش');
  }),
  ScreenStep('equipment_sheet', (tester, container, router) async {
    await tester.tap(find.byIcon(Icons.close_rounded)); // clear the search
    await _pumpFor(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _pumpFor(tester);
    await tester.tap(find.byIcon(Icons.tune_rounded));
  }),
  ScreenStep('library_filtered', (tester, container, router) async {
    // The harness closed the sheet after the last capture: reopen it,
    // pick "Barbell", then the chest chip.
    final ar = Localizations.localeOf(tester.element(find.byType(TextField).first)).languageCode == 'ar';
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await _pumpFor(tester, 30);
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(ar ? 'بار' : 'Barbell')));
    await _pumpFor(tester, 30);
    await tester.tap(find.text(ar ? 'صدر' : 'Chest').first);
  }),
  ScreenStep('picker_3_selected', (tester, container, router) async {
    unawaited(router.push<List<String>>(AppRoutes.exercisePicker));
    await _pumpFor(tester, 40);
    await _typeSearch(tester, 'بار');
    final ids = _visibleCardIds(tester);
    // Select out of list order so the numbers 1-2-3 are visibly the tap order.
    for (final id in [ids[2], ids[0], ids[3]]) {
      await tester.tap(find.byKey(ValueKey(id)));
      await _pumpFor(tester, 10);
    }
  }),
  ScreenStep.push('detail_fallback', AppRoutes.exercise('0025')),
  ScreenStep('detail_history', (tester, container, router) async {
    final db = container.read(appDatabaseProvider);
    await _seedHistory(db);
    addTearDown(() => _removeSeed(db));
    unawaited(router.push(AppRoutes.exercise('0025')));
  }),
  ScreenStep('detail_history_scrolled', (tester, container, router) async {
    unawaited(router.push(AppRoutes.exercise('0025')));
    await _pumpFor(tester, 40);
    final page = find.descendant(of: find.byType(ExerciseDetailScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.byType(ExerciseProgressChart), 300, scrollable: page);
    await _pumpFor(tester);
    // Chart near the top, recent history below it.
    await Scrollable.ensureVisible(tester.element(find.byType(ExerciseProgressChart)), alignment: 0.15);
  }),
]);
