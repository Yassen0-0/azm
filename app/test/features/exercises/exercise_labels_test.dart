import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/features/exercises/data/exercise_labels.dart';
import 'package:azm/features/exercises/data/exercise_library.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

void main() {
  late AppDatabase db;
  late List<Exercise> all;

  setUpAll(() async {
    db = await openCatalogDb();
    all = await db.select(db.exercises).get();
  });
  tearDownAll(() => db.close());

  // Arabic labels can never equal the capitalized English key, so a fallback
  // there means a missing ARB entry. English must at least be non-empty.
  for (final lang in ['ar', 'en']) {
    test('every dataset key of the bundled catalog has a $lang label', () {
      final l = lookupAppLocalizations(Locale(lang));
      String fallback(String k) => lang == 'ar' ? k[0].toUpperCase() + k.substring(1) : '';
      final muscles = {for (final e in all) e.target, for (final e in all) ...decodeStringList(e.secondaryMuscles)};
      final equipment = {for (final e in all) e.equipment};
      final bodyParts = {for (final e in all) e.bodyPart};
      for (final k in muscles) {
        expect(ExerciseLabels.muscle(l, k), isNot(fallback(k)), reason: 'muscle "$k"');
      }
      for (final k in equipment) {
        expect(ExerciseLabels.equipmentLabel(l, k), isNot(fallback(k)), reason: 'equipment "$k"');
      }
      for (final k in bodyParts) {
        expect(ExerciseLabels.bodyPart(l, k), isNot(fallback(k)), reason: 'body part "$k"');
      }
    });
  }

  test('chip and sheet lists cover exactly the catalog targets / equipment', () {
    expect(ExerciseLabels.targets.toSet(), {for (final e in all) e.target});
    expect(ExerciseLabels.equipment.toSet(), {for (final e in all) e.equipment});
  });

  test('unknown key falls back to the raw key', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(ExerciseLabels.muscle(l, 'new muscle'), 'New muscle');
  });
}
