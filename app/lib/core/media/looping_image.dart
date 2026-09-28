import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Plays an animated image (the exercise GIFs) in an ENDLESS loop, whatever
/// loop count the file declares.
///
/// Flutter honours a GIF's own loop count, and a GIF without a NETSCAPE loop
/// block means "play once": it then stops on its last frame. 27 of the 1,324
/// Gym visual GIFs are like that. This wraps any provider (asset or network)
/// and hands the image stream a codec that reports "repeat forever"; the
/// engine codec itself wraps back to the first frame after the last one.
///
/// Its cache key differs from the wrapped provider's, so a plain `Image` of
/// the same file (a still) never shares the looping entry.
@immutable
class LoopingImage extends ImageProvider<LoopingImageKey> {
  const LoopingImage(this.image);

  final ImageProvider image;

  @override
  Future<LoopingImageKey> obtainKey(ImageConfiguration configuration) {
    // Stay synchronous when the wrapped provider is (like ResizeImage), so a
    // cached image shows in the first frame.
    Completer<LoopingImageKey>? completer;
    SynchronousFuture<LoopingImageKey>? result;
    Object? syncError;
    StackTrace? syncStack;
    image.obtainKey(configuration).then(
      (Object key) {
        if (completer == null) {
          result = SynchronousFuture<LoopingImageKey>(LoopingImageKey._(key));
        } else {
          completer.complete(LoopingImageKey._(key));
        }
      },
      onError: (Object e, StackTrace s) {
        if (completer == null) {
          syncError = e;
          syncStack = s;
        } else {
          completer.completeError(e, s);
        }
      },
    );
    if (result != null) return result!;
    if (syncError != null) return Future<LoopingImageKey>.error(syncError!, syncStack);
    completer = Completer<LoopingImageKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(LoopingImageKey key, ImageDecoderCallback decode) {
    Future<ui.Codec> decodeLooping(ui.ImmutableBuffer buffer, {ui.TargetImageSizeCallback? getTargetSize}) async =>
        LoopForeverCodec(await decode(buffer, getTargetSize: getTargetSize));
    return image.loadImage(key._inner, decodeLooping);
  }

  @override
  bool operator ==(Object other) => other is LoopingImage && other.image == image;

  @override
  int get hashCode => Object.hash(LoopingImage, image);

  @override
  String toString() => 'LoopingImage($image)';
}

/// Cache key of a [LoopingImage]: the wrapped provider's key, kept distinct.
@immutable
class LoopingImageKey {
  const LoopingImageKey._(this._inner);

  final Object _inner;

  @override
  bool operator ==(Object other) => other is LoopingImageKey && other._inner == _inner;

  @override
  int get hashCode => Object.hash(LoopingImageKey, _inner);

  @override
  String toString() => 'LoopingImageKey($_inner)';
}

/// A codec that says "repeat forever" (-1); everything else is the wrapped
/// codec's. Single-frame images are unaffected (nothing to repeat).
@visibleForTesting
class LoopForeverCodec implements ui.Codec {
  LoopForeverCodec(this._codec);

  final ui.Codec _codec;

  @override
  int get frameCount => _codec.frameCount;

  @override
  int get repetitionCount => -1;

  @override
  Future<ui.FrameInfo> getNextFrame() => _codec.getNextFrame();

  @override
  void dispose() => _codec.dispose();
}
