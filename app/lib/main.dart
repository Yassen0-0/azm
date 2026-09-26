import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'core/db/catalog_installer.dart';
import 'features/settings/data/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the DB, install/refresh the bundled catalog (catalog tables only),
  // and load settings — all before the first frame (the native splash shows).
  final db = AppDatabase.open();
  await CatalogInstaller(db).installBundledIfNeeded();
  final settings = await AppSettings.load(db);

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(DbSettingsStore(db)),
        initialAppSettingsProvider.overrideWithValue(settings),
      ],
      child: const AzmApp(),
    ),
  );
}
