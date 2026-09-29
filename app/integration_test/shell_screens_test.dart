// Screens of the app shell (bootstrap). Features: copy this file as
// integration_test/<feature>_screens_test.dart and list YOUR screens.
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_harness.dart';

/// Waits until [f] is on screen and hit-testable (so its tab is the visible
/// one), max [max] wall-clock. The harness only settles a fixed 1.2 s; on a
/// fresh install (the Arabic run goes first) the catalog list is not painted
/// yet by then. Fails with a clear reason on timeout.
Future<void> _waitFor(WidgetTester tester, Finder f, {Duration max = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(max);
  while (f.hitTestable().evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(f.hitTestable(), findsWidgets, reason: 'not on screen after ${max.inSeconds} s');
}

void main() => runScreenshotSuite('shell', [
      ScreenStep.go('workout', AppRoutes.workout),
      ScreenStep.go('history', AppRoutes.history),
      ScreenStep('exercises', (tester, _, router) async {
        router.go(AppRoutes.exercises);
        await _waitFor(tester, find.byType(ExerciseCard));
      }),
      ScreenStep.push('settings', AppRoutes.settings),
    ]);
