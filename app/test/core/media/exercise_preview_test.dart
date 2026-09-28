import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/media/exercise_media.dart';
import 'package:azm/core/media/exercise_preview_sheet.dart';
import 'package:azm/core/media/looping_image.dart';
import 'package:azm/core/media/media_resolver.dart';
import 'package:azm/core/theme/azm_theme.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

const _gifPath = 'assets/media/videos/0025-abc.gif';
const _jpgPath = 'assets/media/images/0025-abc.jpg';
/// The credit, wrapped in an LTR isolate so it never mirrors in Arabic.
const _credit = '\u2066© Gym visual — https://gymvisual.com/\u2069';

const _bench = Exercise(
  id: '0025',
  nameEn: 'Barbell Bench Press',
  nameAr: 'ضغط بار مستوي',
  aliasesAr: '[]',
  bodyPart: 'chest',
  target: 'pectorals',
  secondaryMuscles: '[]',
  equipment: 'barbell',
  instructionsEn: '[]',
  mediaId: 'abc',
  searchNorm: '',
  hidden: false,
);

/// Bundled media (the personal flavor's layout) served from [bundle].
const _bundled = MediaConfig(bundled: true);
final _withMedia = FakeMediaBundle({_gifPath: playOnceGif, _jpgPath: playOnceGif});

Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  MediaConfig config = const MediaConfig(),
  AssetBundle? bundle,
}) =>
    tester.pumpWidget(ProviderScope(
      overrides: [mediaResolverProvider.overrideWithValue(MediaResolver(config))],
      child: DefaultAssetBundle(
        bundle: bundle ?? FakeMediaBundle({}),
        child: MaterialApp(
          theme: AzmTheme.dark(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    ));

/// Lets real image decoding finish, then advances the fake clock.
Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _openPreview(WidgetTester tester) async {
  await tester.tap(find.byKey(ExerciseThumbnail.previewKey('0025')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // sheet entrance
}

Future<void> _closePreview(WidgetTester tester) async {
  await tester.tapAt(const Offset(8, 8)); // the barrier above the sheet
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await _decode(tester); // evict() completes
}

Finder get _sheet => find.byType(ExercisePreviewSheet);

Image _imageIn(Finder scope) => tester<Image>(find.descendant(of: scope, matching: find.byType(Image)).first);

// Small indirection so helpers can read widgets without passing the tester.
late WidgetTester _t;
T tester<T extends Widget>(Finder f) => _t.widget<T>(f);

void main() {
  setUp(() => PaintingBinding.instance.imageCache.clear());

  Widget card(VoidCallback onTap) => ExerciseCard(exercise: _bench, onTap: onTap);

  testWidgets('thumbnail tap opens the preview; the rest of the row keeps its own tap', (t) async {
    _t = t;
    var rowTaps = 0;
    await _pump(t, AzmLocales.en, card(() => rowTaps++));

    await _openPreview(t);
    expect(_sheet, findsOneWidget);
    expect(rowTaps, 0, reason: 'the thumbnail must not trigger the row');

    await _closePreview(t);
    expect(_sheet, findsNothing);

    await t.tap(find.text(isolateName('Barbell Bench Press')));
    await t.pump(const Duration(milliseconds: 400));
    expect(rowTaps, 1);
    expect(_sheet, findsNothing);
  });

  testWidgets('preview shows the name in the app language; Arabic is RTL', (t) async {
    _t = t;
    for (final (locale, name, other, dir) in [
      (AzmLocales.ar, 'ضغط بار مستوي', 'Barbell Bench Press', TextDirection.rtl),
      (AzmLocales.en, 'Barbell Bench Press', 'ضغط بار مستوي', TextDirection.ltr),
    ]) {
      await _pump(t, locale, card(() {}));
      await _openPreview(t);
      expect(find.descendant(of: _sheet, matching: find.text(isolateName(name))), findsOneWidget);
      expect(find.descendant(of: _sheet, matching: find.text(isolateName(other))), findsNothing);
      expect(Directionality.of(t.element(_sheet)), dir);
      // Title starts at the start edge: right in Arabic, left in English.
      final title = t.getRect(find.descendant(of: _sheet, matching: find.text(isolateName(name))));
      final sheet = t.getRect(_sheet);
      if (dir == TextDirection.rtl) {
        expect(sheet.right - title.right, lessThan(sheet.width / 4));
      } else {
        expect(title.left - sheet.left, lessThan(sheet.width / 4));
      }
      await _closePreview(t);
    }
  });

  testWidgets('semantics: the thumbnail is a button named after the exercise', (t) async {
    _t = t;
    final handle = t.ensureSemantics();
    await _pump(t, AzmLocales.en, card(() {}));
    expect(find.bySemanticsLabel('Preview Barbell Bench Press'), findsOneWidget);
    await _pump(t, AzmLocales.ar, card(() {}));
    expect(find.bySemanticsLabel('معاينة حركة ضغط بار مستوي'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no media (tester/store builds): placeholder icon, no credit, no crash', (t) async {
    _t = t;
    await _pump(t, AzmLocales.en, card(() {}));
    await _openPreview(t);
    expect(find.descendant(of: _sheet, matching: find.byIcon(Icons.fitness_center_rounded)), findsOneWidget);
    expect(find.textContaining('Gym visual'), findsNothing);
    expect(find.descendant(of: _sheet, matching: find.byType(Image)), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('with media: the sheet plays the looping GIF with the credit; the list keeps the static JPG',
      (t) async {
    _t = t;
    await _pump(t, AzmLocales.ar, card(() {}), config: _bundled, bundle: _withMedia);
    await _decode(t);
    final thumb = _imageIn(find.byType(ExerciseCard)).image;
    expect(thumb, isA<AssetImage>().having((i) => i.assetName, 'assetName', _jpgPath));

    await _openPreview(t);
    await _decode(t);
    final gif = _imageIn(_sheet).image;
    expect(gif, isA<LoopingImage>());
    expect((gif as LoopingImage).image, isA<AssetImage>().having((i) => i.assetName, 'assetName', _gifPath));
    expect(find.descendant(of: _sheet, matching: find.text(_credit)), findsOneWidget);
    // Painted (not the loading placeholder).
    expect(find.descendant(of: _sheet, matching: find.byIcon(Icons.fitness_center_rounded)), findsNothing);
    expect(find.descendant(of: _sheet, matching: find.byType(RawImage)), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('closing the preview releases the GIF from the image cache', (t) async {
    _t = t;
    await _pump(t, AzmLocales.en, card(() {}), config: _bundled, bundle: _withMedia);
    final key = (await t.runAsync(
      () => const LoopingImage(AssetImage(_gifPath)).obtainKey(ImageConfiguration(bundle: _withMedia)),
    ))!;
    final cache = PaintingBinding.instance.imageCache;

    await _openPreview(t);
    await _decode(t);
    expect(cache.statusForKey(key).tracked, isTrue, reason: 'GIF loaded while the sheet is open');

    await _closePreview(t);
    expect(_sheet, findsNothing);
    expect(cache.statusForKey(key).untracked, isTrue, reason: 'GIF must be gone once the sheet closed');
  });

  testWidgets('missing GIF file: placeholder instead of a crash', (t) async {
    _t = t;
    await _pump(t, AzmLocales.en, card(() {}), config: _bundled, bundle: FakeMediaBundle({_jpgPath: playOnceGif}));
    await _openPreview(t);
    await _decode(t);
    expect(find.descendant(of: _sheet, matching: find.byIcon(Icons.fitness_center_rounded)), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('detail-screen animation loops too (LoopingImage), and keeps playing past one cycle', (t) async {
    _t = t;
    await _pump(
      t,
      AzmLocales.en,
      const ExerciseAnimation(exercise: _bench, size: 216),
      config: _bundled,
      bundle: _withMedia,
    );
    await _decode(t);
    expect(_imageIn(find.byType(ExerciseAnimation)).image, isA<LoopingImage>());
    // Different frames over time: the 2-frame play-once GIF would freeze
    // after 100 ms without LoopingImage.
    final seen = <int>{};
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump(const Duration(milliseconds: 60));
      final raw = t.widget<RawImage>(find.byType(RawImage));
      seen.add(identityHashCode(raw.image));
    }
    expect(seen.length, greaterThan(4), reason: 'new frames keep arriving');
  });

  testWidgets('short screen (landscape phone): the sheet scrolls instead of overflowing', (t) async {
    _t = t;
    t.view.physicalSize = const Size(844, 390);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await _pump(t, AzmLocales.ar, card(() {}), config: _bundled, bundle: _withMedia);
    await _openPreview(t);
    await _decode(t);
    expect(_sheet, findsOneWidget);
    expect(t.takeException(), isNull, reason: 'no RenderFlex overflow');
  });

  testWidgets('preview: false keeps a thumbnail inert', (t) async {
    _t = t;
    await _pump(t, AzmLocales.en, const ExerciseThumbnail(exercise: _bench, preview: false));
    expect(find.byKey(ExerciseThumbnail.previewKey('0025')), findsNothing);
  });
}
