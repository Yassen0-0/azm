// Screens of the app shell (bootstrap). Features: copy this file as
// integration_test/<feature>_screens_test.dart and list YOUR screens.
import 'package:azm/core/router/app_router.dart';

import 'screenshot_harness.dart';

void main() => runScreenshotSuite('shell', [
      ScreenStep.go('workout', AppRoutes.workout),
      ScreenStep.go('history', AppRoutes.history),
      ScreenStep.go('exercises', AppRoutes.exercises),
      ScreenStep.push('settings', AppRoutes.settings),
    ]);
