import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';

// First-run gate. bootstrapApp() calls [loadOnboardingDone] before the first
// frame and overrides [onboardingDoneAtLaunchProvider]; the router starts on
// AppRoutes.onboarding when it is false. Screenshot/integration runs
// (bootstrapApp(settingsOverride: …)) always count as done.
// Pre-registered (docs/PLAN.md → Parallel windows, round 2): keep both names
// and signatures; the onboarding window implements them.

/// Whether first-run onboarding was completed (settings key `onboarding_done`,
/// docs/DATA.md). Placeholder: always true until onboarding exists.
Future<bool> loadOnboardingDone(AppDatabase db) async => true;

/// Read once by the router for its initial location. Default (tests without
/// bootstrap): done.
final onboardingDoneAtLaunchProvider = Provider<bool>((ref) => true);
