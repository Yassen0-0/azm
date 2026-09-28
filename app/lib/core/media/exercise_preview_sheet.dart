import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../l10n/exercise_names.dart';
import '../l10n/l10n.dart';
import '../theme/azm_theme.dart';
import '../widgets/exercise_card.dart' show isolateName;
import 'exercise_media.dart';
import 'media_resolver.dart';

/// Quick exercise preview (tap on any list thumbnail, [ExerciseThumbnail]):
/// the exercise name in the app language, the GIF playing in a loop, and the
/// Gym visual attribution whenever media is shown (docs/LICENSES.md). Without
/// media it shows the fallback icon and no attribution. The GIF is released
/// when the sheet closes ([ExerciseAnimation] evicts it on dispose).
Future<void> showExercisePreview(BuildContext context, Exercise exercise) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      // Sized by its content (not capped at 9/16 of the screen); scrolls on
      // short screens (small phones, landscape) instead of overflowing.
      isScrollControlled: true,
      builder: (_) => ExercisePreviewSheet(exercise: exercise),
    );

class ExercisePreviewSheet extends ConsumerWidget {
  const ExercisePreviewSheet({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final hasMedia = ref.watch(mediaResolverProvider).gifFor(exercise) != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isolateName(context.namesOf(exercise).primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AzmType.cardTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AzmSpace.md),
            LayoutBuilder(
              builder: (context, box) => Center(
                child: ExerciseAnimation(exercise: exercise, size: math.min(box.maxWidth, AzmSize.exerciseMedia)),
              ),
            ),
            if (hasMedia) ...[
              const SizedBox(height: AzmSpace.xs),
              Text(
                // LTR isolate: the Latin credit keeps its order in Arabic
                // (no "/… ©"), like the Licences screen.
                '\u2066${context.l10n.commonMediaCredit}\u2069',
                textAlign: TextAlign.center,
                style: AzmType.micro.copyWith(color: c.textMicro),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
