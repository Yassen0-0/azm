import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/theme/azm_theme.dart';
import 'package:azm/core/widgets/set_row.dart';
import 'package:azm/core/widgets/weight_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {TextDirection dir = TextDirection.ltr}) => MaterialApp(
      theme: AzmTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      home: Directionality(textDirection: dir, child: Scaffold(body: child)),
    );

void main() {
  group('applyKeypadKey', () {
    ({String buffer, bool fresh}) keys(String start, List<KeypadKey> ks, {bool decimal = true, bool fresh = true}) {
      var r = (buffer: start, fresh: fresh);
      for (final k in ks) {
        r = applyKeypadKey(r.buffer, r.fresh, k, allowDecimal: decimal);
      }
      return r;
    }

    test('a fresh field is replaced by the first digit', () {
      expect(keys('60', [const KeypadDigit(7), const KeypadDigit(5)]).buffer, '75');
    });

    test('decimal: one point, one decimal digit, leading 0', () {
      expect(keys('', [const KeypadDecimal(), const KeypadDigit(5)]).buffer, '0.5');
      expect(keys('', [const KeypadDigit(6), const KeypadDigit(2), const KeypadDecimal(), const KeypadDecimal(), const KeypadDigit(5), const KeypadDigit(9)]).buffer,
          '62.5');
    });

    test('reps ignore the decimal key', () {
      expect(keys('', [const KeypadDigit(8), const KeypadDecimal()], decimal: false).buffer, '8');
    });

    test('backspace on a fresh field clears it; otherwise deletes one char', () {
      expect(keys('60', [const KeypadBackspace()]).buffer, '');
      expect(keys('62.5', [const KeypadBackspace()], fresh: false).buffer, '62.');
    });

    test('no leading zeros, max 4 integer digits', () {
      expect(keys('', [const KeypadDigit(0), const KeypadDigit(7)]).buffer, '7');
      expect(keys('', [for (var i = 1; i <= 6; i++) KeypadDigit(i)]).buffer, '1234');
    });
  });

  testWidgets('WeightKeypad emits every key', (tester) async {
    final got = <KeypadKey>[];
    await tester.pumpWidget(_wrap(Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: WeightKeypad(
        title: 'Weight (kg)',
        valueText: '60',
        allowDecimal: true,
        stepText: '2.5',
        nextLabel: 'Next',
        backspaceLabel: 'Delete digit',
        hideLabel: 'Close keypad',
        decreaseLabel: 'Decrease',
        increaseLabel: 'Increase',
        onKey: got.add,
      ),
    )));
    expect(find.text('60'), findsOneWidget);
    await tester.tap(find.text('7'));
    await tester.tap(find.text('.'));
    await tester.tap(find.textContaining('+2.5'));
    await tester.tap(find.textContaining('−2.5'));
    await tester.tap(find.bySemanticsLabel('Delete digit'));
    await tester.tap(find.bySemanticsLabel('Close keypad'));
    await tester.tap(find.text('Next'));
    expect(got.map((k) => k.runtimeType), [KeypadDigit, KeypadDecimal, KeypadStep, KeypadStep, KeypadBackspace, KeypadHide, KeypadNext]);
    expect((got[2] as KeypadStep).up, isTrue);
    expect((got[3] as KeypadStep).up, isFalse);
  });

  group('SetRow', () {
    final calls = <String>[];

    Widget row({
      String label = '1',
      SetLabelKind kind = SetLabelKind.normal,
      bool completed = false,
      bool pr = false,
      String weight = '',
      String reps = '',
    }) =>
        SetRow(
          setId: 's1',
          label: label,
          labelKind: kind,
          previousText: '60 × 8',
          weightText: weight,
          repsText: reps,
          weightHint: '60',
          repsHint: '8',
          completed: completed,
          isPr: pr,
          onLabelTap: () => calls.add('label'),
          onPreviousTap: () => calls.add('previous'),
          onWeightTap: () => calls.add('weight'),
          onRepsTap: () => calls.add('reps'),
          onToggleComplete: () => calls.add('check'),
          onDelete: () => calls.add('delete'),
          deleteLabel: 'Delete set',
          completeLabel: 'Mark set complete',
        );

    setUp(calls.clear);

    Color textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style!.color!;

    testWidgets('empty set shows the previous values as grey hints', (tester) async {
      await tester.pumpWidget(_wrap(row()));
      expect(textColor(tester, '60'), AzmColors.dark.textNoData);
      expect(textColor(tester, '8'), AzmColors.dark.textNoData);
      expect(find.text('60 × 8'), findsOneWidget);
    });

    testWidgets('warm-up label is amber; failure label is NOT red', (tester) async {
      await tester.pumpWidget(_wrap(row(label: 'W', kind: SetLabelKind.warmup)));
      expect(textColor(tester, 'W'), AzmColors.dark.warmupText);
      await tester.pumpWidget(_wrap(row(label: 'F', kind: SetLabelKind.other)));
      expect(textColor(tester, 'F'), isNot(AzmColors.dark.destructive));
      expect(textColor(tester, 'F'), AzmColors.dark.textPrimary);
    });

    testWidgets('completed set gets the setDone tint and a green ✓; PR shows 🏆', (tester) async {
      await tester.pumpWidget(_wrap(row(completed: true, weight: '62.5', reps: '8', pr: true)));
      await tester.pumpAndSettle();
      final tinted = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AzmColors.dark.setDone;
      });
      expect(tinted, isNotEmpty);
      expect(textColor(tester, '62.5'), AzmColors.dark.textPrimary);
      expect(find.text(PrBadge.trophy), findsOneWidget);
    });

    testWidgets('taps reach the right callbacks', (tester) async {
      await tester.pumpWidget(_wrap(row(weight: '60', reps: '8')));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('60 × 8'));
      await tester.tap(find.text('60'));
      await tester.tap(find.text('8'));
      await tester.tap(find.bySemanticsLabel('Mark set complete'));
      expect(calls, ['label', 'previous', 'weight', 'reps', 'check']);
    });

    for (final dir in TextDirection.values) {
      testWidgets('swipe toward the START edge deletes (${dir.name})', (tester) async {
        await tester.pumpWidget(_wrap(row(), dir: dir));
        // START edge = left in English, right in Arabic.
        final toStart = dir == TextDirection.ltr ? const Offset(-500, 0) : const Offset(500, 0);
        // Toward the end edge: nothing.
        await tester.drag(find.byType(SetRow), -toStart);
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        expect(find.text('60 × 8'), findsOneWidget);
        await tester.drag(find.byType(SetRow), toStart);
        await tester.pumpAndSettle();
        expect(calls, ['delete']);
        // The row is gone at once, even before the parent drops it.
        expect(find.text('60 × 8'), findsNothing);
      });

      testWidgets('long-press → menu → Delete set (${dir.name})', (tester) async {
        await tester.pumpWidget(_wrap(row(), dir: dir));
        await tester.longPress(find.byKey(SetRow.rowKey('s1')));
        await tester.pumpAndSettle();
        expect(find.byKey(SetRow.menuDeleteKey), findsOneWidget);
        expect(calls, isEmpty);
        await tester.tap(find.byKey(SetRow.menuDeleteKey));
        await tester.pumpAndSettle();
        expect(calls, ['delete']);
      });
    }

    testWidgets('long-press menu dismissed without a choice deletes nothing', (tester) async {
      await tester.pumpWidget(_wrap(row()));
      await tester.longPress(find.byKey(SetRow.rowKey('s1')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // the scrim
      await tester.pumpAndSettle();
      expect(find.byKey(SetRow.menuDeleteKey), findsNothing);
      expect(calls, isEmpty);
    });

    testWidgets('a short tap is still a tap, not the menu', (tester) async {
      await tester.pumpWidget(_wrap(row(weight: '60', reps: '8')));
      await tester.tap(find.text('60'));
      await tester.pumpAndSettle();
      expect(calls, ['weight']);
      expect(find.byKey(SetRow.menuDeleteKey), findsNothing);
    });
  });
}
