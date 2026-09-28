import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/azm_tab_page.dart';
import '../../../core/widgets/rest_timer_bar.dart';
import '../../routines/ui/routines_home_section.dart';
import '../data/workout_repository.dart';
import 'workout_format.dart';

/// Workout tab: a compact "Start empty workout" row (empty workout → active
/// workout in one tap), or the running workout; "My routines" below
/// (RoutinesHomeSection).
class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active = ref.watch(activeWorkoutProvider).value;
    return AzmTabPage(
      title: l.shellTabWorkout,
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.xs, AzmSpace.pageMargin, 0),
        children: [
          if (active == null) const _StartRow() else _ActiveRow(workout: active),
          // Routines window slot: my routines.
          const RoutinesHomeSection(),
        ],
      ),
    );
  }
}

/// Starts an empty workout (or reuses the active one) and opens it.
Future<void> startEmptyWorkout(BuildContext context, WidgetRef ref) async {
  final name = context.l10n.defaultWorkoutName(DateTime.now());
  await ref.read(workoutRepositoryProvider).startEmpty(name);
  if (context.mounted) unawaited(context.push(AppRoutes.activeWorkout));
}

/// Card row: + icon, "Start empty workout".
class _StartRow extends ConsumerWidget {
  const _StartRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    return _CardRow(
      key: const ValueKey('workoutStartEmpty'),
      onTap: () => startEmptyWorkout(context, ref),
      semanticLabel: l.workoutStartEmpty,
      leading: Icon(Icons.add_rounded, color: c.textPrimary, size: AzmSize.icon),
      child: Text(
        l.workoutStartEmpty,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AzmType.itemLabel.copyWith(color: c.textPrimary),
      ),
    );
  }
}

/// Card row for the running workout: play icon, name, elapsed time.
class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return _CardRow(
      key: const ValueKey('workoutResume'),
      onTap: () => context.push(AppRoutes.activeWorkout),
      semanticLabel: '${l.workoutResume}: ${workout.name}',
      leading: Icon(Icons.play_arrow_rounded, color: c.accent, size: AzmSize.icon),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.workoutResume, style: AzmType.itemLabel.copyWith(color: c.accent)),
                Text(
                  workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AzmType.secondary.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          AzmTicker(
            period: const Duration(seconds: 1),
            builder: (_, now) => Text(
              formatClock(now.difference(workout.startedAt)),
              style: AzmType.rowNumberCompact.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({super.key, required this.onTap, required this.semanticLabel, required this.leading, required this.child});

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: AzmSize.primaryButton),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xl, vertical: AzmSpace.xs),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.input)),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AzmSpace.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
