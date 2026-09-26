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
import '../data/workout_repository.dart';
import 'workout_format.dart';

/// Workout tab: big "Start workout" (empty workout → active workout in one
/// tap), or the running workout. Routines/programs come with the routines task.
class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active = ref.watch(activeWorkoutProvider).value;
    return AzmTabPage(
      title: l.shellTabWorkout,
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.md, AzmSpace.pageMargin, 0),
        children: [
          if (active == null) const _StartCard() else _ActiveCard(workout: active),
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

class _StartCard extends ConsumerWidget {
  const _StartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryButton(
            label: l.workoutStart,
            icon: Icons.play_arrow_rounded,
            onTap: () => startEmptyWorkout(context, ref),
          ),
          const SizedBox(height: AzmSpace.md),
          Text(
            l.workoutStartHint,
            textAlign: TextAlign.center,
            style: AzmType.secondary.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.workoutInProgress, style: AzmType.groupHeading.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.xxs),
          Row(
            children: [
              Expanded(
                child: Text(
                  workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AzmType.cardTitle.copyWith(color: c.textPrimary),
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
          const SizedBox(height: AzmSpace.md),
          _PrimaryButton(
            label: l.workoutResume,
            icon: Icons.play_arrow_rounded,
            onTap: () => context.push(AppRoutes.activeWorkout),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.primaryButton,
          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AzmRadius.button)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: c.onAccent, size: AzmSize.icon),
              const SizedBox(width: AzmSpace.xs),
              Text(label, style: AzmType.button.copyWith(color: c.onAccent)),
            ],
          ),
        ),
      ),
    );
  }
}
