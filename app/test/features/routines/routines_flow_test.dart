import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/feature_flags.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/features/onboarding/data/onboarding_gate.dart';
import 'package:azm/features/onboarding/ui/onboarding_screen.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/routines/ui/programs_screen.dart';
import 'package:azm/features/routines/ui/routine_detail_screen.dart';
import 'package:azm/features/routines/ui/routine_editor_screen.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/workout/data/rest_notifications.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:azm/features/workout/ui/active_workout_bar_slot.dart';
import 'package:azm/features/workout/ui/active_workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../workout/workout_test_helpers.dart' show FakeRestAlarm;
import 'routines_test_helpers.dart';

/// Timers tick on some screens, so pump fixed fake time instead of settling.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() => ActiveWorkoutBarSlot.autoResume = false);

  Future<void> pumpApp(WidgetTester tester, LanguagePref lang, {bool onboardingDone = true, bool programs = false}) async {
    db = openRoutinesTestDb();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      restAlarmProvider.overrideWithValue(FakeRestAlarm()),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
      onboardingDoneAtLaunchProvider.overrideWithValue(onboardingDone),
      // Ready programs are hidden by default (kProgramsEnabled); their tests
      // turn them back on.
      programsEnabledProvider.overrideWithValue(programs),
    ]);
    await seedRoutinesCatalog(db);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(db.close());
    await tester.pump(const Duration(seconds: 1));
  }

  RoutineRepository repo() => container.read(routineRepositoryProvider);

  testWidgets('onboarding: lb + ready program → Workout tab with the copied routines (English)', (tester) async {
    await pumpApp(tester, LanguagePref.en, onboardingDone: false, programs: true);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);

    await tester.tap(find.text('Pounds'));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(parseWeightUnit(await db.readSetting(TrainingSettingsKeys.unit)), WeightUnit.lb);

    await tester.tap(find.text('Test A/B'));
    await settle(tester);
    await tester.tap(find.text('Add program and start'));
    await settle(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('My routines (2)'), findsOneWidget);
    expect(find.text('Day A'), findsOneWidget);
    expect(find.text('Day B'), findsOneWidget);
    expect(find.text('Barbell Bench Press, Dumbbell One Arm Bent-over Row'), findsOneWidget);
    expect(await loadOnboardingDone(db), isTrue);
    await tearDownApp(tester);
  });

  testWidgets('onboarding: skip (Arabic) → empty routines state', (tester) async {
    await pumpApp(tester, LanguagePref.ar, onboardingDone: false, programs: true);
    await tester.tap(find.text('التالي'));
    await settle(tester);
    await tester.tap(find.text('تخطّى، وابدأ من غير برنامج'));
    await settle(tester);
    expect(find.text('لسه معندكش روتين'), findsOneWidget);
    expect(parseWeightUnit(await db.readSetting(TrainingSettingsKeys.unit)), WeightUnit.kg);
    expect(await db.select(db.routines).get(), isEmpty);
    await tearDownApp(tester);
  });

  testWidgets('new routine → name, targets via keypad (persisted) → back → start in one tap', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    expect(find.text('No routines yet'), findsOneWidget);

    await tester.tap(find.text('New routine'));
    await settle(tester);
    expect(find.byType(RoutineEditorScreen), findsOneWidget);
    final routineId = (await db.select(db.routines).getSingle()).id;

    await tester.enterText(find.byKey(const ValueKey('routineName')), 'Push day');
    await settle(tester);
    expect((await repo().loadDetail(routineId))!.routine.name, 'Push day');

    // The picker belongs to the exercises feature; add directly.
    await repo().addExercises(routineId, ['0025']);
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    final sets = (await repo().loadDetail(routineId))!.exercises.single.sets;

    // Weight 60 → Next → reps 8 → Done: each key is written immediately.
    await tester.tap(find.byKey(ValueKey('set-weight-${sets.first.id}')));
    await settle(tester);
    expect(find.text('Target weight (kg)'), findsOneWidget);
    await tester.tap(find.text('6').last);
    await tester.tap(find.text('0').last);
    await settle(tester);
    var s = (await repo().loadDetail(routineId))!.exercises.single.sets.first;
    expect(s.targetWeightKg, 60);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Target reps'), findsOneWidget);
    await tester.tap(find.text('8').last);
    await settle(tester);
    s = (await repo().loadDetail(routineId))!.exercises.single.sets.first;
    expect(s.targetReps, 8);
    await tester.tap(find.bySemanticsLabel('Close keypad'));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget); // exercise preview

    await tester.tap(find.bySemanticsLabel('Start routine'));
    await settle(tester);
    expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    final w = (await container.read(workoutRepositoryProvider).active())!;
    expect((w.name, w.routineId), ('Push day', routineId));
    await tearDownApp(tester);
  });

  for (final lang in [LanguagePref.en, LanguagePref.ar]) {
    testWidgets('routine editor: delete a target set by swipe / long-press, renumber, Undo (${lang.name})', (tester) async {
      await pumpApp(tester, lang);
      final id = await repo().create(name: 'Push');
      await repo().addExercises(id, ['0025']);
      container.read(appRouterProvider).push(AppRoutes.routineEditorFor(id));
      await settle(tester);
      Future<List<String>> ids() async => [for (final s in (await repo().loadDetail(id))!.exercises.single.sets) s.id];
      List<String> labels() => [for (final r in tester.widgetList<SetRow>(find.byType(SetRow))) r.label];
      final all = await ids();
      List<String> numbers(int n) => [for (var i = 1; i <= n; i++) '$i'];
      expect(all.length, greaterThanOrEqualTo(2));
      expect(labels(), numbers(all.length));

      // Toward the START edge: left in English, right in Arabic.
      final toStart = lang == LanguagePref.en ? const Offset(-600, 0) : const Offset(600, 0);
      await tester.drag(find.byKey(ValueKey('set-weight-${all[0]}')), toStart);
      await settle(tester);
      expect(await ids(), all.sublist(1));
      expect(labels(), numbers(all.length - 1));
      await tester.tap(find.text(lang == LanguagePref.en ? 'Undo' : 'تراجع'));

      await settle(tester);
      expect(await ids(), all);
      expect(labels(), numbers(all.length));

      // Long-press → Delete set, down to the last one.
      for (final setId in all) {
        await tester.longPress(find.byKey(SetRow.rowKey(setId)));
        await settle(tester);
        await tester.tap(find.byKey(SetRow.menuDeleteKey));
        await settle(tester);
      }
      expect(await ids(), isEmpty);
      expect(find.byType(SetRow), findsNothing);
      expect((await repo().loadDetail(id))!.exercises, hasLength(1));
      await tester.tap(find.text(lang == LanguagePref.en ? 'Undo' : 'تراجع'));
      await settle(tester);
      expect(await ids(), [all.last]);
      await tearDownApp(tester);
    });
  }

  testWidgets('an untouched new routine leaves nothing behind; delete asks first', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    await tester.tap(find.text('New routine'));
    await settle(tester);
    expect(await db.select(db.routines).get(), hasLength(1));
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(await db.select(db.routines).get(), isEmpty);

    final id = await repo().create(name: 'Legs');
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Routine options'));
    await settle(tester);
    await tester.tap(find.text('Delete routine'));
    await settle(tester);
    expect(find.text('Delete this routine?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routinesConfirm')));
    await settle(tester);
    expect(await repo().loadDetail(id), isNull);
    expect(find.text('No routines yet'), findsOneWidget);
    await tearDownApp(tester);
  });

  test('ready programs are hidden in this build', () {
    expect(kProgramsEnabled, isFalse);
    expect(ProviderContainer().read(programsEnabledProvider), isFalse);
  });

  for (final lang in [LanguagePref.en, LanguagePref.ar]) {
    testWidgets('programs hidden: one onboarding screen (unit only), no entry, routes unreachable (${lang.name})',
        (tester) async {
      await pumpApp(tester, lang, onboardingDone: false);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.textContaining(lang == LanguagePref.en ? 'Step' : 'خطوة'), findsNothing);
      await tester.tap(find.text(lang == LanguagePref.en ? 'Pounds' : 'باوند'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('onboarding-start')));
      await settle(tester);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(await loadOnboardingDone(db), isTrue);
      expect(parseWeightUnit(await db.readSetting(TrainingSettingsKeys.unit)), WeightUnit.lb);
      expect(await db.select(db.routines).get(), isEmpty);
      expect(find.byKey(const ValueKey('routinesProgramsEntry')), findsNothing);

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.programs);
      await settle(tester);
      expect(find.byType(ProgramsScreen), findsNothing);
      router.go(AppRoutes.programFor('test_ab'));
      await settle(tester);
      expect(find.byType(ProgramsScreen), findsNothing);
      expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.workout);
      await tearDownApp(tester);
    });
  }

  for (final lang in [LanguagePref.en, LanguagePref.ar]) {
    testWidgets('routine card → read-only detail (SET | KG | REPS) → Edit → back → dumbbell start (${lang.name})',
        (tester) async {
      await pumpApp(tester, lang);
      final id = await repo().create(name: 'Upper day');
      await repo().addExercises(id, ['0025', '0292']);
      final d = (await repo().loadDetail(id))!;
      await repo().updateSet(d.exercises[0].sets[0].id, targetWeightKg: 15, targetReps: 8);
      await settle(tester);

      // Card: name, preview (max 2 lines), ⋯, icon-only start button.
      expect(find.text(lang == LanguagePref.en ? 'My routines (1)' : 'روتيناتي (1)'), findsOneWidget);
      final start = find.bySemanticsLabel(lang == LanguagePref.en ? 'Start routine' : 'ابدأ الروتين');
      expect(start, findsOneWidget);
      expect(find.descendant(of: find.byKey(ValueKey('routine-start-$id')), matching: find.byType(Text)), findsNothing);
      expect(
        find.descendant(of: find.byKey(ValueKey('routine-start-$id')), matching: find.byIcon(Icons.fitness_center_rounded)),
        findsOneWidget,
      );
      final preview = tester.widgetList<Text>(find.byType(Text)).firstWhere((t) => RegExp('[,،]').hasMatch(t.data ?? ''));
      expect(preview.maxLines, 2);

      await tester.tap(find.text('Upper day'));
      await settle(tester);
      expect(find.byType(RoutineDetailScreen), findsOneWidget);
      expect(find.byType(RoutineEditorScreen), findsNothing);
      // Plain text rows, no inputs: 3 + 3 target sets; the first has 15 × 8.
      expect(find.byType(TextField), findsNothing);
      for (final e in d.exercises) {
        for (final s in e.sets) {
          expect(find.byKey(ValueKey('routine-detail-set-${s.id}')), findsOneWidget);
        }
      }
      expect(find.text('15'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('KG'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('routineDetailEdit')));
      await settle(tester);
      expect(find.byType(RoutineEditorScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(lang == LanguagePref.en ? 'Back' : 'رجوع'));
      await settle(tester);
      expect(find.byType(RoutineDetailScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('routineDetailStart')));
      await settle(tester);
      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
      expect((await container.read(workoutRepositoryProvider).active())!.routineId, id);
      await tearDownApp(tester);
    });
  }

  testWidgets('⋯ menu → Edit opens the editor', (tester) async {
    await pumpApp(tester, LanguagePref.en);
    await repo().create(name: 'Legs');
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Routine options'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('routineMenuEdit')));
    await settle(tester);
    expect(find.byType(RoutineEditorScreen), findsOneWidget);
    await tearDownApp(tester);
  });
}
