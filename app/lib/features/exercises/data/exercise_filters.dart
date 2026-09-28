import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'exercise_filters_data.dart';

/// The three filter types of the library and the exercise picker.
enum FilterKind { place, muscle, equipment }

/// A section of the Muscle Group sheet (docs/SPEC.md → Exercise library).
typedef MuscleSection = ({String id, List<String> groups});

/// Which filter cards an exercise belongs to, from its dataset keys.
///
/// Built from `exercise_filters_data.dart`, the merged copy of the
/// reviewable `data/{equipment,place,muscle}_mapping.json` generated (and
/// validated against the dataset) by `tools/build_catalog.dart`:
/// - equipment group = `equipment.map[exercise.equipment]` (else `other`);
/// - places = every place whose list contains that equipment group (gym has
///   them all);
/// - muscle group = `muscle.target[exercise.target]`, else
///   `muscle.body_part[exercise.bodyPart]`, else `muscle.fallback`; plus
///   `full_body` for the ids listed in `muscle.full_body`.
@immutable
class ExerciseFilterMapping {
  const ExerciseFilterMapping({
    required this.places,
    required this.equipmentGroups,
    required this.muscleSections,
    required this.equipmentByValue,
    required this.placeEquipment,
    required this.muscleByTarget,
    required this.muscleByBodyPart,
    required this.muscleFallback,
    required this.fullBodyIds,
  });

  factory ExerciseFilterMapping.fromJson(Map<String, dynamic> json) {
    final eq = json['equipment'] as Map<String, dynamic>;
    final place = (json['place'] as Map<String, dynamic>)['places'] as Map<String, dynamic>;
    final muscle = json['muscle'] as Map<String, dynamic>;
    List<String> strings(Object? v) => (v as List).cast<String>();
    return ExerciseFilterMapping(
      places: place.keys.toList(),
      equipmentGroups: strings(eq['groups']),
      muscleSections: [
        for (final s in (muscle['sections'] as Map<String, dynamic>).entries) (id: s.key, groups: strings(s.value)),
      ],
      equipmentByValue: (eq['map'] as Map<String, dynamic>).cast<String, String>(),
      placeEquipment: {for (final p in place.entries) p.key: strings(p.value).toSet()},
      muscleByTarget: (muscle['target'] as Map<String, dynamic>).cast<String, String>(),
      muscleByBodyPart: (muscle['body_part'] as Map<String, dynamic>).cast<String, String>(),
      muscleFallback: muscle['fallback'] as String,
      fullBodyIds: strings(muscle['full_body']).toSet(),
    );
  }

  /// The mapping shipped with this build.
  static final ExerciseFilterMapping bundled =
      ExerciseFilterMapping.fromJson(jsonDecode(exerciseFiltersJson) as Map<String, dynamic>);

  /// Card order of each sheet.
  final List<String> places;
  final List<String> equipmentGroups;
  final List<MuscleSection> muscleSections;

  final Map<String, String> equipmentByValue;
  final Map<String, Set<String>> placeEquipment;
  final Map<String, String> muscleByTarget;
  final Map<String, String> muscleByBodyPart;
  final String muscleFallback;
  final Set<String> fullBodyIds;

  static const fullBody = 'full_body';
  static const otherGroup = 'other';

  List<String> get muscleGroups => [for (final s in muscleSections) ...s.groups];

  /// Every card id of [kind], in sheet order.
  List<String> optionsOf(FilterKind kind) => switch (kind) {
        FilterKind.place => places,
        FilterKind.muscle => muscleGroups,
        FilterKind.equipment => equipmentGroups,
      };

  String equipmentOf(Exercise e) => equipmentByValue[e.equipment] ?? otherGroup;

  Set<String> placesOf(Exercise e) {
    final g = equipmentOf(e);
    return {for (final p in placeEquipment.entries) if (p.value.contains(g)) p.key};
  }

  Set<String> musclesOf(Exercise e) => {
        muscleByTarget[e.target] ?? muscleByBodyPart[e.bodyPart] ?? muscleFallback,
        if (fullBodyIds.contains(e.id)) fullBody,
      };

  ExerciseTags tagsOf(Exercise e) => ExerciseTags(places: placesOf(e), muscles: musclesOf(e), equipment: equipmentOf(e));
}

/// Filter cards one exercise belongs to (precomputed by the search index).
@immutable
class ExerciseTags {
  const ExerciseTags({required this.places, required this.muscles, required this.equipment});

  final Set<String> places;
  final Set<String> muscles;
  final String equipment;
}

/// The active filters of one screen: OR within a type, AND across types
/// (and AND with the search text). Empty type = no constraint.
@immutable
class ExerciseFilters {
  const ExerciseFilters({this.places = const {}, this.muscles = const {}, this.equipment = const {}});

  final Set<String> places;
  final Set<String> muscles;
  final Set<String> equipment;

  static const none = ExerciseFilters();

  bool get isEmpty => places.isEmpty && muscles.isEmpty && equipment.isEmpty;

  /// Number of selected cards over all types.
  int get count => places.length + muscles.length + equipment.length;

  Set<String> of(FilterKind kind) => switch (kind) {
        FilterKind.place => places,
        FilterKind.muscle => muscles,
        FilterKind.equipment => equipment,
      };

  ExerciseFilters withKind(FilterKind kind, Set<String> values) => ExerciseFilters(
        places: kind == FilterKind.place ? Set.unmodifiable(values) : places,
        muscles: kind == FilterKind.muscle ? Set.unmodifiable(values) : muscles,
        equipment: kind == FilterKind.equipment ? Set.unmodifiable(values) : equipment,
      );

  bool matches(ExerciseTags t) =>
      (places.isEmpty || t.places.any(places.contains)) &&
      (muscles.isEmpty || t.muscles.any(muscles.contains)) &&
      (equipment.isEmpty || equipment.contains(t.equipment));

  /// Drops ids a (newer) mapping no longer has.
  ExerciseFilters validFor(ExerciseFilterMapping m) => ExerciseFilters(
        places: places.where(m.places.contains).toSet(),
        muscles: muscles.where(m.muscleGroups.contains).toSet(),
        equipment: equipment.where(m.equipmentGroups.contains).toSet(),
      );

  Map<String, Object> toJson() => {
        'place': places.toList()..sort(),
        'muscle': muscles.toList()..sort(),
        'equipment': equipment.toList()..sort(),
      };

  /// Lenient: anything unreadable means "no filters".
  static ExerciseFilters fromJson(Object? json) {
    if (json is! Map) return none;
    Set<String> read(String k) {
      final v = json[k];
      return v is List ? v.whereType<String>().toSet() : const {};
    }

    return ExerciseFilters(places: read('place'), muscles: read('muscle'), equipment: read('equipment'));
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseFilters &&
      setEquals(other.places, places) &&
      setEquals(other.muscles, muscles) &&
      setEquals(other.equipment, equipment);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(places),
        Object.hashAllUnordered(muscles),
        Object.hashAllUnordered(equipment),
      );
}

/// Which screen's filters are remembered (settings key per screen).
enum FilterScreen {
  library('exercises_filters_library'),
  picker('exercises_filters_picker');

  const FilterScreen(this.settingsKey);

  /// Settings key (value = [ExerciseFilters.toJson], JSON-encoded).
  final String settingsKey;
}

/// Last-used filters, per screen, in the `settings` table (docs/DATA.md).
class ExerciseFilterStore {
  ExerciseFilterStore(this.db);

  final AppDatabase db;

  Future<ExerciseFilters> load(FilterScreen screen) async {
    try {
      final raw = await db.readSetting(screen.settingsKey);
      return raw == null ? ExerciseFilters.none : ExerciseFilters.fromJson(jsonDecode(raw));
    } on Object {
      return ExerciseFilters.none;
    }
  }

  Future<void> save(FilterScreen screen, ExerciseFilters filters) =>
      db.writeSetting(screen.settingsKey, jsonEncode(filters.toJson()));
}

final exerciseFilterStoreProvider = Provider<ExerciseFilterStore>((ref) => ExerciseFilterStore(ref.watch(appDatabaseProvider)));

/// The bundled mapping (overridable in tests).
final exerciseFilterMappingProvider = Provider<ExerciseFilterMapping>((ref) => ExerciseFilterMapping.bundled);
