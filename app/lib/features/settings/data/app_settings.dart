import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';

/// Language preference. `system` follows the device (Arabic if the device is
/// Arabic, English otherwise).
enum LanguagePref { system, ar, en }

/// Theme preference. Dark is the default.
enum ThemePref { dark, light }

/// Settings keys in the `settings` table (values are JSON-encoded).
abstract final class SettingsKeys {
  static const locale = 'locale';
  static const theme = 'theme';
}

@immutable
class AppSettings {
  const AppSettings({this.language = LanguagePref.system, this.theme = ThemePref.dark});

  final LanguagePref language;
  final ThemePref theme;

  /// Locale to force on MaterialApp, or null to follow the device.
  Locale? get forcedLocale => switch (language) {
        LanguagePref.system => null,
        LanguagePref.ar => AzmLocales.ar,
        LanguagePref.en => AzmLocales.en,
      };

  ThemeMode get themeMode => theme == ThemePref.dark ? ThemeMode.dark : ThemeMode.light;

  AppSettings copyWith({LanguagePref? language, ThemePref? theme}) =>
      AppSettings(language: language ?? this.language, theme: theme ?? this.theme);

  /// Loads from the DB; unknown/missing values fall back to defaults.
  static Future<AppSettings> load(AppDatabase db) async {
    T pick<T extends Enum>(List<T> values, String? json, T fallback) {
      if (json == null) return fallback;
      final name = jsonDecode(json);
      return values.firstWhere((v) => v.name == name, orElse: () => fallback);
    }

    return AppSettings(
      language: pick(LanguagePref.values, await db.readSetting(SettingsKeys.locale), LanguagePref.system),
      theme: pick(ThemePref.values, await db.readSetting(SettingsKeys.theme), ThemePref.dark),
    );
  }
}

/// Where settings are persisted.
abstract interface class SettingsStore {
  Future<void> write(String key, String jsonValue);
}

class DbSettingsStore implements SettingsStore {
  DbSettingsStore(this.db);

  final AppDatabase db;

  @override
  Future<void> write(String key, String jsonValue) => db.writeSetting(key, jsonValue);
}

/// Default store (tests, previews): keeps nothing.
class MemorySettingsStore implements SettingsStore {
  final Map<String, String> values = {};

  @override
  Future<void> write(String key, String jsonValue) async => values[key] = jsonValue;
}

/// Overridden in main() with the DB-backed store.
final settingsStoreProvider = Provider<SettingsStore>((ref) => MemorySettingsStore());

/// Settings loaded before the first frame (overridden in main()).
final initialAppSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

/// App-wide settings; every change is persisted immediately.
class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialAppSettingsProvider);

  void setLanguage(LanguagePref value) {
    state = state.copyWith(language: value);
    unawaited(ref.read(settingsStoreProvider).write(SettingsKeys.locale, jsonEncode(value.name)));
  }

  void setTheme(ThemePref value) {
    state = state.copyWith(theme: value);
    unawaited(ref.read(settingsStoreProvider).write(SettingsKeys.theme, jsonEncode(value.name)));
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);
