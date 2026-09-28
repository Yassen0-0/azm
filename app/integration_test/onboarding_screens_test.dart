// Parity screenshots of first-run onboarding (CLAUDE.md → Platform Parity Rule).
//   AZM_DEVICE_SET=A tools/screenshots.sh onboarding
// Opens AppRoutes.onboarding directly (screenshot runs always count as
// onboarded). Never taps the final button, so onboarding_done and the
// routines on the device are left alone. Ready programs are hidden
// (kProgramsEnabled = false): onboarding is the unit screen only; the
// two-step version is captured by programs_screens_test.dart.
import 'package:azm/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int ms = 600]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Fresh onboarding (leave the route first so its state resets).
Future<void> _open(WidgetTester tester, GoRouter router) async {
  router.go(AppRoutes.workout);
  await _pumpFor(tester, 300);
  router.go(AppRoutes.onboarding);
  await _pumpFor(tester);
}

void main() => runScreenshotSuite('onboarding', [
      ScreenStep('unit', (tester, ProviderContainer c, router) => _open(tester, router)),
      ScreenStep('unit_lb_selected', (tester, c, router) async {
        await _open(tester, router);
        await tester.tap(find.byKey(const ValueKey('onboarding-unit-lb')));
      }),
    ]);
