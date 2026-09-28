import 'dart:async' show unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../l10n/exercise_names.dart';
import '../l10n/l10n.dart';
import '../theme/azm_theme.dart';
import '../widgets/azm_pressable.dart';
import 'exercise_preview_sheet.dart';
import 'looping_image.dart';
import 'media_resolver.dart';

/// Square exercise thumbnail for LISTS (never a GIF: lists stay static and
/// light). Falls back to a muscle icon when media is unavailable, unlicensed,
/// or fails to load.
///
/// Tapping it opens the quick preview (bottom sheet with the looping GIF,
/// `showExercisePreview`); the row around it keeps its own tap. Pass
/// [preview] = false where the thumbnail must stay inert.
class ExerciseThumbnail extends ConsumerWidget {
  const ExerciseThumbnail({super.key, required this.exercise, this.size = AzmSize.thumbnailList, this.preview = true});

  final Exercise exercise;
  final double size;
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(mediaResolverProvider).thumbnailFor(exercise);
    final thumbnail = _Frame(
      size: size,
      child: url == null
          ? _Fallback(size: size)
          : url.startsWith(MediaConfig.assetScheme)
              ? _BundledImage(path: url.substring(MediaConfig.assetScheme.length), fit: BoxFit.cover, size: size)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: AzmMotion.of(context, AzmMotion.micro),
                  placeholder: (_, _) => _Fallback(size: size),
                  errorWidget: (_, _, _) => _Fallback(size: size),
                ),
    );
    if (!preview) return thumbnail;
    return AzmPressable(
      key: ExerciseThumbnail.previewKey(exercise.id),
      onTap: () => showExercisePreview(context, exercise),
      semanticLabel: context.l10n.commonExercisePreview(context.namesOf(exercise).primary),
      child: thumbnail,
    );
  }

  /// Key of the tappable thumbnail of exercise [id] (tests, screenshots).
  static Key previewKey(String id) => ValueKey('exercise-thumbnail-preview-$id');
}

/// Animated GIF, looping endlessly (`LoopingImage`), for the exercise detail
/// screen and the quick preview sheet only; lists use [ExerciseThumbnail].
/// Wherever it shows media, the Gym visual attribution must be shown too
/// (docs/LICENSES.md). Its decoded frames are evicted from the image cache
/// when it is disposed, so a closed preview or detail screen holds no GIF.
class ExerciseAnimation extends ConsumerStatefulWidget {
  const ExerciseAnimation({super.key, required this.exercise, required this.size});

  final Exercise exercise;
  final double size;

  @override
  ConsumerState<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends ConsumerState<ExerciseAnimation> {
  LoopingImage? _image;
  ImageConfiguration _configuration = ImageConfiguration.empty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configuration = createLocalImageConfiguration(context);
  }

  @override
  void dispose() {
    _evict(_image);
    super.dispose();
  }

  void _evict(LoopingImage? image) {
    if (image != null) unawaited(image.evict(configuration: _configuration));
  }

  LoopingImage? _imageFor(String? source) {
    if (source == null) return null;
    return LoopingImage(
      source.startsWith(MediaConfig.assetScheme)
          ? AssetImage(source.substring(MediaConfig.assetScheme.length))
          : CachedNetworkImageProvider(source),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final image = _imageFor(ref.watch(mediaResolverProvider).gifFor(widget.exercise));
    if (image != _image) {
      _evict(_image);
      _image = image;
    }
    return _Frame(
      size: size,
      child: image == null
          ? _Fallback(size: size)
          : Image(
              image: image,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              frameBuilder: (_, child, frame, _) => frame == null ? _Fallback(size: size) : child,
              errorBuilder: (_, _, _) => _Fallback(size: size),
            ),
    );
  }
}

/// Media bundled as an app asset (owner-only personal flavor): works offline.
/// A missing file shows the fallback, like a failed download.
class _BundledImage extends StatelessWidget {
  const _BundledImage({required this.path, required this.fit, required this.size});

  final String path;
  final BoxFit fit;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _Fallback(size: size),
      );
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
