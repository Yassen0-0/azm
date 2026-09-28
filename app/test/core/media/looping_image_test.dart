import 'dart:io';
import 'dart:ui' as ui;

import 'package:azm/core/media/looping_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

void main() {
  setUp(() => PaintingBinding.instance.imageCache.clear());

  /// Frames delivered to one listener of [provider] over ~2 s of animation.
  Future<int> framesShown(WidgetTester tester, ImageProvider provider) async {
    var frames = 0;
    final stream = provider.resolve(ImageConfiguration(bundle: FakeMediaBundle({'a.gif': playOnceGif})));
    final listener = ImageStreamListener((info, _) {
      frames++;
      info.dispose();
    });
    stream.addListener(listener);
    for (var i = 0; i < 40; i++) {
      // Decoding is real async work; frame timers run on the fake clock.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 60));
    }
    stream.removeListener(listener);
    return frames;
  }

  testWidgets('a play-once GIF stops after one cycle as a plain image, but loops through LoopingImage', (tester) async {
    expect(await framesShown(tester, const AssetImage('a.gif')), 2, reason: 'Flutter honours "play once"');
    expect(await framesShown(tester, const LoopingImage(AssetImage('a.gif'))), greaterThan(8));
  });

  test('LoopingImage has its own cache key (never shares the still/plain entry)', () async {
    final config = ImageConfiguration(bundle: FakeMediaBundle({'a.gif': playOnceGif}));
    final plain = await const AssetImage('a.gif').obtainKey(config);
    final looping = await const LoopingImage(AssetImage('a.gif')).obtainKey(config);
    expect(looping, isNot(plain));
    expect(looping, await const LoopingImage(AssetImage('a.gif')).obtainKey(config));
    expect(const LoopingImage(AssetImage('a.gif')), const LoopingImage(AssetImage('a.gif')));
  });

  testWidgets('real Gym visual GIF without a loop block (0053) reports "repeat forever" once wrapped', (tester) async {
    // media/ is committed in azm (docs/LICENSES.md); tests run from app/.
    final file = File('../media/videos/0053-1gFNTZV.gif');
    expect(file.existsSync(), isTrue, reason: 'media/ must be in the checkout');
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
      expect(codec.frameCount, greaterThan(1));
      expect(codec.repetitionCount, 0, reason: 'the file itself says "play once"');
      final looping = LoopForeverCodec(codec);
      expect(looping.repetitionCount, -1);
      expect(looping.frameCount, codec.frameCount);
      // The engine codec wraps around after the last frame.
      for (var i = 0; i < codec.frameCount + 2; i++) {
        (await looping.getNextFrame()).image.dispose();
      }
      looping.dispose();
    });
  });
}
