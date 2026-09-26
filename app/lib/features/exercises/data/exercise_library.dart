import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/catalog_repository.dart';
import '../../../core/utils/units.dart';

/// What the library / picker is currently asking the catalog for.
@immutable
class ExerciseQuery {
  const ExerciseQuery({this.text = '', this.target, this.equipment});

  /// Raw search text (normalized by `CatalogRepository.search`).
  final String text;

  /// Dataset `target` key, or null for all muscles.
  final String? target;

  /// Dataset `equipment` key, or null for all equipment.
  final String? equipment;

  bool get isEmpty => text.trim().isEmpty && target == null && equipment == null;

  ExerciseQuery copyWith({String? text, String? Function()? target, String? Function()? equipment}) => ExerciseQuery(
    text: text ?? this.text,
    target: target == null ? this.target : target(),
    equipment: equipment == null ? this.equipment : equipment(),
  );

  @override
  bool operator ==(Object other) =>
      other is ExerciseQuery && other.text == text && other.target == target && other.equipment == equipment;

  @override
  int get hashCode => Object.hash(text, target, equipment);
}

/// One catalog exercise by id (null if the catalog no longer has it).
final exerciseByIdProvider = FutureProvider.autoDispose.family<Exercise?, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).exercise(id),
  retry: (_, _) => null,
);

/// Decoded JSON string list column (`secondary_muscles`, instructions).
List<String> decodeStringList(String? json) {
  if (json == null || json.isEmpty) return const [];
  final v = jsonDecode(json);
  return v is List ? v.whereType<String>().toList() : const [];
}

/// Instruction steps in the app language: Arabic when translated, otherwise
/// English. [englishFallback] is true when Arabic was wanted but missing.
({List<String> steps, bool englishFallback}) exerciseInstructions(Exercise e, Locale locale) {
  final wantsArabic = locale.languageCode == 'ar';
  if (wantsArabic) {
    final ar = decodeStringList(e.instructionsAr);
    if (ar.isNotEmpty) return (steps: ar, englishFallback: false);
  }
  return (steps: decodeStringList(e.instructionsEn), englishFallback: wantsArabic);
}

/// The weight unit chosen in settings (`unit` key, JSON "kg" | "lb"; default
/// kg). Read-only here: the settings feature owns writing it.
final exercisesWeightUnitProvider = FutureProvider<WeightUnit>((ref) async {
  final json = await ref.watch(appDatabaseProvider).readSetting('unit');
  if (json == null) return WeightUnit.kg;
  return jsonDecode(json) == 'lb' ? WeightUnit.lb : WeightUnit.kg;
}, retry: (_, _) => null);
