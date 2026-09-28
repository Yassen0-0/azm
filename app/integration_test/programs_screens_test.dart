// Parity screenshots of READY PROGRAMS, which are hidden in this build
// (core/feature_flags.dart → kProgramsEnabled = false). The suite turns the
// flag on through programsEnabledProvider so the kept code stays verified:
// programs list, a program, and the two-step onboarding.
//   AZM_DEVICE_SET=A tools/screenshots.sh programs
import 'dart:async';

import 'package:azm/core/feature_flags.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int ms = 600]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _onboarding(WidgetTester tester, GoRouter router) async {
  router.go(AppRoutes.workout);
  await _pumpFor(tester, 300);
  router.go(AppRoutes.onboarding);
  await _pumpFor(tester);
}

void main() => runScreenshotSuite(
      'programs',
      [
        ScreenStep('programs', (tester, c, router) async => unawaited(router.push(AppRoutes.programs))),
        ScreenStep('program_preview', (tester, c, router) async => unawaited(router.push(AppRoutes.programFor('ppl')))),
        ScreenStep('onboarding_unit', (tester, c, router) => _onboarding(tester, router)),
        ScreenStep('onboarding_program', (tester, c, router) async {
          await _onboarding(tester, router);
          await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        }),
      ],
      overrides: [programsEnabledProvider.overrideWithValue(true)],
    );
