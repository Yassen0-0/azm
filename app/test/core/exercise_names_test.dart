import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/exercise_names.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise ex({String? ar}) => Exercise(
  id: '0025',
  nameEn: 'Barbell Bench Press',
  nameAr: ar,
  aliasesAr: '[]',
  bodyPart: 'chest',
  target: 'pectorals',
  secondaryMuscles: '[]',
  equipment: 'barbell',
  instructionsEn: '[]',
  instructionsAr: null,
  mediaId: 'x',
  searchNorm: '',
  hidden: false,
);

void main() {
  test('Arabic UI: Arabic primary, English secondary', () {
    expect(exerciseNames(ex(ar: 'ضغط بار مستوي'), const Locale('ar')), (
      primary: 'ضغط بار مستوي',
      secondary: 'Barbell Bench Press',
    ));
  });
  test('English UI: English primary, Arabic secondary', () {
    expect(exerciseNames(ex(ar: 'ضغط بار مستوي'), const Locale('en')), (
      primary: 'Barbell Bench Press',
      secondary: 'ضغط بار مستوي',
    ));
  });
  test('no Arabic name yet: English only, in both languages', () {
    expect(exerciseNames(ex(), const Locale('ar')), (
      primary: 'Barbell Bench Press',
      secondary: null,
    ));
    expect(exerciseNames(ex(), const Locale('en')), (
      primary: 'Barbell Bench Press',
      secondary: null,
    ));
  });
}
