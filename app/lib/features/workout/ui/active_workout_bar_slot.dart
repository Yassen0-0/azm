import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/active_workout_bar.dart';
import '../data/rest_timer.dart';
import '../data/workout_repository.dart';

/// Slot rendered by AppShell directly ABOVE the floating tab bar, on every tab.
/// Shows the ActiveWorkoutBar (minimized workout + mini rest timer) and
/// nothing when no workout is active. Its height is automatically added to
/// the tabs' bottom padding (Scaffold extendBody). Keep the class name/constructor.
///
/// Also resumes a workout after an app kill: on the first launch state that
/// has an active workout, it opens the full screen once per process.
class ActiveWorkoutBarSlot extends ConsumerStatefulWidget {
  const ActiveWorkoutBarSlot({super.key});

  /// Open the active workout on cold launch. The screenshot suite turns it off.
  static bool autoResume = true;
  static bool _launchChecked = false;

  @override
  ConsumerState<ActiveWorkoutBarSlot> createState() => _ActiveWorkoutBarSlotState();
}

class _ActiveWorkoutBarSlotState extends ConsumerState<ActiveWorkoutBarSlot> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<Workout?>>(activeWorkoutProvider, (_, next) {
      if (ActiveWorkoutBarSlot._launchChecked || !next.hasValue) return;
      ActiveWorkoutBarSlot._launchChecked = true;
      if (next.value == null || !ActiveWorkoutBarSlot.autoResume) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(AppRoutes.activeWorkout);
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider).value;
    return AnimatedSize(
      duration: AzmMotion.of(context, AzmMotion.sheetDuration),
      curve: AzmMotion.sheet,
      child: workout == null ? const SizedBox(width: double.infinity) : _Bar(workout: workout),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rest = ref.watch(restTimerProvider);
    return ActiveWorkoutBar(
      name: workout.name,
      startedAt: workout.startedAt,
      restEndsAt: rest?.endsAt,
      now: ref.read(workoutClockProvider),
      semanticLabel: context.l10n.workoutBarOpen,
      onTap: () => context.push(AppRoutes.activeWorkout),
    );
  }
}
