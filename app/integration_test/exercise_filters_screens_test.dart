// Parity screenshots of the library filters (Place / Muscle group /
// Equipment) in the library and the exercise picker.
//   tools/screenshots.sh exercise_filters
// Clears the remembered filters of both screens before and after the run, so
// other suites always start unfiltered.
import 'dart:async' show unawaited;

import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/features/exercises/data/exercise_filters.dart';
import 'package:azm/features/exercises/ui/filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _waitFor(WidgetTester tester, Finder f, {Duration max = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(max);
  while (f.hitTestable().evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(f.hitTestable(), findsWidgets, reason: 'not on screen after ${max.inSeconds} s');
  await _pumpFor(tester);
}

Future<void> _clearSaved(ProviderContainer c) async {
  final store = c.read(exerciseFilterStoreProvider);
  for (final s in FilterScreen.values) {
    await store.save(s, ExerciseFilters.none);
  }
}

Future<void> _open(WidgetTester tester, FilterKind k) async {
  await tester.tap(find.byKey(FilterKeys.chip(k)));
  await _pumpFor(tester, 40);
}

Future<void> _card(WidgetTester tester, FilterKind k, String id) async {
  final card = find.byKey(FilterKeys.card(k, id));
  await tester.scrollUntilVisible(
    card.hitTestable(),
    120,
    scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first,
  );
  await tester.tap(card);
  await _pumpFor(tester, 12);
}

Future<void> _apply(WidgetTester tester, FilterKind k, List<String> ids) async {
  await _open(tester, k);
  for (final id in ids) {
    await _card(tester, k, id);
  }
  await tester.tap(find.byKey(FilterKeys.showResults));
  await _pumpFor(tester, 40);
}

void main() => runScreenshotSuite('exercise_filters', [
  ScreenStep('library_filter_bar', (tester, c, router) async {
    await _clearSaved(c);
    addTearDown(() => _clearSaved(c));
    router.go(AppRoutes.exercises);
    await _waitFor(tester, find.byType(ExerciseCard));
  }),
  ScreenStep('place_sheet', (tester, c, router) async {
    await _open(tester, FilterKind.place);
    await _card(tester, FilterKind.place, 'home');
  }),
  ScreenStep('muscle_sheet_upper', (tester, c, router) async {
    await _open(tester, FilterKind.muscle);
    await _card(tester, FilterKind.muscle, 'chest');
    await _card(tester, FilterKind.muscle, 'triceps');
    final list = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    tester.state<ScrollableState>(list).position.jumpTo(0);
  }),
  ScreenStep('muscle_sheet_lower', (tester, c, router) async {
    await _open(tester, FilterKind.muscle);
    await _card(tester, FilterKind.muscle, 'quads');
    await _card(tester, FilterKind.muscle, 'glutes');
    await _card(tester, FilterKind.muscle, 'full_body');
    final list = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    final p = tester.state<ScrollableState>(list).position;
    p.jumpTo(p.maxScrollExtent);
  }),
  ScreenStep('equipment_sheet', (tester, c, router) async {
    await _open(tester, FilterKind.equipment);
    await _card(tester, FilterKind.equipment, 'dumbbell');
    await _card(tester, FilterKind.equipment, 'resistance_band');
  }),
  ScreenStep('library_filtered', (tester, c, router) async {
    await _apply(tester, FilterKind.place, ['home']);
    await _apply(tester, FilterKind.muscle, ['chest', 'triceps']);
    await _apply(tester, FilterKind.equipment, ['dumbbell']);
  }),
  ScreenStep('library_filtered_search', (tester, c, router) async {
    await tester.enterText(find.byType(TextField).first, 'press');
    await _pumpFor(tester);
    FocusManager.instance.primaryFocus?.unfocus();
  }),
  ScreenStep('picker_own_filters', (tester, c, router) async {
    await tester.enterText(find.byType(TextField).first, '');
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(router.push<List<String>>(AppRoutes.exercisePicker));
    await _waitFor(tester, find.byType(ExerciseCard));
    await _apply(tester, FilterKind.place, ['bands']);
  }),
]);
