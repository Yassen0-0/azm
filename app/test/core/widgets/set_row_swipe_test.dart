import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/theme/azm_theme.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Swipe-to-delete of the shared SetRow (live workout, past workout, routine
/// editor): the row follows the finger toward the START edge over a red
/// panel; > 25 % rests open on "Delete", > 60 % deletes (light haptic), else
/// springs back; one open row at a time. English (LTR) and Arabic (RTL).
void main() {
  final deleted = <String>[];
  final haptics = <String>[];

  setUp(() {
    deleted.clear();
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

  SetRow row(String id) => SetRow(
        key: ValueKey(id),
        setId: id,
        label: '1',
        labelKind: SetLabelKind.normal,
        previousText: '60 × 8',
        weightText: '60',
        repsText: '8',
        weightHint: '',
        repsHint: '',
        completed: true,
        onLabelTap: () {},
        onPreviousTap: null,
        onWeightTap: () {},
        onRepsTap: () {},
        onToggleComplete: () {},
        onDelete: () => deleted.add(id),
        deleteLabel: 'Delete set',
        completeLabel: 'Mark set complete',
      );

  Widget app(TextDirection dir, List<String> ids, {double textScale = 1, double? width}) => MaterialApp(
        theme: AzmTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  child: ListView(shrinkWrap: true, children: [for (final id in ids) row(id), const SizedBox(height: 300)]),
                ),
              ),
            ),
          ),
        ),
      );

  /// A slow drag (low release velocity) of [fraction] × row width toward the
  /// START edge (left in English, right in Arabic).
  Future<void> swipe(WidgetTester tester, TextDirection dir, String id, double fraction) async {
    final rowFinder = find.byKey(SetRow.rowKey(id));
    final width = tester.getSize(rowFinder).width;
    final sign = dir == TextDirection.ltr ? -1.0 : 1.0;
    final g = await tester.startGesture(tester.getCenter(find.byKey(ValueKey('set-reps-$id'))));
    const steps = 40;
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(sign * width * fraction / steps, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 100)); // finger rests: no fling
    await g.up();
    await tester.pumpAndSettle();
  }

  Finder panel() => find.byKey(SetRow.swipeDeleteKey);

  for (final dir in TextDirection.values) {
    final en = dir == TextDirection.ltr;
    final label = en ? 'Delete' : 'امسح';
    final lang = en ? 'English' : 'Arabic';

    testWidgets('$lang: the row follows the finger over a red panel at the END edge', (tester) async {
      await tester.pumpWidget(app(dir, ['a']));
      final before = tester.getTopLeft(find.byKey(const ValueKey('set-reps-a')));
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('set-reps-a'))));
      await g.moveBy(Offset(en ? -60 : 60, 0));
      await tester.pump();
      await g.moveBy(Offset(en ? -60 : 60, 0));
      await tester.pump();
      final during = tester.getTopLeft(find.byKey(const ValueKey('set-reps-a')));
      // Moved with the finger past the drag slop, toward the start edge.
      expect((during.dx - before.dx).abs(), greaterThan(80));
      expect(en ? during.dx < before.dx : during.dx > before.dx, isTrue);
      final rowRect = tester.getRect(find.byKey(SetRow.rowKey('a')));
      final red = tester.getRect(panel());
      expect(red.height, rowRect.height); // full row height
      expect(en ? red.right : red.left, en ? rowRect.right : rowRect.left); // flush with the edge (full-width row)
      final box = tester.widget<ColoredBox>(find.descendant(of: panel(), matching: find.byType(ColoredBox)));
      expect(box.color, AzmColors.dark.destructive);
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('$lang: partial swipe (> 25 %) rests open; tapping Delete deletes after the height collapses', (tester) async {
      await tester.pumpWidget(app(dir, ['a']));
      await swipe(tester, dir, 'a', 0.35);
      expect(panel(), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      expect(deleted, isEmpty);
      final h = tester.getSize(find.byKey(SetRow.rowKey('a'))).height;
      await tester.tap(panel());
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50)); // slides out (200 ms), then collapses
      }
      final mid = tester.getSize(find.ancestor(of: find.byKey(SetRow.rowKey('a')), matching: find.byType(SizeTransition)).first).height;
      expect(mid, lessThan(h));
      expect(deleted, isEmpty);
      await tester.pumpAndSettle();
      expect(deleted, ['a']);
      expect(find.byKey(SetRow.rowKey('a')), findsNothing);
    });

    testWidgets('$lang: open row closes on a tap elsewhere, on a tap on the row, and on scroll', (tester) async {
      await tester.pumpWidget(app(dir, ['a']));
      await swipe(tester, dir, 'a', 0.35);
      expect(panel(), findsOneWidget);
      await tester.tapAt(const Offset(400, 500)); // outside the row
      await tester.pumpAndSettle();
      expect(panel(), findsNothing);

      await swipe(tester, dir, 'a', 0.35);
      await tester.tap(find.text('60'), warnIfMissed: false); // on the row: closes, doesn't edit
      await tester.pumpAndSettle();
      expect(panel(), findsNothing);

      await swipe(tester, dir, 'a', 0.35);
      await tester.drag(find.byType(ListView), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(panel(), findsNothing);
      expect(deleted, isEmpty);
    });

    testWidgets('$lang: full swipe (> 60 %) deletes at once with a light haptic at the threshold', (tester) async {
      await tester.pumpWidget(app(dir, ['a']));
      await swipe(tester, dir, 'a', 0.7);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      expect(deleted, ['a']);
      expect(find.byKey(SetRow.rowKey('a')), findsNothing);
    });

    testWidgets('$lang: under 25 % springs back; toward the end edge does nothing', (tester) async {
      await tester.pumpWidget(app(dir, ['a']));
      final rest = tester.getTopLeft(find.byKey(const ValueKey('set-reps-a')));
      await swipe(tester, dir, 'a', 0.15);
      expect(panel(), findsNothing);
      expect(tester.getTopLeft(find.byKey(const ValueKey('set-reps-a'))), rest);
      await swipe(tester, dir == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr, 'a', 0.7); // wrong way
      expect(panel(), findsNothing);
      expect(deleted, isEmpty);
      expect(haptics, isEmpty);
    });

    testWidgets('$lang: only one row is open at a time', (tester) async {
      await tester.pumpWidget(app(dir, ['a', 'b']));
      await swipe(tester, dir, 'a', 0.35);
      expect(panel(), findsOneWidget);
      await swipe(tester, dir, 'b', 0.35);
      expect(panel(), findsOneWidget);
      // The open one is b's.
      expect(find.descendant(of: find.byKey(SetRow.rowKey('b')), matching: panel()), findsOneWidget);
      expect(find.descendant(of: find.byKey(SetRow.rowKey('a')), matching: panel()), findsNothing);
    });

    testWidgets('$lang: in an inset card, the red panel is painted all the way to the screen edge', (tester) async {
      // Like the live workout: the set row sits in a card 16 px from the
      // screen edges; the panel must bleed over that margin, unclipped.
      await tester.pumpWidget(MaterialApp(
        theme: AzmTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(en ? 'en' : 'ar'),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 40),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: AzmColors.dark.card, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [const SizedBox(height: 40), row('a'), const SizedBox(height: 40)]),
              ),
            ],
          ),
        ),
      ));
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('set-reps-a'))));
      for (var i = 0; i < 20; i++) {
        await g.moveBy(Offset((en ? -1 : 1) * 768 * 0.45 / 20, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final y = tester.getCenter(find.byKey(SetRow.rowKey('a'))).dy;
      final screenW = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final image = await captureImage(tester.element(find.byType(Scaffold)));
      final bytes = (await tester.runAsync(() => image.toByteData()))!;
      final top = tester.getRect(find.byKey(SetRow.rowKey('a'))).top + 3; // above the label glyphs
      Color at(double x, [double? atY]) {
        final i = (((atY ?? y).round() * image.width) + x.round()) * 4;
        return Color.fromARGB(bytes.getUint8(i + 3), bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
      }
      final red = AzmColors.dark.destructive;
      for (final x in en ? [screenW - 2, screenW - 10] : [2.0, 10.0]) {
        expect(at(x), red, reason: 'x=$x must be red (panel flush with the screen edge)');
      }
      for (final x in en ? [screenW - 40, screenW - 200] : [40.0, 200.0]) {
        expect(at(x, top), red, reason: 'x=$x (row top) must be red');
      }
      // …and the whole label is inside the painted panel.
      final label = tester.getRect(find.text(en ? 'Delete' : 'امسح'));
      expect(label.left >= 0 && label.right <= screenW, isTrue);
      expect(en ? label.right <= screenW - 8 : label.left >= 8, isTrue, reason: 'pinned near the edge, not under it');
      await g.up();
      await tester.pumpAndSettle();
    });

    for (final (scale, width) in [(1.0, 320.0), (2.0, 320.0), (3.0, 280.0)]) {
      testWidgets('$lang: the label never truncates (text ×$scale, ${width.toInt()} px wide)', (tester) async {
        await tester.pumpWidget(app(dir, ['a'], textScale: scale, width: width));
        for (final fraction in [0.1, 0.35]) {
          final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('set-reps-a'))));
          for (var i = 0; i < 20; i++) {
            await g.moveBy(Offset((en ? -1 : 1) * width * fraction / 20, 0));
            await tester.pump(const Duration(milliseconds: 16));
          }
          final text = find.descendant(of: panel(), matching: find.text(label));
          if (text.evaluate().isNotEmpty) {
            final p = tester.renderObject<RenderParagraph>(text);
            expect(p.didExceedMaxLines, isFalse);
            expect(p.size.width, greaterThanOrEqualTo(p.getMaxIntrinsicWidth(double.infinity) - 0.5));
            final r = tester.getRect(text), red = tester.getRect(panel());
            expect(r.left >= red.left - 0.5 && r.right <= red.right + 0.5, isTrue, reason: 'label inside the panel');
          } else {
            // Too narrow for the words: the icon alone.
            expect(find.descendant(of: panel(), matching: find.byIcon(Icons.delete_outline_rounded)), findsWidgets);
          }
          await g.up();
          await tester.pumpAndSettle();
        }
        // Resting open, the full label always fits (open width adapts).
        expect(find.descendant(of: panel(), matching: find.text(label)).evaluate().isNotEmpty || scale > 1, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
