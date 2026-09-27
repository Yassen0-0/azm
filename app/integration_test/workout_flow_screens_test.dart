// END-TO-END flow on a real device, in Arabic and English, through the UI only:
//   Start workout → Add exercise (picker: 3 exercises, selection order) →
//   log sets with the keypad → ✓ → rest timer (+15, skip) → finish with an
//   unticked set ("Mark all done") → summary → Exercises tab → detail shows
//   the new history and records.
// Run on both platforms with:   tools/screenshots.sh workout_flow
// Proof images land in docs/screenshots/workout_flow/<platform>/.
//
// Android: when exact alarms are not allowed (and notifications are), the
// one-time explanation sheet shows on the first rest timer. The Arabic run taps
// "Not now". The English run taps "Open settings" only with
// --dart-define=AZM_E2E_OPEN_ALARM_SETTINGS=true, and then a host script must
// press Back on the system screen (tools/ can't be changed by features; the
// script used is described in DECISIONS_LOG).
//
// It wipes all workouts of the test device DB (dedicated devices only).
import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:azm/app.dart';
import 'package:azm/bootstrap.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/features/exercises/ui/exercise_detail_screen.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:azm/features/workout/ui/active_workout_bar_slot.dart';
import 'package:azm/features/workout/ui/active_workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _openAlarmSettings = bool.fromEnvironment('AZM_E2E_OPEN_ALARM_SETTINGS');

/// Bench press, full squat, one-arm dumbbell row, picked in THIS order.
const _picks = [
  (id: '0025', ar: 'بنش', en: 'barbell bench press'),
  (id: '0043', ar: 'سكوات', en: 'barbell full squat'),
  (id: '0292', ar: 'منشار', en: 'dumbbell one arm bent-over row'),
];

/// Keypad input per exercise: weight, reps.
const _logged = [('60', '8'), ('100', '5'), ('30', '10')];

// ignore: avoid_print
void _log(String m) => print('[e2e] $m');

Future<void> _pump(WidgetTester tester, [int ms = 600]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Text without Unicode bidi isolates/marks (names and numbers are isolated).
String _plain(String s) => s.replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '');

Finder _textWhere(bool Function(String) test) => find.byWidgetPredicate((w) {
      final t = w is Text ? (w.data ?? w.textSpan?.toPlainText()) : null;
      return t != null && test(_plain(t));
    });

/// Pumps until [f] finds something (the catalog index loads asynchronously).
Future<void> _waitFor(WidgetTester tester, Finder f, String what) async {
  for (var i = 0; i < 50 && f.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (f.evaluate().isEmpty) {
    final texts = [
      for (final e in find.byType(Text).evaluate().take(40)) _plain((e.widget as Text).data ?? ''),
    ];
    _log('NOT FOUND: $what; visible texts: $texts');
  }
}

Future<void> _typeOnKeypad(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final platform = Platform.isIOS ? 'ios' : 'android';
  ActiveWorkoutBarSlot.autoResume = false;

  for (final lang in [LanguagePref.ar, LanguagePref.en]) {
    testWidgets('workout end-to-end ($platform, ${lang.name})', (tester) async {
      final container = await bootstrapApp(settingsOverride: AppSettings(language: lang));
      addTearDown(container.dispose);
      final db = container.read(appDatabaseProvider);
      // Each language run bootstraps its own DB. Awaiting close() in the test
      // zone never completes (see the workout widget tests), so don't await.
      addTearDown(() => unawaited(db.close()));
      final repo = container.read(workoutRepositoryProvider);
      final l = lookupAppLocalizations(lang == LanguagePref.ar ? AzmLocales.ar : AzmLocales.en);
      var shot = 0;
      Future<void> screenshot(String name) async {
        await _pump(tester, 400);
        final nn = (++shot).toString().padLeft(2, '0');
        await binding.takeScreenshot('workout_flow/$platform/${lang.name}_${nn}_$name');
        _log('screenshot → $name');
      }

      // Clean slate: no workouts, no system notification prompt (can't be
      // tapped from a Flutter test), exact-alarm explanation not yet shown.
      await container.read(restTimerProvider.notifier).skip();
      await db.delete(db.workouts).go();
      await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
      await (db.delete(db.settings)..where((s) => s.key.equals(WorkoutSettingsKeys.exactAlarmsAsked))).go();

      // Route text entry through the test IME: the real keyboard otherwise
      // races enterText on device and wipes the search field.
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
      await _pump(tester, 1200);
      if (!Platform.isIOS) await binding.convertFlutterSurfaceToImage();

      // 1. Start workout (one tap).
      await _waitFor(tester, find.text(l.workoutStart), 'home');
      await tester.tap(find.text(l.workoutStart));
      await _waitFor(tester, find.text(l.workoutFinish), 'active workout');
      expect(find.text(l.workoutFinish), findsOneWidget);
      final workoutId = (await repo.active())!.id;

      // 2. Picker: search + select three exercises; the order is shown.
      await _waitFor(tester, find.text(l.workoutAddExercise), 'add exercise button');
      await tester.tap(find.text(l.workoutAddExercise));
      await _waitFor(tester, find.text(l.exercisesPickerTitle), 'picker');
      expect(find.text(l.exercisesPickerTitle), findsOneWidget);
      for (final p in _picks) {
        await tester.enterText(find.byType(TextField).first, lang == LanguagePref.ar ? p.ar : p.en);
        await _pump(tester);
        FocusManager.instance.primaryFocus?.unfocus();
        await _pump(tester, 300);
        final card = find.byKey(ValueKey(p.id));
        await _waitFor(tester, card, 'picker row ${p.id}');
        await tester.ensureVisible(card);
        await tester.tap(card);
        await _pump(tester, 300);
      }
      await screenshot('picker_3_selected');
      await tester.tap(find.byKey(const ValueKey('exercisePickerConfirm')));
      await _pump(tester, 1000);

      var d = (await repo.loadDetail(workoutId))!;
      expect([for (final e in d.exercises) e.entry.exerciseId], [for (final p in _picks) p.id]);
      expect(find.byType(SetRow), findsNWidgets(3));

      // 3. Log with the keypad: weight → Next → reps → Next walks all three.
      final firstWeight = find.descendant(of: find.byType(SetRow).first, matching: find.text(l.workoutNoData)).at(1);
      await tester.tap(firstWeight);
      await _pump(tester, 300);
      for (final (w, r) in _logged) {
        await _typeOnKeypad(tester, w);
        await tester.tap(find.text(l.commonKeypadNext));
        await tester.pump(const Duration(milliseconds: 100));
        await _typeOnKeypad(tester, r);
        await tester.tap(find.text(r == _logged.last.$2 ? l.commonKeypadDone : l.commonKeypadNext));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _pump(tester);
      d = (await repo.loadDetail(workoutId))!;
      expect([for (final s in d.allSets) (s.weightKg, s.reps)], [(60.0, 8), (100.0, 5), (30.0, 10)]);

      final openSettings = _openAlarmSettings && lang == LanguagePref.en;

      // 4. ✓ all three; the first ✓ starts the rest timer.
      final setIds = [for (final s in d.allSets) s.id];
      final workoutList =
          find.descendant(of: find.byType(ActiveWorkoutScreen), matching: find.byType(Scrollable)).first;
      // The keypad's Next chain left the list scrolled to the end.
      tester.state<ScrollableState>(workoutList).position.jumpTo(0);
      await _pump(tester, 300);
      for (var i = 0; i < 3; i++) {
        // The list is lazy: on a shorter screen the third row isn't built yet.
        final row = find.byKey(ValueKey(setIds[i]));
        await tester.scrollUntilVisible(row, 150, scrollable: workoutList);
        await tester.ensureVisible(row);
        await _pump(tester, 300);
        await tester.tap(find.descendant(of: row, matching: find.bySemanticsLabel(l.commonSetComplete)));
        await _pump(tester);
        if (i == 0 && find.text(l.workoutExactAlarmTitle).evaluate().isNotEmpty) {
          _log('exact-alarm sheet shown ($platform)');
          expect(Platform.isAndroid, isTrue);
          await screenshot('exact_alarm_sheet');
          await tester.tap(find.text(openSettings ? l.workoutExactAlarmAllow : l.workoutExactAlarmLater));
          await _pump(tester, openSettings ? 8000 : 600);
          expect(await db.readSetting(WorkoutSettingsKeys.exactAlarmsAsked), 'true');
        }
      }
      d = (await repo.loadDetail(workoutId))!;
      expect(d.completedSets, 3);
      final rest = container.read(restTimerProvider);
      expect(rest, isNotNull);
      expect(find.text(l.workoutRestSkip), findsOneWidget);
      await screenshot('logged_rest_timer');

      // 5. Rest timer: +15 moves the end, Skip clears it.
      await tester.tap(find.bySemanticsLabel(l.workoutRestMore));
      await _pump(tester, 300);
      expect(container.read(restTimerProvider)!.endsAt.difference(rest!.endsAt), const Duration(seconds: 15));
      await tester.tap(find.text(l.workoutRestSkip));
      await _pump(tester, 300);
      expect(container.read(restTimerProvider), isNull);

      // 6. One more bench set (unticked copy of 60 × 8), then Finish.
      await tester.tap(find.text(l.workoutAddSet).first);
      await _pump(tester);
      await tester.tap(find.text(l.workoutFinish));
      await _pump(tester);
      expect(find.text(l.workoutFinishUncheckedBody(1, '1')), findsOneWidget);
      await screenshot('finish_unticked_dialog');
      await tester.tap(find.byKey(const ValueKey('workoutFinishMarkAllDone')));
      await _pump(tester, 1500);

      // 7. Summary.
      expect(find.text(l.workoutSummaryTitle), findsOneWidget);
      final done = (await repo.loadDetail(workoutId))!;
      expect(done.workout.status, WorkoutStatus.finished);
      expect(done.completedSets, 4);
      expect(await repo.active(), isNull);
      await screenshot('summary');
      await tester.tap(find.text(l.workoutDone));
      await _pump(tester);

      // 8. Exercises tab → bench press → detail: new history + records.
      await tester.tap(find.text(l.shellTabExercises));
      await _pump(tester);
      await tester.enterText(find.byType(TextField).first, lang == LanguagePref.ar ? 'بنش' : 'barbell bench press');
      await _pump(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await _pump(tester, 300);
      // The library row carries the new record badge (heaviest = 60 kg).
      expect(
        find.descendant(of: find.byKey(const ValueKey('0025')), matching: _textWhere((t) => t.contains('60'))),
        findsWidgets,
      );
      await tester.tap(find.byKey(const ValueKey('0025')));
      await _waitFor(tester, find.text(l.exercisesDetailRecords), 'detail');
      expect(find.text(l.exercisesDetailRecords), findsOneWidget);
      // Records load from the history stream after the section titles.
      final heaviest = find.descendant(of: find.byType(ExerciseDetailScreen), matching: _textWhere((t) => t.startsWith('60')));
      await _waitFor(tester, heaviest, 'heaviest record 60');
      expect(heaviest, findsWidgets);
      expect(find.text(l.exercisesHistoryEmpty), findsNothing);
      await screenshot('detail_records');
      final detailList = find
          .descendant(of: find.byType(ExerciseDetailScreen), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(find.byKey(ExerciseDetailScreen.historyKey), 200, scrollable: detailList);
      await tester.drag(detailList, const Offset(0, -200));
      await _pump(tester);
      // Two sets of 60 × 8 in today's session.
      expect(_textWhere((t) => t.contains('60') && t.contains('8') && t.contains('×')), findsWidgets);
      await screenshot('detail_history');
    });
  }
}
