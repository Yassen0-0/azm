import 'package:azm/app.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dark is the default on first launch whatever the phone's setting; light
/// stays available in Settings (DESIGN.md → Dark is the default theme).
void main() {
  Future<Brightness> brightness(WidgetTester tester, {AppSettings? settings}) async {
    final container = ProviderContainer(overrides: [
      if (settings != null) initialAppSettingsProvider.overrideWithValue(settings),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await tester.pumpAndSettle();
    return Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
  }

  testWidgets('first launch on a phone in LIGHT mode → dark', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(await brightness(tester), Brightness.dark);
  });

  testWidgets('first launch on a phone in DARK mode → dark', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(await brightness(tester), Brightness.dark);
  });

  testWidgets('light chosen in Settings → light, even on a dark phone', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(await brightness(tester, settings: const AppSettings(theme: ThemePref.light)), Brightness.light);
  });
}
