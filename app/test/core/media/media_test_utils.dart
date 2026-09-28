import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A 1×1, 2-frame GIF (50 ms per frame) WITHOUT a NETSCAPE loop block, i.e.
/// "play once", like 27 of the Gym visual GIFs.
final Uint8List playOnceGif = Uint8List.fromList([
  ...'GIF89a'.codeUnits,
  0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, // 1×1, global colour table of 2
  0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, // black, white
  for (final pixel in [0x44, 0x4C]) ...[
    0x21, 0xF9, 0x04, 0x00, 0x05, 0x00, 0x00, 0x00, // graphic control: 5/100 s
    0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, // image 1×1
    0x02, 0x02, pixel, 0x01, 0x00, // LZW: colour 0 (0x44) or 1 (0x4C)
  ],
  0x3B,
]);

/// Asset bundle holding only [files] (+ an empty asset manifest). Anything
/// else fails like a missing asset does in the app.
class FakeMediaBundle extends CachingAssetBundle {
  FakeMediaBundle(this.files);

  final Map<String, Uint8List> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
    final bytes = files[key];
    if (bytes == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(bytes);
  }
}
