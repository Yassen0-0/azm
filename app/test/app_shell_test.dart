import 'package:azm/app.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester, List<Locale> deviceLocales) async {
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const ProviderScope(child: AzmApp()));
  await tester.pumpAndSettle();
}

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(Scaffold).first));

void main() {
  testWidgets('Arabic device → Arabic, RTL, dark by default, 3 tabs', (tester) async {
    await _pumpApp(tester, const [Locale('ar', 'EG')]);

    expect(_direction(tester), TextDirection.rtl);
    // Tab labels (bar) + the Workout title.
    expect(find.text('تمرين'), findsNWidgets(2));
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('التمارين'), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);
  });

  testWidgets('non-Arabic device (fr) → English, LTR', (tester) async {
    await _pumpApp(tester, const [Locale('fr', 'FR')]);

    expect(_direction(tester), TextDirection.ltr);
    expect(find.text('Workout'), findsNWidgets(2));
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
  });

  testWidgets('tabs switch the screen title', (tester) async {
    await _pumpApp(tester, const [Locale('en')]);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsNWidgets(2));

    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();
    expect(find.text('Exercises'), findsNWidgets(2));
  });

  testWidgets('settings: language override and light theme', (tester) async {
    await _pumpApp(tester, const [Locale('en')]);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Device language'), findsOneWidget);

    // Force Arabic.
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);

    // Light theme.
    await tester.tap(find.text('فاتح'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);

    // Back to the shell, still Arabic.
    await tester.tap(find.bySemanticsLabel('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('السجل'), findsOneWidget);
  });

  test('Western digits in both languages', () {
    expect(AzmNumbers.integer(12450), '12,450');
    expect(AzmNumbers.decimal(62.5), '62.5');
    expect(AzmNumbers.decimal(60), '60');
  });
}
