import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/theme/azm_theme.dart';
import 'package:azm/core/widgets/lifted_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Locale locale, Widget child) => tester.pumpWidget(MaterialApp(
      theme: AzmTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ));

void main() {
  testWidgets('compact: exact below 100,000, K/M/B above (en)', (tester) async {
    for (final (v, text) in [(84500.0, '84,500'), (450400.0, '450K'), (1234567.0, '1.2M'), (2.46e9, '2.5B')]) {
      await _pump(tester, AzmLocales.en, LiftedCounter(value: v, unit: 'kg', size: LiftedCounterSize.history, compact: true));
      await tester.pumpAndSettle();
      expect(find.textContaining(text), findsOneWidget, reason: '$v');
    }
  });

  testWidgets('compact: Arabic scale words, Western digits', (tester) async {
    for (final (v, text) in [(450000.0, '450 ألف'), (1200000.0, '1.2 مليون'), (3e9, '3 مليار')]) {
      await _pump(tester, AzmLocales.ar, LiftedCounter(value: v, unit: 'kg', size: LiftedCounterSize.history, compact: true));
      await tester.pumpAndSettle();
      expect(find.textContaining(text), findsOneWidget, reason: '$v');
    }
  });

  testWidgets('not compact by default; zeroText replaces 0', (tester) async {
    await _pump(tester, AzmLocales.en, const LiftedCounter(value: 1234567, unit: 'kg'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1,234,567'), findsOneWidget);
    await _pump(tester, AzmLocales.en, const LiftedCounter(value: 0, unit: 'kg', compact: true, zeroText: '—'));
    await tester.pumpAndSettle();
    expect(find.textContaining('—'), findsOneWidget);
  });

  testWidgets('number before unit in both languages (one LTR isolate, never "kg 200")', (tester) async {
    for (final locale in [AzmLocales.en, AzmLocales.ar]) {
      await _pump(tester, locale, const LiftedCounter(value: 200, unit: 'kg'));
      await tester.pumpAndSettle();
      expect(find.textContaining('\u2066200'), findsOneWidget, reason: '$locale');
      final plain = tester.widget<Text>(find.textContaining('200')).textSpan!.toPlainText();
      expect(plain.startsWith('\u2066200'), isTrue, reason: plain);
      expect(plain.indexOf('kg'), greaterThan(plain.indexOf('200')), reason: plain);
      expect(plain.endsWith('\u2069'), isTrue, reason: plain);
    }
  });
}
