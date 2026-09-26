import 'package:azm/core/media/media_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no base URL → null (fallback UI)', () {
    const r = MediaResolver(MediaConfig(allowAll: true));
    expect(r.thumbnailUrl('0025', 'abc'), isNull);
    expect(r.gifUrl('0025', 'abc'), isNull);
  });

  test('unlicensed exercise → null even with a base URL', () {
    const r = MediaResolver(MediaConfig(baseUrl: 'https://cdn.example', licensedIds: {'0001'}));
    expect(r.thumbnailUrl('0025', 'abc'), isNull);
    expect(r.thumbnailUrl('0001', 'xyz'), 'https://cdn.example/images/0001-xyz.jpg');
    expect(r.gifUrl('0001', 'xyz'), 'https://cdn.example/videos/0001-xyz.gif');
  });

  test('dev allow-all + trailing slash', () {
    const r = MediaResolver(MediaConfig(baseUrl: 'http://10.0.2.2:8080/', allowAll: true));
    expect(r.thumbnailUrl('0025', '2gPfomN'), 'http://10.0.2.2:8080/images/0025-2gPfomN.jpg');
  });

  test('default build config has no media (nothing licensed yet)', () {
    expect(MediaConfig.licensedExerciseIds, isEmpty);
    final r = MediaResolver(MediaConfig.fromEnvironment());
    expect(r.thumbnailUrl('0025', 'abc'), isNull);
  });
}
