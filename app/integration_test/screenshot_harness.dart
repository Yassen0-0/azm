// Shared screenshot harness for the PLATFORM PARITY RULE (CLAUDE.md).
// Core-owned: features add their OWN `<feature>_screens_test.dart` next to this
// file and never edit it. Run through tools/screenshots.sh.
import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:azm/app.dart';
import 'package:azm/bootstrap.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

/// One screen to capture: [name] becomes the file name, [open] navigates there
/// (and may seed data through the container).
class ScreenStep {
  const ScreenStep(this.name, this.open);

  final String name;
  final Future<void> Function(WidgetTester tester, ProviderContainer container, GoRouter router) open;

  /// Shortcut: `ScreenStep.go('history', AppRoutes.history)`.
  factory ScreenStep.go(String name, String location) =>
      ScreenStep(name, (_, _, router) async => router.go(location));

  /// Shortcut for pushed routes (settings, detail, ...). The push Future only
  /// completes when the route is popped, so it must NOT be awaited.
  factory ScreenStep.push(String name, String location) =>
      ScreenStep(name, (_, _, router) async => unawaited(router.push(location)));
}

/// Pumps frames for a fixed time instead of pumpAndSettle: screenshots must
/// not hang on screens with endless animations (timers, spinners, GIFs).
Future<void> _settle(WidgetTester tester, [Duration d = const Duration(milliseconds: 1200)]) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

// ignore: avoid_print
void _log(String m) => print('[screenshots] $m');

/// Captures every step in Arabic and English. Files land in
/// `docs/screenshots/<feature>/<android|ios>/<locale>_<nn>_<name>.png`.
void runScreenshotSuite(String feature, List<ScreenStep> steps) {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final platform = Platform.isIOS ? 'ios' : 'android';

  for (final lang in [LanguagePref.ar, LanguagePref.en]) {
    testWidgets('$feature screenshots ($platform, ${lang.name})', (tester) async {
      _log('bootstrap ${lang.name}');
      final container = await bootstrapApp(settingsOverride: AppSettings(language: lang));
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
      await _settle(tester);
      if (!Platform.isIOS) await binding.convertFlutterSurfaceToImage();

      final router = container.read(appRouterProvider);
      for (var i = 0; i < steps.length; i++) {
        _log('open ${steps[i].name}');
        await steps[i].open(tester, container, router);
        await _settle(tester);
        final nn = (i + 1).toString().padLeft(2, '0');
        await binding.takeScreenshot('$feature/$platform/${lang.name}_${nn}_${steps[i].name}');
        _log('captured ${steps[i].name}');
        // Return to a known state for the next step.
        while (router.canPop()) {
          router.pop();
          await _settle(tester);
        }
      }
    });
  }
}
