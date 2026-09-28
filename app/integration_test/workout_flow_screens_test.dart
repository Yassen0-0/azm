// END-TO-END flows on a real device, in Arabic and English, through the UI:
// 1. Workout: Start workout → Add exercise (picker: 3 exercises, selection
//    order) → log sets with the keypad → ✓ → rest timer (+15, skip) → finish
//    with an unticked set ("Mark all done") → summary → Exercises tab →
//    detail shows the new history and records.
// 2. Full journey: onboarding (kg) → add a ready program (Full Body 3×) →
//    start "Full Body A" from the Workout tab (prefilled) → log sets → finish
//    ("Remove them") → History shows it → edit that past workout → PRs
//    recompute (one earlier workout is seeded so PRs have something to beat)
//    → Settings: back up (export) → wipe all user data → import that backup
//    → every user row is back, identical, and History shows the workouts.
//    Screenshots: <lang>_jNN_<name>.
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
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/exercises/ui/exercise_detail_screen.dart';
import 'package:azm/features/history/data/history_repository.dart';
import 'package:azm/features/history/ui/past_workout_screen.dart';
import 'package:azm/features/onboarding/data/onboarding_gate.dart';
import 'package:azm/features/routines/data/ready_programs.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/settings/data/app_version.dart';
import 'package:azm/features/settings/data/backup/backup_codec.dart';
import 'package:azm/features/settings/data/backup/backup_files.dart';
import 'package:azm/features/settings/data/backup/backup_service.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/workout/data/rest_timer.dart';
import 'package:azm/features/workout/data/workout_models.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:azm/features/workout/ui/active_workout_bar_slot.dart';
import 'package:azm/features/workout/ui/active_workout_screen.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
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
/// Max [tries] × 100 ms (default 5 s).
Future<void> _waitFor(WidgetTester tester, Finder f, String what, {int tries = 50}) async {
  for (var i = 0; i < tries && f.evaluate().isEmpty; i++) {
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

/// Stands in for the system share sheet and file picker (no system UI in
/// tests): export keeps the file, import "picks" that same file.
class _FileBox implements BackupFiles {
  String? fileName;
  String? text;

  @override
  Future<void> share({required String fileName, required String text, Rect? origin}) async {
    this.fileName = fileName;
    this.text = text;
  }

  @override
  Future<String?> pickText() async => text;
}

/// Every user row + the restorable settings, as backup JSON with fixed meta
/// (so two dumps compare equal when the data is identical).
Future<String> _userDataDump(AppDatabase db) async =>
    encodeBackup(await BackupService(db).snapshot(exportedAt: DateTime.utc(2000), appVersion: '-'));

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
      await _waitFor(tester, find.text(l.workoutStartEmpty), 'home');
      await tester.tap(find.text(l.workoutStartEmpty));
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

    testWidgets('full journey ($platform, ${lang.name})', (tester) async {
      final files = _FileBox();
      final container = await bootstrapApp(
        settingsOverride: AppSettings(language: lang),
        overrides: [backupFilesProvider.overrideWithValue(files)],
      );
      addTearDown(container.dispose);
      final db = container.read(appDatabaseProvider);
      addTearDown(() => unawaited(db.close()));
      final repo = container.read(workoutRepositoryProvider);
      final l = lookupAppLocalizations(lang == LanguagePref.ar ? AzmLocales.ar : AzmLocales.en);
      var shot = 0;
      Future<void> screenshot(String name) async {
        await _pump(tester, 400);
        final nn = (++shot).toString().padLeft(2, '0');
        await binding.takeScreenshot('workout_flow/$platform/${lang.name}_j${nn}_$name');
        _log('screenshot → j$name');
      }

      // Clean slate: no workouts/routines, onboarding not done, unit lb (so
      // choosing kg is a real change), no system prompts or alarm sheet.
      await container.read(restTimerProvider.notifier).skip();
      await db.delete(db.workouts).go();
      await db.delete(db.routines).go();
      await db.writeSetting(kOnboardingDoneKey, jsonEncode(false));
      await db.writeSetting(TrainingSettingsKeys.unit, jsonEncode('lb'));
      // The backup carries `locale` and import applies it live: store this
      // run's language so the round trip in step 8 keeps it.
      await db.writeSetting(SettingsKeys.locale, jsonEncode(lang.name));
      await db.writeSetting(WorkoutSettingsKeys.notificationsAsked, jsonEncode(true));
      await db.writeSetting(WorkoutSettingsKeys.exactAlarmsAsked, jsonEncode(true));
      // One earlier finished workout (3 days ago): squat 3 × (100 × 5), bench
      // 3 × (80 × 5). "Previous" (and the routine prefill) is per set index.
      final earlier = DateTime.now().toUtc().subtract(const Duration(days: 3));
      // Real UUID v4 ids, like every user record (the backup step validates them).
      final earlierId = newUuid();
      final earlierEx = [newUuid(), newUuid()];
      await db.into(db.workouts).insert(WorkoutsCompanion.insert(
            id: Value(earlierId),
            name: 'Earlier',
            startedAt: Value(earlier),
            endedAt: Value(earlier.add(const Duration(minutes: 40))),
            status: const Value(WorkoutStatus.finished),
          ));
      for (final (i, ex, kg) in [(0, '0043', 100.0), (1, '0025', 80.0)]) {
        await db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
              id: Value(earlierEx[i]),
              workoutId: earlierId,
              exerciseId: ex,
              sort: Value(i),
            ));
        for (var n = 0; n < 3; n++) {
          await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                workoutExerciseId: earlierEx[i],
                sort: Value(n),
                weightKg: Value(kg),
                reps: const Value(5),
                completedAt: Value(earlier.add(Duration(minutes: 5 + n))),
              ));
        }
      }

      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
      await _pump(tester, 1200);
      if (!Platform.isIOS) await binding.convertFlutterSurfaceToImage();
      final router = container.read(appRouterProvider);

      // 1. Onboarding (ready programs hidden → one screen): kg → "Let's go".
      //    The two routines come from the (hidden) Full Body 3× program data.
      router.go(AppRoutes.onboarding);
      await _waitFor(tester, find.byKey(const ValueKey('onboarding-unit-kg')), 'onboarding');
      await tester.tap(find.byKey(const ValueKey('onboarding-unit-kg')));
      await _pump(tester, 300);
      await screenshot('onboarding_kg');
      await tester.tap(find.byKey(const ValueKey('onboarding-start')));
      await _pump(tester, 1500);
      expect(await db.readSetting(TrainingSettingsKeys.unit), jsonEncode('kg'));
      expect(await db.readSetting(kOnboardingDoneKey), jsonEncode(true));
      final fullBody = (await container.read(readyProgramsProvider.future)).firstWhere((p) => p.id == 'full_body_3x');
      await container
          .read(routineRepositoryProvider)
          .copyProgram(fullBody, languageCode: Localizations.localeOf(tester.element(find.byType(Scaffold).first)).languageCode);
      final routines = await (db.select(db.routines)..orderBy([(r) => OrderingTerm(expression: r.sort)])).get();
      expect(routines, hasLength(2)); // Full Body 3×: days A and B, alternated

      // 2. Workout tab: "My routines" → ▶ on Full Body A (first).
      final start = find.byKey(ValueKey('routine-start-${routines.first.id}'));
      await _waitFor(tester, start, 'routine start button', tries: 100);
      await screenshot('workout_tab_routines');
      await tester.ensureVisible(start);
      await _pump(tester, 300);
      await tester.tap(start);
      await _waitFor(tester, find.text(l.workoutFinish), 'active workout from routine', tries: 100);
      final w = (await repo.active())!;
      expect(w.routineId, routines.first.id);
      var d = (await repo.loadDetail(w.id))!;
      expect([for (final e in d.exercises) e.entry.exerciseId], ['0043', '0025', '0027', '0405', '0294', '0274']);
      final squat = d.exercises.first.sets;
      // Prefilled: target reps 8, weight from the earlier workout (100 kg).
      expect([for (final s in squat) (s.weightKg, s.reps)], [(100.0, 8), (100.0, 8), (100.0, 8)]);
      await screenshot('active_from_routine');

      // 3. Log: ✓ set 1 as prefilled; set 2 via the keypad (105 × 5) then ✓.
      Future<void> tick(String setId) async {
        final row = find.byKey(ValueKey(setId));
        await tester.ensureVisible(row);
        await _pump(tester, 300);
        await tester.tap(find.descendant(of: row, matching: find.bySemanticsLabel(l.commonSetComplete)));
        await _pump(tester);
        if (find.text(l.workoutRestSkip).evaluate().isNotEmpty) {
          await tester.tap(find.text(l.workoutRestSkip));
          await _pump(tester, 300);
        }
      }

      await tick(squat[0].id);
      await tester.tap(find.byKey(ValueKey('set-weight-${squat[1].id}')));
      await _pump(tester, 300);
      await _typeOnKeypad(tester, '105');
      await tester.tap(find.text(l.commonKeypadNext));
      await tester.pump(const Duration(milliseconds: 100));
      await _typeOnKeypad(tester, '5');
      await tester.tap(find.bySemanticsLabel(l.commonKeypadHide));
      await _pump(tester);
      await tick(squat[1].id);
      d = (await repo.loadDetail(w.id))!;
      expect(
        [for (final s in d.exercises.first.sets) (s.weightKg, s.reps, s.completedAt != null)],
        [(100.0, 8, true), (105.0, 5, true), (100.0, 8, false)],
      );
      await screenshot('logged');

      // 4. Finish: 13 unticked sets → "Remove them" → summary.
      await tester.tap(find.text(l.workoutFinish));
      await _pump(tester);
      await screenshot('finish_dialog');
      await tester.tap(find.byKey(const ValueKey('workoutFinishRemoveThem')));
      await _waitFor(tester, find.text(l.workoutSummaryTitle), 'summary', tries: 100);
      final done = (await repo.loadDetail(w.id))!;
      expect(done.workout.status, WorkoutStatus.finished);
      expect(done.completedSets, 2);
      expect(done.exercises.map((e) => e.entry.exerciseId), ['0043']);
      await screenshot('summary');
      await tester.tap(find.text(l.workoutDone));
      await _pump(tester);

      // 5. History tab shows it with 2 PR sets (100 × 8: e1RM + volume;
      //    105 × 5: heaviest) versus the earlier workout.
      Future<int> prSets() async {
        final h = await container.read(historyRepositoryProvider).watchHistory().first;
        final hw = h.workouts.firstWhere((x) => x.id == w.id);
        return hw.exercises.fold<int>(0, (n, e) => n + e.prSets);
      }

      await tester.tap(find.text(l.shellTabHistory));
      final card = find.byKey(ValueKey(w.id));
      await _waitFor(tester, card, 'history card', tries: 200);
      expect(card, findsOneWidget);
      expect(await prSets(), 2);
      await screenshot('history');

      // 6. Edit the past workout: no ✓ there; 105 → 95 kg on set 2.
      await tester.tap(card);
      await _waitFor(tester, find.byType(PastWorkoutScreen), 'past workout');
      await _waitFor(tester, find.byKey(ValueKey('set-weight-${squat[1].id}')), 'past set row', tries: 100);
      expect(find.byType(PrBadge), findsNWidgets(2));
      expect(find.bySemanticsLabel(l.commonSetComplete), findsNothing);
      await screenshot('past_workout');
      await tester.tap(find.byKey(ValueKey('set-weight-${squat[1].id}')));
      await _pump(tester, 300);
      await _typeOnKeypad(tester, '95');
      await _pump(tester, 300);
      await screenshot('past_workout_keypad');
      await tester.tap(find.bySemanticsLabel(l.commonKeypadHide));
      await _pump(tester, 1500);
      final edited = (await repo.loadDetail(w.id))!.exercises.first.sets;
      expect([for (final s in edited) (s.weightKg, s.reps)], [(100.0, 8), (95.0, 5)]);

      // 7. PRs recompute: 95 × 5 beats nothing any more → 1 PR set, one 🏆.
      expect(await prSets(), 1);
      expect(find.byType(PrBadge), findsOneWidget);
      final squatRecord = (await container.read(historyRepositoryProvider).watchHistory().first)
          .records
          .firstWhere((r) => r.exerciseId == '0043');
      expect(squatRecord.bests.heaviestKg, 100);
      await screenshot('past_workout_edited');
      router.pop();
      await _pump(tester);
      await screenshot('history_after_edit');

      // 8. Backup round trip through Settings: export → wipe → import.
      final before = await _userDataDump(db);
      Future<void> tapSetting(String key) async {
        final f = find.byKey(ValueKey(key));
        await _waitFor(tester, find.byKey(const ValueKey('settings-list')), 'settings');
        await tester.scrollUntilVisible(
          f,
          200,
          scrollable: find
              .descendant(of: find.byKey(const ValueKey('settings-list')), matching: find.byType(Scrollable))
              .first,
        );
        await _pump(tester, 300);
        await tester.tap(f);
        await _pump(tester);
      }

      unawaited(router.push(AppRoutes.settings));
      await _pump(tester);
      await tapSetting('settings-export');
      for (var i = 0; i < 50 && files.text == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(files.fileName, matches(RegExp(r'^azm-backup-\d{8}-\d{4}\.json$')));
      final exported = decodeBackup(files.text!);
      // The real build version from the platform, not a constant.
      final version = await container.read(appVersionProvider.future);
      expect(exported.appVersion, version.full);
      expect(version.version, isNotEmpty);
      expect(exported.workouts.map((x) => x.id), containsAll(<String>[earlierId, w.id]));
      await screenshot('settings_exported');

      // Wipe every user table and change a restorable setting.
      await db.transaction(() async {
        await db.delete(db.workouts).go();
        await db.delete(db.routines).go();
      });
      await db.writeSetting(TrainingSettingsKeys.unit, jsonEncode('lb'));
      expect(await db.select(db.workoutSets).get(), isEmpty);
      expect(await db.select(db.routineExercises).get(), isEmpty);

      await tapSetting('settings-import');
      await _waitFor(tester, find.byKey(const ValueKey('settings-import-confirm')), 'import confirmation');
      expect(find.text(l.settingsImportCountRoutines('2')), findsOneWidget);
      expect(find.text(l.settingsImportCountWorkouts('2')), findsOneWidget);
      await screenshot('import_confirm');
      await tester.tap(find.byKey(const ValueKey('settings-import-confirm')));
      await _pump(tester, 1500);
      await _waitFor(tester, find.byType(SnackBar), 'import done');
      expect(find.text(l.settingsImportDone), findsOneWidget);
      expect(await _userDataDump(db), before);
      expect(await db.readSetting(TrainingSettingsKeys.unit), jsonEncode('kg'));
      await screenshot('import_done');

      router.pop();
      await _pump(tester);
      router.go(AppRoutes.history);
      await _waitFor(tester, find.byKey(ValueKey(w.id)), 'history card after import', tries: 200);
      expect(find.byKey(ValueKey(w.id)), findsOneWidget);
      expect(await prSets(), 1);
      await screenshot('history_after_import');
    });
  }
}
