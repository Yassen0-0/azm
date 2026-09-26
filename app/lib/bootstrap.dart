import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/app_database.dart';
import 'core/db/catalog_installer.dart';
import 'features/settings/data/app_settings.dart';

/// App startup shared by `main()` and the screenshot integration tests:
/// open the DB, install/refresh the bundled catalog (catalog tables only),
/// load persisted settings, and build the root ProviderContainer.
///
/// [settingsOverride] forces settings (e.g. language) without persisting them.
Future<ProviderContainer> bootstrapApp({AppSettings? settingsOverride}) async {
  final db = AppDatabase.open();
  await CatalogInstaller(db).installBundledIfNeeded();
  final settings = settingsOverride ?? await AppSettings.load(db);
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(
        settingsOverride == null ? DbSettingsStore(db) : MemorySettingsStore(),
      ),
      initialAppSettingsProvider.overrideWithValue(settings),
    ],
  );
}
