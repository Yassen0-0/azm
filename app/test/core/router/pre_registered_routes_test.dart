import 'package:azm/app.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/history/ui/exercise_history_screen.dart';
import 'package:azm/features/history/ui/past_workout_screen.dart';
import 'package:azm/features/history/ui/stats_screen.dart';
import 'package:azm/features/onboarding/data/onboarding_gate.dart';
import 'package:azm/features/onboarding/ui/onboarding_screen.dart';
import 'package:azm/features/routines/ui/program_detail_screen.dart';
import 'package:azm/features/routines/ui/programs_screen.dart';
import 'package:azm/features/routines/ui/routine_editor_screen.dart';
import 'package:azm/features/workout/ui/workout_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Round-2 routes are pre-registered in the frozen router (docs/PLAN.md →
// Parallel windows). Each must open its owner's screen with its argument.
void main() {
  Future<ProviderContainer> pump(WidgetTester tester, {bool onboardingDone = true}) async {
    final container = ProviderContainer(
      overrides: [onboardingDoneAtLaunchProvider.overrideWithValue(onboardingDone)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('first run starts on onboarding, otherwise on the Workout tab', (tester) async {
    await pump(tester, onboardingDone: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(WorkoutHomeScreen), findsNothing);
  });

  testWidgets('every pre-registered route opens its screen', (tester) async {
    final router = (await pump(tester)).read(appRouterProvider);
    expect(find.byType(WorkoutHomeScreen), findsOneWidget);

    Future<T> open<T extends Widget>(String location) async {
      router.go(location);
      await tester.pumpAndSettle();
      return tester.widget<T>(find.byType(T));
    }

    await open<OnboardingScreen>(AppRoutes.onboarding);
    expect((await open<RoutineEditorScreen>(AppRoutes.routineNew)).routineId, isNull);
    expect((await open<RoutineEditorScreen>(AppRoutes.routineEditorFor('r1'))).routineId, 'r1');
    await open<ProgramsScreen>(AppRoutes.programs);
    expect((await open<ProgramDetailScreen>(AppRoutes.programFor('ppl'))).programId, 'ppl');
    expect((await open<PastWorkoutScreen>(AppRoutes.pastWorkoutFor('w1'))).workoutId, 'w1');
    await open<StatsScreen>(AppRoutes.stats);
    expect((await open<ExerciseHistoryScreen>(AppRoutes.exerciseHistoryFor('0001'))).exerciseId, '0001');
  });
}
