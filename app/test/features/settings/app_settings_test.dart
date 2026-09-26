import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: System language, dark theme', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final s = await AppSettings.load(db);
    expect(s.language, LanguagePref.system);
    expect(s.theme, ThemePref.dark);
  });

  test('changes are persisted and survive a restart', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      settingsStoreProvider.overrideWithValue(DbSettingsStore(db)),
    ]);
    container.read(appSettingsProvider.notifier)
      ..setLanguage(LanguagePref.ar)
      ..setTheme(ThemePref.light);
    container.dispose();
    await Future<void>.delayed(Duration.zero); // let the unawaited writes land

    final reloaded = await AppSettings.load(db);
    expect(reloaded.language, LanguagePref.ar);
    expect(reloaded.theme, ThemePref.light);
    expect(await db.readSetting('locale'), '"ar"');
  });

  test('corrupt/unknown stored values fall back to defaults', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.writeSetting('locale', '"fr"');
    expect((await AppSettings.load(db)).language, LanguagePref.system);
  });
}
