// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Azm';

  @override
  String get shellTabWorkout => 'Workout';

  @override
  String get shellTabHistory => 'History';

  @override
  String get shellTabExercises => 'Exercises';

  @override
  String get shellOpenSettings => 'Settings';

  @override
  String get shellComingSoon => 'This screen is still being built';

  @override
  String get commonBack => 'Back';

  @override
  String get exercisesSearchHint => 'Search exercises';

  @override
  String get exercisesSearchClear => 'Clear search';

  @override
  String get exercisesFilterAll => 'All';

  @override
  String get exercisesFilterEquipment => 'Equipment';

  @override
  String get exercisesEquipmentSheetTitle => 'Filter by equipment';

  @override
  String get exercisesEquipmentAll => 'All equipment';

  @override
  String exercisesRemoveEquipmentFilter(String equipment) {
    return 'Remove filter $equipment';
  }

  @override
  String exercisesResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'No exercises',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoResultsTitle => 'No exercises found';

  @override
  String get exercisesNoResultsBody =>
      'Try another name, or clear the filters.';

  @override
  String get exercisesClearFilters => 'Clear filters';

  @override
  String get exercisesLibraryEmpty => 'The exercise library isn\'t ready yet';

  @override
  String exercisesPrBadge(String weight) {
    return 'Your record: $weight';
  }

  @override
  String get exercisesUnitKg => 'kg';

  @override
  String get exercisesUnitLb => 'lb';

  @override
  String exercisesWeightValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String exercisesSetValue(String weight, String reps) {
    return '$weight × $reps';
  }

  @override
  String get exercisesPickerTitle => 'Add exercises';

  @override
  String get exercisesPickerCancel => 'Cancel';

  @override
  String get exercisesPickerAdd => 'Add';

  @override
  String exercisesPickerAddCount(int count) {
    return 'Add ($count)';
  }

  @override
  String exercisesPickerSelected(int index) {
    return 'Selected, number $index';
  }

  @override
  String get exercisesUnknown => 'Unknown exercise';

  @override
  String get exercisesDetailTarget => 'Target muscle';

  @override
  String get exercisesDetailSecondary => 'Secondary muscles';

  @override
  String get exercisesDetailEquipment => 'Equipment';

  @override
  String get exercisesDetailBodyPart => 'Body part';

  @override
  String get exercisesDetailInstructions => 'How to do it';

  @override
  String get exercisesDetailInstructionsEnglishOnly =>
      'Instructions are only available in English for now.';

  @override
  String get exercisesDetailAttribution =>
      '© Gym visual — https://gymvisual.com/';

  @override
  String get exercisesDetailRecords => 'Personal records';

  @override
  String get exercisesRecordHeaviest => 'Heaviest weight';

  @override
  String get exercisesRecordBest1Rm => 'Best est. 1RM';

  @override
  String get exercisesRecordBestVolume => 'Best set volume';

  @override
  String get exercisesDetailProgress => 'Progress';

  @override
  String get exercisesChartHeaviest => 'Heaviest';

  @override
  String get exercisesChart1Rm => '1RM';

  @override
  String get exercisesChartVolume => 'Volume';

  @override
  String get exercisesChartEmpty =>
      'The chart appears after at least two workouts.';

  @override
  String get exercisesDetailHistory => 'Your history';

  @override
  String get exercisesHistoryEmpty =>
      'You haven\'t done this exercise yet. Log a set and your history shows up here.';

  @override
  String get exercisesSetLabelWarmup => 'W';

  @override
  String get exercisesSetLabelDrop => 'D';

  @override
  String get exercisesSetLabelFailure => 'F';

  @override
  String get exercisesMuscleAbs => 'Abs';

  @override
  String get exercisesMusclePectorals => 'Chest';

  @override
  String get exercisesMuscleBiceps => 'Biceps';

  @override
  String get exercisesMuscleGlutes => 'Glutes';

  @override
  String get exercisesMuscleDelts => 'Shoulders';

  @override
  String get exercisesMuscleTriceps => 'Triceps';

  @override
  String get exercisesMuscleUpperBack => 'Upper back';

  @override
  String get exercisesMuscleLats => 'Lats';

  @override
  String get exercisesMuscleCalves => 'Calves';

  @override
  String get exercisesMuscleQuads => 'Quads';

  @override
  String get exercisesMuscleForearms => 'Forearms';

  @override
  String get exercisesMuscleCardiovascularSystem => 'Cardio';

  @override
  String get exercisesMuscleHamstrings => 'Hamstrings';

  @override
  String get exercisesMuscleSpine => 'Spine';

  @override
  String get exercisesMuscleTraps => 'Traps';

  @override
  String get exercisesMuscleAdductors => 'Adductors';

  @override
  String get exercisesMuscleSerratusAnterior => 'Serratus';

  @override
  String get exercisesMuscleAbductors => 'Abductors';

  @override
  String get exercisesMuscleLevatorScapulae => 'Levator scapulae';

  @override
  String get exercisesMuscleAbdominals => 'Abdominals';

  @override
  String get exercisesMuscleAnkleStabilizers => 'Ankle stabilizers';

  @override
  String get exercisesMuscleAnkles => 'Ankles';

  @override
  String get exercisesMuscleBack => 'Back';

  @override
  String get exercisesMuscleBrachialis => 'Brachialis';

  @override
  String get exercisesMuscleChest => 'Chest';

  @override
  String get exercisesMuscleCore => 'Core';

  @override
  String get exercisesMuscleDeltoids => 'Deltoids';

  @override
  String get exercisesMuscleFeet => 'Feet';

  @override
  String get exercisesMuscleGripMuscles => 'Grip';

  @override
  String get exercisesMuscleGroin => 'Groin';

  @override
  String get exercisesMuscleHands => 'Hands';

  @override
  String get exercisesMuscleHipFlexors => 'Hip flexors';

  @override
  String get exercisesMuscleInnerThighs => 'Inner thighs';

  @override
  String get exercisesMuscleLatissimusDorsi => 'Latissimus dorsi';

  @override
  String get exercisesMuscleLowerAbs => 'Lower abs';

  @override
  String get exercisesMuscleLowerBack => 'Lower back';

  @override
  String get exercisesMuscleObliques => 'Obliques';

  @override
  String get exercisesMuscleQuadriceps => 'Quadriceps';

  @override
  String get exercisesMuscleRearDeltoids => 'Rear delts';

  @override
  String get exercisesMuscleRhomboids => 'Rhomboids';

  @override
  String get exercisesMuscleRotatorCuff => 'Rotator cuff';

  @override
  String get exercisesMuscleShins => 'Shins';

  @override
  String get exercisesMuscleShoulders => 'Shoulders';

  @override
  String get exercisesMuscleSoleus => 'Soleus';

  @override
  String get exercisesMuscleSternocleidomastoid => 'Sternocleidomastoid';

  @override
  String get exercisesMuscleTrapezius => 'Trapezius';

  @override
  String get exercisesMuscleUpperChest => 'Upper chest';

  @override
  String get exercisesMuscleWristExtensors => 'Wrist extensors';

  @override
  String get exercisesMuscleWristFlexors => 'Wrist flexors';

  @override
  String get exercisesMuscleWrists => 'Wrists';

  @override
  String get exercisesEquipmentBodyWeight => 'Body weight';

  @override
  String get exercisesEquipmentDumbbell => 'Dumbbell';

  @override
  String get exercisesEquipmentCable => 'Cable';

  @override
  String get exercisesEquipmentBarbell => 'Barbell';

  @override
  String get exercisesEquipmentLeverageMachine => 'Machine';

  @override
  String get exercisesEquipmentBand => 'Band';

  @override
  String get exercisesEquipmentSmithMachine => 'Smith machine';

  @override
  String get exercisesEquipmentKettlebell => 'Kettlebell';

  @override
  String get exercisesEquipmentWeighted => 'Weighted';

  @override
  String get exercisesEquipmentStabilityBall => 'Stability ball';

  @override
  String get exercisesEquipmentEzBarbell => 'EZ bar';

  @override
  String get exercisesEquipmentSledMachine => 'Sled machine';

  @override
  String get exercisesEquipmentAssisted => 'Assisted';

  @override
  String get exercisesEquipmentMedicineBall => 'Medicine ball';

  @override
  String get exercisesEquipmentRope => 'Rope';

  @override
  String get exercisesEquipmentRoller => 'Roller';

  @override
  String get exercisesEquipmentResistanceBand => 'Resistance band';

  @override
  String get exercisesEquipmentBosuBall => 'Bosu ball';

  @override
  String get exercisesEquipmentWheelRoller => 'Ab wheel';

  @override
  String get exercisesEquipmentOlympicBarbell => 'Olympic barbell';

  @override
  String get exercisesEquipmentUpperBodyErgometer => 'Upper body ergometer';

  @override
  String get exercisesEquipmentTrapBar => 'Trap bar';

  @override
  String get exercisesEquipmentTire => 'Tire';

  @override
  String get exercisesEquipmentStepmillMachine => 'Stepmill';

  @override
  String get exercisesEquipmentStationaryBike => 'Stationary bike';

  @override
  String get exercisesEquipmentSkiergMachine => 'SkiErg';

  @override
  String get exercisesEquipmentHammer => 'Hammer';

  @override
  String get exercisesEquipmentEllipticalMachine => 'Elliptical';

  @override
  String get exercisesBodyPartUpperArms => 'Upper arms';

  @override
  String get exercisesBodyPartUpperLegs => 'Upper legs';

  @override
  String get exercisesBodyPartBack => 'Back';

  @override
  String get exercisesBodyPartWaist => 'Waist';

  @override
  String get exercisesBodyPartChest => 'Chest';

  @override
  String get exercisesBodyPartShoulders => 'Shoulders';

  @override
  String get exercisesBodyPartLowerLegs => 'Lower legs';

  @override
  String get exercisesBodyPartLowerArms => 'Lower arms';

  @override
  String get exercisesBodyPartCardio => 'Cardio';

  @override
  String get exercisesBodyPartNeck => 'Neck';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Device language';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';
}
