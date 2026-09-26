import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exercises/ui/exercises_screen.dart';
import '../../features/history/ui/history_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/workout/ui/workout_home_screen.dart';
import '../l10n/l10n.dart';
import '../widgets/azm_tab_bar.dart';

/// Route paths. Features navigate with `context.push(AppRoutes.x)` / `go`.
abstract final class AppRoutes {
  static const String workout = '/workout';
  static const String history = '/history';
  static const String exercises = '/exercises';
  static const String settings = '/settings';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.workout,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.workout, builder: (_, _) => const WorkoutHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.history, builder: (_, _) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.exercises, builder: (_, _) => const ExercisesScreen()),
          ]),
        ],
      ),
      // Pushed above the shell (covers the tab bar).
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
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
      bottomNavigationBar: AzmTabBar(
        currentIndex: shell.currentIndex,
        onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
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
    );
  }
}
