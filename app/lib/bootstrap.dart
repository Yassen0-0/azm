import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'core/db/app_database.dart';
import 'core/db/catalog_installer.dart';
import 'features/exercises/data/exercise_history.dart';
import 'features/history/data/history_exercise_source.dart';
import 'features/onboarding/data/onboarding_gate.dart';
import 'features/settings/data/app_settings.dart';

/// App startup shared by `main()` and the screenshot integration tests:
/// open the DB, install/refresh the bundled catalog (catalog tables only),
/// load persisted settings and the first-run flag, and build the root
/// ProviderContainer (incl. the history feature's ExerciseHistorySource).
///
/// [settingsOverride] forces settings (e.g. language) without persisting them;
/// such runs (screenshots, integration tests) also skip onboarding.
/// [overrides] are appended (integration tests: e.g. a fake share sheet).
Future<ProviderContainer> bootstrapApp({AppSettings? settingsOverride, List<Override> overrides = const []}) async {
  final db = AppDatabase.open();
  await CatalogInstaller(db).installBundledIfNeeded();
  final settings = settingsOverride ?? await AppSettings.load(db);
  final onboardingDone = settingsOverride != null || await loadOnboardingDone(db);
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(
        settingsOverride == null ? DbSettingsStore(db) : MemorySettingsStore(),
      ),
      initialAppSettingsProvider.overrideWithValue(settings),
      onboardingDoneAtLaunchProvider.overrideWithValue(onboardingDone),
      exerciseHistorySourceProvider.overrideWith((ref) => createExerciseHistorySource(ref.watch(appDatabaseProvider))),
      ...overrides,
    ],
  );
}
