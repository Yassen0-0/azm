import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../theme/azm_theme.dart';
import 'media_resolver.dart';

/// Square exercise thumbnail for LISTS (never a GIF). Falls back to a muscle
/// icon when media is unavailable, unlicensed, or fails to load.
class ExerciseThumbnail extends ConsumerWidget {
  const ExerciseThumbnail({super.key, required this.exercise, this.size = AzmSize.thumbnailList});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(mediaResolverProvider).thumbnailFor(exercise);
    return _Frame(
      size: size,
      child: url == null
          ? _Fallback(size: size)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: AzmMotion.of(context, AzmMotion.micro),
              placeholder: (_, _) => _Fallback(size: size),
              errorWidget: (_, _, _) => _Fallback(size: size),
            ),
    );
  }
}

/// Animated GIF — ONLY on the exercise detail screen. The detail screen must
/// also show the media attribution (docs/LICENSES.md).
class ExerciseAnimation extends ConsumerWidget {
  const ExerciseAnimation({super.key, required this.exercise, required this.size});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(mediaResolverProvider).gifFor(exercise);
    return _Frame(
      size: size,
      child: url == null
          ? _Fallback(size: size)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, _) => _Fallback(size: size),
              errorWidget: (_, _, _) => _Fallback(size: size),
            ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AzmRadius.input),
        child: SizedBox.square(dimension: size, child: child),
      );
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: c.fill,
      child: Center(
        child: Icon(Icons.fitness_center_rounded, size: size / 2, color: c.textTertiary),
      ),
    );
  }
}
