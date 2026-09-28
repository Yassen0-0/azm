import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exercises/ui/exercise_detail_screen.dart';
import '../../features/exercises/ui/exercise_picker_screen.dart';
import '../../features/exercises/ui/exercises_screen.dart';
import '../../features/history/ui/exercise_history_screen.dart';
import '../../features/history/ui/history_screen.dart';
import '../../features/history/ui/past_workout_screen.dart';
import '../../features/history/ui/stats_screen.dart';
import '../../features/onboarding/data/onboarding_gate.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../features/routines/ui/program_detail_screen.dart';
import '../../features/routines/ui/programs_screen.dart';
import '../../features/routines/ui/routine_detail_screen.dart';
import '../../features/routines/ui/routine_editor_screen.dart';
import '../../features/settings/ui/licenses_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/workout/ui/active_workout_bar_slot.dart';
import '../../features/workout/ui/active_workout_screen.dart';
import '../../features/workout/ui/workout_home_screen.dart';
import '../../features/workout/ui/workout_summary_screen.dart';
import '../feature_flags.dart';
import '../l10n/l10n.dart';
import '../widgets/azm_tab_bar.dart';

/// Route paths. Features navigate with `context.push(AppRoutes.x)` / `go`.
/// All routes are pre-registered here so feature windows never edit this file;
/// ask in docs/PLAN.md → Requests for a new one.
abstract final class AppRoutes {
  // Tabs
  static const String workout = '/workout';
  static const String history = '/history';
  static const String exercises = '/exercises';

  // Pushed over the shell (cover the tab bar)
  static const String settings = '/settings';

  /// Exercise detail: `context.push(AppRoutes.exercise(id))`.
  static const String exerciseDetail = '/exercise/:id';
  static String exercise(String id) => '/exercise/$id';

  /// Multi-select picker; pops `List<String>` ids in selection order, or null.
  static const String exercisePicker = '/exercise-picker';

  /// The active workout (full screen).
  static const String activeWorkout = '/active-workout';

  /// Post-workout summary: `context.go(AppRoutes.workoutSummaryFor(id))`.
  static const String workoutSummary = '/workout-summary/:id';
  static String workoutSummaryFor(String id) => '/workout-summary/$id';

  // ── Round 2, routines + onboarding window (C) ──

  /// First-run onboarding; the initial location while `onboarding_done` is unset.
  static const String onboarding = '/onboarding';

  /// Routine editor for a NEW routine.
  static const String routineNew = '/routine-editor';

  /// Routine editor for an existing routine: `context.push(AppRoutes.routineEditorFor(id))`.
  static const String routineEditor = '/routine-editor/:id';
  static String routineEditorFor(String id) => '/routine-editor/$id';

  /// Read-only routine detail: `context.push(AppRoutes.routineDetailFor(id))`.
  static const String routineDetail = '/routine/:id';
  static String routineDetailFor(String id) => '/routine/$id';

  /// Ready programs list.
  static const String programs = '/programs';

  /// One ready program: `context.push(AppRoutes.programFor(id))`.
  static const String programDetail = '/program/:id';
  static String programFor(String id) => '/program/$id';

  // ── Round 2, history window (D) ──

  /// Past (finished) workout, editable: `context.push(AppRoutes.pastWorkoutFor(id))`.
  static const String pastWorkout = '/past-workout/:id';
  static String pastWorkoutFor(String id) => '/past-workout/$id';

  /// Stats (workouts per week, total sets, per-exercise PRs).
  static const String stats = '/stats';

  /// Full history of one exercise: `context.push(AppRoutes.exerciseHistoryFor(id))`.
  static const String exerciseHistory = '/exercise-history/:id';
  static String exerciseHistoryFor(String id) => '/exercise-history/$id';

  // ── Round 3, settings window (E) ──

  /// Licences and attributions, pushed from Settings.
  static const String licenses = '/settings/licenses';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

bool _isProgramsLocation(String location) =>
    location == AppRoutes.programs || location.startsWith('/program/');

final appRouterProvider = Provider<GoRouter>((ref) {
  final programsEnabled = ref.read(programsEnabledProvider);
  final router = GoRouter(
    navigatorKey: _rootKey,
    // Ready programs are behind a feature flag (core/feature_flags.dart):
    // while it is off their routes are unreachable.
    redirect: (_, state) =>
        !programsEnabled && _isProgramsLocation(state.uri.path) ? AppRoutes.workout : null,
    // First run → onboarding (read once; bootstrapApp sets it before the first frame).
    initialLocation: ref.read(onboardingDoneAtLaunchProvider) ? AppRoutes.workout : AppRoutes.onboarding,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workout,
                builder: (_, _) => const WorkoutHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.exercises,
                builder: (_, _) => const ExercisesScreen(),
              ),
            ],
          ),
        ],
      ),
      // Pushed above the shell (covers the tab bar).
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.licenses,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LicensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.exerciseDetail,
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.exercisePicker,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ExercisePickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeWorkout,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.workoutSummary,
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            WorkoutSummaryScreen(workoutId: state.pathParameters['id']!),
      ),
      // Round 2 (C): onboarding, routines, programs.
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.routineNew,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RoutineEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.routineEditor,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RoutineEditorScreen(routineId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.routineDetail,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RoutineDetailScreen(routineId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.programs,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ProgramsScreen(),
      ),
      GoRoute(
        path: AppRoutes.programDetail,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ProgramDetailScreen(programId: state.pathParameters['id']!),
      ),
      // Round 2 (D): history.
      GoRoute(
        path: AppRoutes.pastWorkout,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => PastWorkoutScreen(workoutId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.stats,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.exerciseHistory,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ExerciseHistoryScreen(exerciseId: state.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Scaffold holding the three tab branches and the floating glass tab bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      extendBody: true, // pages scroll under the glass bar
      body: shell,
      // Workout-owned slot (minimized active workout) sits above the tab bar.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ActiveWorkoutBarSlot(),
          AzmTabBar(
            currentIndex: shell.currentIndex,
            onSelect: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            items: [
              AzmTabItem(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center_rounded,
                label: l10n.shellTabWorkout,
              ),
              AzmTabItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: l10n.shellTabHistory,
              ),
              AzmTabItem(
                icon: Icons.format_list_bulleted_outlined,
                activeIcon: Icons.format_list_bulleted_rounded,
                label: l10n.shellTabExercises,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
