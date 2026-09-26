import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';

/// Language preference. `system` follows the device (Arabic if the device is
/// Arabic, English otherwise).
enum LanguagePref { system, ar, en }

/// Theme preference. Dark is the default.
enum ThemePref { dark, light }

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
}

/// App-wide settings.
///
/// TODO(Phase 3): persist to the Drift `settings` table (keys `locale`, `theme`)
/// and load on startup. Until then values reset on restart.
class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setLanguage(LanguagePref value) => state = state.copyWith(language: value);

  void setTheme(ThemePref value) => state = state.copyWith(theme: value);
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);
