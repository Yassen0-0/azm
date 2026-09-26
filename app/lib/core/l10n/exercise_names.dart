import 'package:flutter/widgets.dart';

import '../db/app_database.dart';

/// Bilingual exercise names (docs/SPEC.md → Exercise library): primary name in
/// the app language, secondary (smaller) in the other language. When the
/// exercise has no Arabic name yet, the English name is primary and there is
/// no secondary.
typedef ExerciseNames = ({String primary, String? secondary});

ExerciseNames exerciseNames(Exercise e, Locale locale) {
  final ar = e.nameAr;
  if (ar == null || ar.isEmpty) return (primary: e.nameEn, secondary: null);
  return locale.languageCode == 'ar'
      ? (primary: ar, secondary: e.nameEn)
      : (primary: e.nameEn, secondary: ar);
}

extension ExerciseNamesContext on BuildContext {
  ExerciseNames namesOf(Exercise e) => exerciseNames(e, Localizations.localeOf(this));
}
