import 'dart:convert';
import 'dart:io';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_repository.dart';
import 'package:azm/core/widgets/filter_icon.dart';
import 'package:azm/features/exercises/data/exercise_filters.dart';
import 'package:azm/features/exercises/data/exercise_library.dart';
import 'package:azm/features/exercises/data/exercise_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

/// Unit tests for the Place / Muscle Group / Equipment filters: the mapping
/// (data/*_mapping.json → exercise_filters_data.dart) and the filtering.
void main() {
  final m = ExerciseFilterMapping.bundled;

  // The raw dataset (tests run from app/).
  final raw = (jsonDecode(File('../data/raw/exercises.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final hidden = ((jsonDecode(File('../data/hidden_exercises.json').readAsStringSync()) as Map)['hidden'] as Map).keys.toSet();

  group('mapping', () {
    test('every dataset equipment value and target is mapped explicitly', () {
      expect({for (final e in raw) e['equipment'] as String}.difference(m.equipmentByValue.keys.toSet()), isEmpty);
      expect({for (final e in raw) e['target'] as String}.difference(m.muscleByTarget.keys.toSet()), isEmpty);
    });

    test('card order and ids match the spec', () {
      expect(m.places, ['gym', 'home', 'bands']);
      expect(m.equipmentGroups, [
        'none', 'barbell', 'dumbbell', 'kettlebell', 'machine', 'cable', 'plate', 'resistance_band', 'suspension_band', 'other', //
      ]);
      expect([for (final s in m.muscleSections) s.id], ['upper', 'lower', 'other']);
      expect(m.muscleSections[0].groups, [
        'abs', 'biceps', 'chest', 'forearms', 'lats', 'lower_back', 'neck', 'shoulders', 'traps', 'triceps', 'upper_back', //
      ]);
      expect(m.muscleSections[1].groups, ['abductors', 'adductors', 'calves', 'glutes', 'hamstrings', 'quads']);
      expect(m.muscleSections[2].groups, ['cardio', 'full_body', 'other']);
    });

    Exercise ex({String id = '9999', String equipment = 'barbell', String target = 'pectorals', String bodyPart = 'chest'}) =>
        Exercise(
          id: id,
          nameEn: 'X',
          aliasesAr: '[]',
          bodyPart: bodyPart,
          target: target,
          secondaryMuscles: '[]',
          equipment: equipment,
          instructionsEn: '[]',
          mediaId: 'm',
          searchNorm: 'x',
          hidden: false,
        );

    test('equipment groups', () {
      expect(m.equipmentOf(ex(equipment: 'body weight')), 'none');
      expect(m.equipmentOf(ex(equipment: 'ez barbell')), 'barbell');
      expect(m.equipmentOf(ex(equipment: 'trap bar')), 'barbell');
      expect(m.equipmentOf(ex(equipment: 'smith machine')), 'machine');
      expect(m.equipmentOf(ex(equipment: 'weighted')), 'plate');
      expect(m.equipmentOf(ex(equipment: 'band')), 'resistance_band');
      expect(m.equipmentOf(ex(equipment: 'resistance band')), 'resistance_band');
      expect(m.equipmentOf(ex(equipment: 'stability ball')), 'other');
      expect(m.equipmentOf(ex(equipment: 'something new')), 'other'); // future value
    });

    test('place is derived from equipment: Home = bodyweight/dumbbell/kettlebell/bands; Bands = bands only; Gym = all', () {
      expect(m.placesOf(ex(equipment: 'barbell')), {'gym'});
      expect(m.placesOf(ex(equipment: 'leverage machine')), {'gym'});
      expect(m.placesOf(ex(equipment: 'body weight')), {'gym', 'home'});
      expect(m.placesOf(ex(equipment: 'dumbbell')), {'gym', 'home'});
      expect(m.placesOf(ex(equipment: 'kettlebell')), {'gym', 'home'});
      expect(m.placesOf(ex(equipment: 'band')), {'gym', 'home', 'bands'});
      expect(m.placesOf(ex(equipment: 'resistance band')), {'gym', 'home', 'bands'});
      for (final v in m.equipmentByValue.keys) {
        expect(m.placesOf(ex(equipment: v)), contains('gym'), reason: v);
      }
    });

    test('muscle group: target first, then body part, then "other"; full body adds a group', () {
      expect(m.musclesOf(ex(target: 'pectorals')), {'chest'});
      expect(m.musclesOf(ex(target: 'serratus anterior')), {'chest'});
      expect(m.musclesOf(ex(target: 'delts')), {'shoulders'});
      expect(m.musclesOf(ex(target: 'spine')), {'lower_back'});
      expect(m.musclesOf(ex(target: 'levator scapulae')), {'neck'});
      expect(m.musclesOf(ex(target: 'cardiovascular system')), {'cardio'});
      expect(m.musclesOf(ex(target: 'new muscle', bodyPart: 'waist')), {'abs'}); // body-part fallback
      expect(m.musclesOf(ex(target: 'new muscle', bodyPart: 'upper arms')), {'other'});
      expect(m.musclesOf(ex(id: '1160', target: 'cardiovascular system')), {'cardio', 'full_body'}); // burpee
      expect(m.musclesOf(ex(id: '0648', target: 'hamstrings')), {'hamstrings', 'full_body'}); // power clean
    });

    test('every card has an original icon and every full-body id is a visible exercise', () {
      for (final k in FilterKind.values) {
        for (final id in m.optionsOf(k)) {
          expect(FilterIcon.exists('${k.name}_$id'), isTrue, reason: '${k.name}_$id');
        }
      }
      final ids = {for (final e in raw) e['id'] as String};
      for (final id in m.fullBodyIds) {
        expect(ids, contains(id));
        expect(hidden, isNot(contains(id)));
      }
    });
  });

  group('ExerciseFilters', () {
    const tags = ExerciseTags(places: {'gym', 'home'}, muscles: {'chest'}, equipment: 'dumbbell');

    test('OR within a type, AND across types; empty = no constraint', () {
      expect(ExerciseFilters.none.matches(tags), isTrue);
      expect(const ExerciseFilters(muscles: {'chest', 'biceps'}).matches(tags), isTrue);
      expect(const ExerciseFilters(muscles: {'biceps'}).matches(tags), isFalse);
      expect(const ExerciseFilters(muscles: {'chest'}, equipment: {'dumbbell', 'barbell'}).matches(tags), isTrue);
      expect(const ExerciseFilters(muscles: {'chest'}, equipment: {'barbell'}).matches(tags), isFalse);
      expect(const ExerciseFilters(places: {'home'}, muscles: {'chest'}, equipment: {'dumbbell'}).matches(tags), isTrue);
      expect(const ExerciseFilters(places: {'bands'}, muscles: {'chest'}).matches(tags), isFalse);
    });

    test('count, withKind, equality', () {
      final f = ExerciseFilters.none.withKind(FilterKind.muscle, {'chest', 'abs'}).withKind(FilterKind.place, {'home'});
      expect(f.count, 3);
      expect(f.of(FilterKind.muscle), {'chest', 'abs'});
      expect(f, const ExerciseFilters(places: {'home'}, muscles: {'abs', 'chest'}));
      expect(f.withKind(FilterKind.muscle, {}).count, 1);
    });

    test('JSON round trip; unreadable → none; unknown ids dropped', () {
      const f = ExerciseFilters(places: {'home'}, muscles: {'chest', 'abs'}, equipment: {'dumbbell'});
      expect(ExerciseFilters.fromJson(jsonDecode(jsonEncode(f.toJson()))), f);
      expect(ExerciseFilters.fromJson('nope'), ExerciseFilters.none);
      expect(ExerciseFilters.fromJson({'muscle': 3}), ExerciseFilters.none);
      expect(
        const ExerciseFilters(muscles: {'chest', 'wings'}, equipment: {'jetpack'}).validFor(m),
        const ExerciseFilters(muscles: {'chest'}),
      );
    });
  });

  group('search index with filters (real catalog)', () {
    late AppDatabase db;
    late ExerciseSearchIndex index;
    late List<Exercise> visible;

    setUpAll(() async {
      db = await openCatalogDb();
      index = await ExerciseSearchIndex.load(CatalogRepository(db), mapping: m);
      visible = await CatalogRepository(db).search('');
    });
    tearDownAll(() => db.close());

    int count(ExerciseFilters f, {String text = ''}) => index.count(ExerciseQuery(text: text, filters: f));

    test('results per card (the report in docs/DECISIONS_LOG.md)', () {
      expect(visible.length, 1291);
      final place = {for (final p in m.places) p: count(ExerciseFilters(places: {p}))};
      expect(place, {'gym': 1291, 'home': 719, 'bands': 61});
      final muscle = {for (final g in m.muscleGroups) g: count(ExerciseFilters(muscles: {g}))};
      expect(muscle, {
        'abs': 166, 'biceps': 143, 'chest': 158, 'forearms': 36, 'lats': 79, 'lower_back': 19, 'neck': 2, //
        'shoulders': 135, 'traps': 15, 'triceps': 140, 'upper_back': 87, 'abductors': 5, 'adductors': 6, //
        'calves': 58, 'glutes': 141, 'hamstrings': 28, 'quads': 44, 'cardio': 29, 'full_body': 30, 'other': 0, //
      });
      final equipment = {for (final g in m.equipmentGroups) g: count(ExerciseFilters(equipment: {g}))};
      expect(equipment, {
        'none': 336, 'barbell': 175, 'dumbbell': 281, 'kettlebell': 41, 'machine': 142, 'cable': 156, 'plate': 35, //
        'resistance_band': 61, 'suspension_band': 0, 'other': 64, //
      });
      // Every visible exercise has exactly one equipment group and ≥ 1 muscle group.
      expect(equipment.values.fold(0, (a, b) => a + b), 1291);
    });

    test('cards without any exercise are hidden (suspension band, muscle "other"); the rest keep their order', () {
      expect(index.availableOptions(FilterKind.place), ['gym', 'home', 'bands']);
      expect(index.availableOptions(FilterKind.equipment), [
        for (final g in m.equipmentGroups)
          if (g != 'suspension_band') g,
      ]);
      expect(index.availableOptions(FilterKind.muscle), [
        for (final g in m.muscleGroups)
          if (g != 'other') g,
      ]);
      // Every shown card really has results; every hidden one really has none.
      for (final k in FilterKind.values) {
        for (final id in m.optionsOf(k)) {
          final n = count(ExerciseFilters.none.withKind(k, {id}));
          expect(index.availableOptions(k).contains(id), n > 0, reason: '${k.name}/$id has $n');
        }
      }
      // A remembered hidden card can never filter the list.
      expect(
        index.onlyAvailable(const ExerciseFilters(muscles: {'other', 'chest'}, equipment: {'suspension_band'})),
        const ExerciseFilters(muscles: {'chest'}),
      );
    });

    test('filters combine with each other and with the search text', () {
      final chestOrBiceps = count(const ExerciseFilters(muscles: {'chest', 'biceps'}));
      expect(chestOrBiceps, 158 + 143);
      final withBarbell = count(const ExerciseFilters(muscles: {'chest', 'biceps'}, equipment: {'barbell'}));
      final expected = visible.where((e) {
        final t = m.tagsOf(e);
        return (t.muscles.contains('chest') || t.muscles.contains('biceps')) && t.equipment == 'barbell';
      }).length;
      expect(withBarbell, expected);
      expect(withBarbell, lessThan(chestOrBiceps));

      final benchAtHome = index.search(const ExerciseQuery(text: 'bench', filters: ExerciseFilters(places: {'home'})));
      expect(benchAtHome, isNotEmpty);
      for (final e in benchAtHome) {
        expect(m.placesOf(e), contains('home'));
        expect(e.searchNorm, contains('bench'));
      }
      expect(benchAtHome.map((e) => e.id), isNot(contains('0025'))); // barbell bench press is gym-only
      expect(count(const ExerciseFilters(places: {'bands'}, equipment: {'barbell'})), 0);
      // count() == search().length for any query.
      const q = ExerciseQuery(text: 'curl', filters: ExerciseFilters(places: {'home'}, muscles: {'biceps'}));
      expect(index.count(q), index.search(q).length);
    });
  });
}
