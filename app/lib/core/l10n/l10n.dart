import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// `context.l10n.shellTabWorkout` etc. All UI strings come from ARB files in
/// `arb/` — never hard-code user-visible text.
extension AzmL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Supported app languages. Arabic first (primary market), English second.
abstract final class AzmLocales {
  static const Locale ar = Locale('ar');
  static const Locale en = Locale('en');
  static const List<Locale> supported = [ar, en];

  /// Device-language resolution for the "System" setting: any Arabic variant
  /// → Arabic; everything else → English.
  static Locale resolve(List<Locale>? deviceLocales) {
    for (final l in deviceLocales ?? const <Locale>[]) {
      if (l.languageCode == 'ar') return ar;
      if (l.languageCode == 'en') return en;
    }
    return en;
  }
}

/// Number formatting with WESTERN digits (0-9) in both languages, regardless
/// of the locale's native numbering system. Always format numbers through here.
abstract final class AzmNumbers {
  static final NumberFormat _int = NumberFormat.decimalPattern('en');

  /// 12,450
  static String integer(num value) => _int.format(value.round());

  /// Up to [maxDecimals] fraction digits, trailing zeros dropped: 62.5, 60.
  static String decimal(num value, {int maxDecimals = 1}) {
    final f = NumberFormat.decimalPattern('en')
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = maxDecimals;
    return f.format(value);
  }
}
