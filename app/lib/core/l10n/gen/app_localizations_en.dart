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
  String get exercisesFilterMore => 'More';

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
  String get historyLiftedSoFar => 'Lifted so far';

  @override
  String historyCompactThousand(String value) {
    return '${value}K';
  }

  @override
  String historyCompactMillion(String value) {
    return '${value}M';
  }

  @override
  String historyCompactBillion(String value) {
    return '${value}B';
  }

  @override
  String historyWorkoutCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText workouts',
      one: '1 workout',
      zero: 'No workouts',
    );
    return '$_temp0';
  }

  @override
  String historySetCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText sets',
      one: '1 set',
      zero: 'No sets',
    );
    return '$_temp0';
  }

  @override
  String get historyOpenStats => 'Stats';

  @override
  String get historyViewList => 'List';

  @override
  String get historyViewCalendar => 'Calendar';

  @override
  String get historyEmptyTitle => 'No workouts yet';

  @override
  String get historyEmptyBody =>
      'Finish your first workout and it shows up here, with everything you lifted.';

  @override
  String historyDurationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String historyDurationHours(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get historyUnitKg => 'kg';

  @override
  String get historyUnitLb => 'lb';

  @override
  String historyWeightValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String historySetValue(String weight, String reps) {
    return '$weight × $reps';
  }

  @override
  String historyExerciseSets(String count, String name) {
    return '$count × $name';
  }

  @override
  String historyPrBadge(String count) {
    return '🏆 $count';
  }

  @override
  String historyPrCountLabel(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText personal records',
      one: '1 personal record',
    );
    return '$_temp0';
  }

  @override
  String get historyNoData => '—';

  @override
  String historyUnknownExercise(String id) {
    return 'Unknown exercise ($id)';
  }

  @override
  String get historyPrevMonth => 'Previous month';

  @override
  String get historyNextMonth => 'Next month';

  @override
  String get historyDayEmpty => 'No workouts on this day';

  @override
  String get historyPickDay => 'Tap a marked day to see its workouts';

  @override
  String get historyWorkoutOptions => 'Workout options';

  @override
  String get historyRename => 'Rename';

  @override
  String get historyRenameTitle => 'Workout name';

  @override
  String get historySave => 'Save';

  @override
  String get historyCancel => 'Cancel';

  @override
  String get historyDeleteWorkout => 'Delete workout';

  @override
  String get historyDeleteTitle => 'Delete this workout?';

  @override
  String get historyDeleteBody =>
      'All its sets are removed, and your Lifted total and records are recalculated. This can\'t be undone.';

  @override
  String get historyDeleteConfirm => 'Delete';

  @override
  String get historyStatDuration => 'Duration';

  @override
  String get historyStatLifted => 'Lifted';

  @override
  String get historyStatSets => 'Sets';

  @override
  String get historyStatPrs => 'PRs';

  @override
  String get historyStatWorkouts => 'Workouts';

  @override
  String get historyColSet => 'Set';

  @override
  String get historyColPrevious => 'Previous';

  @override
  String get historyColReps => 'Reps';

  @override
  String get historySetTypeTitle => 'Set type';

  @override
  String get historySetTypeNormal => 'Normal';

  @override
  String get historySetTypeWarmup => 'Warm-up';

  @override
  String get historySetTypeDrop => 'Drop set';

  @override
  String get historySetTypeFailure => 'Failure';

  @override
  String get historySetTypeWarmupShort => 'W';

  @override
  String get historySetTypeDropShort => 'D';

  @override
  String get historySetTypeFailureShort => 'F';

  @override
  String get historyAddSet => 'Add set';

  @override
  String get historyAddExercise => 'Add exercise';

  @override
  String get historyExerciseOptions => 'Exercise options';

  @override
  String get historyRemoveExercise => 'Remove exercise';

  @override
  String get historyDeleteSet => 'Delete set';

  @override
  String get historyCompleteSet => 'Mark set done';

  @override
  String historyKeypadWeight(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get historyKeypadNext => 'Next';

  @override
  String get historyDone => 'Done';

  @override
  String get historyKeypadBackspace => 'Backspace';

  @override
  String get historyKeypadHide => 'Hide keypad';

  @override
  String get historyKeypadDecrease => 'Decrease';

  @override
  String get historyKeypadIncrease => 'Increase';

  @override
  String get historyEditHint =>
      'Edits save instantly. Sets without ✓ or reps are removed when you leave.';

  @override
  String get historyNotFound => 'This workout doesn\'t exist';

  @override
  String get historyStatsTitle => 'Stats';

  @override
  String get historyStatsPerWeek => 'Workouts per week';

  @override
  String historyStatsThisWeek(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This week: $countText workouts',
      one: 'This week: 1 workout',
      zero: 'This week: none yet',
    );
    return '$_temp0';
  }

  @override
  String historyStatsAverage(String value) {
    return 'Average $value a week';
  }

  @override
  String get historyStatsRecords => 'Personal records';

  @override
  String get historyStatsRecordsEmpty =>
      'No records yet. Finish a workout with weights and they show up here.';

  @override
  String get historyRecordHeaviest => 'Heaviest';

  @override
  String get historyRecord1Rm => 'Est. 1RM';

  @override
  String get historyRecordVolume => 'Best volume';

  @override
  String historySeeAll(String count) {
    return 'See all history ($count)';
  }

  @override
  String get historyExerciseRecords => 'Your records';

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

  @override
  String get workoutStart => 'Start workout';

  @override
  String get workoutStartHint => 'Empty workout, add exercises as you go';

  @override
  String get workoutResume => 'Resume workout';

  @override
  String get workoutInProgress => 'Workout in progress';

  @override
  String get workoutNameMorning => 'Morning workout';

  @override
  String get workoutNameAfternoon => 'Afternoon workout';

  @override
  String get workoutNameEvening => 'Evening workout';

  @override
  String get workoutNameNight => 'Late-night workout';

  @override
  String get workoutMinimize => 'Minimize workout';

  @override
  String get workoutFinish => 'Finish';

  @override
  String get workoutStatDuration => 'Duration';

  @override
  String get workoutStatLifted => 'Lifted';

  @override
  String get workoutStatSets => 'Sets';

  @override
  String get workoutStatPrs => 'PRs';

  @override
  String get workoutColSet => 'Set';

  @override
  String get workoutColPrevious => 'Previous';

  @override
  String get workoutColReps => 'Reps';

  @override
  String get workoutUnitKg => 'kg';

  @override
  String get workoutUnitLb => 'lb';

  @override
  String get workoutNoData => '—';

  @override
  String workoutSetValue(String weight, String reps) {
    return '$weight × $reps';
  }

  @override
  String workoutWeightUnit(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get workoutSetTypeWarmupShort => 'W';

  @override
  String get workoutSetTypeDropShort => 'D';

  @override
  String get workoutSetTypeFailureShort => 'F';

  @override
  String get workoutSetTypeTitle => 'Set type';

  @override
  String get workoutSetTypeNormal => 'Normal';

  @override
  String get workoutSetTypeWarmup => 'Warm-up';

  @override
  String get workoutSetTypeDrop => 'Drop set';

  @override
  String get workoutSetTypeFailure => 'Failure';

  @override
  String get workoutAddSet => 'Add set';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutEmpty => 'Add your first exercise to start logging';

  @override
  String get workoutExerciseOptions => 'Exercise options';

  @override
  String get workoutReorder => 'Reorder exercises';

  @override
  String get workoutRemoveExercise => 'Remove exercise';

  @override
  String get workoutDone => 'Done';

  @override
  String get workoutCancel => 'Cancel';

  @override
  String get workoutDeleteSet => 'Delete set';

  @override
  String get workoutCompleteSet => 'Mark set complete';

  @override
  String workoutUnknownExercise(String id) {
    return 'Unknown exercise ($id)';
  }

  @override
  String workoutKeypadWeight(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get workoutKeypadNext => 'Next';

  @override
  String get workoutKeypadBackspace => 'Delete digit';

  @override
  String get workoutKeypadHide => 'Close keypad';

  @override
  String get workoutKeypadDecrease => 'Decrease';

  @override
  String get workoutKeypadIncrease => 'Increase';

  @override
  String get workoutRest => 'Rest';

  @override
  String get workoutRestSkip => 'Skip';

  @override
  String get workoutRestLess => '15 seconds less';

  @override
  String get workoutRestMore => '15 seconds more';

  @override
  String get workoutRestNotificationTitle => 'Rest is over 💪';

  @override
  String get workoutRestNotificationBody => 'Time for your next set';

  @override
  String get workoutRestChannelName => 'Rest timer';

  @override
  String get workoutRestChannelDescription =>
      'Alerts you when your rest is over';

  @override
  String get workoutFinishTitle => 'Finish workout?';

  @override
  String get workoutFinishNothing =>
      'No completed sets yet. Discard this workout?';

  @override
  String get workoutDiscard => 'Discard workout';

  @override
  String get workoutDiscardTitle => 'Discard workout?';

  @override
  String get workoutDiscardBody =>
      'Everything logged in this workout will be deleted.';

  @override
  String get workoutDiscardConfirm => 'Discard';

  @override
  String get workoutSummaryTitle => 'Workout complete';

  @override
  String get workoutSummaryPrs => 'New PRs';

  @override
  String get workoutSummaryBestSets => 'Best set per exercise';

  @override
  String get workoutSummaryNotFound => 'This workout doesn\'t exist';

  @override
  String get workoutPrHeaviest => 'Heaviest weight';

  @override
  String get workoutPr1Rm => 'Best est. 1RM';

  @override
  String get workoutPrVolume => 'Best set volume';

  @override
  String workoutCompareCar(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'the weight of $countText cars 🚗',
      one: 'the weight of a car 🚗',
    );
    return '$_temp0';
  }

  @override
  String workoutComparePyramid(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'the weight of $countText pyramid stone blocks 🗿',
      one: 'the weight of a pyramid stone block 🗿',
    );
    return '$_temp0';
  }

  @override
  String workoutCompareElephant(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'the weight of $countText elephants 🐘',
      one: 'the weight of an elephant 🐘',
    );
    return '$_temp0';
  }

  @override
  String get workoutBarOpen => 'Open workout';

  @override
  String get workoutFinishAllDoneBody =>
      'All sets are ticked ✓. Save this workout?';

  @override
  String workoutFinishUncheckedBody(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText sets have no ✓ yet.',
      one: '1 set has no ✓ yet.',
    );
    return '$_temp0';
  }

  @override
  String workoutFinishEmptyNote(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText of them are empty and will be removed.',
      one: '1 of them is empty and will be removed.',
    );
    return '$_temp0';
  }

  @override
  String get workoutFinishMarkAllDone => 'Mark all done';

  @override
  String get workoutFinishRemoveThem => 'Remove them';

  @override
  String get workoutExactAlarmTitle => 'Get the rest alert on time';

  @override
  String get workoutExactAlarmBody =>
      'With the screen off, Android can delay the “rest is over” alert by a few minutes. Allow “Alarms & reminders” for Azm so it rings exactly when your rest ends. You can change this any time in the phone settings.';

  @override
  String get workoutExactAlarmAllow => 'Open settings';

  @override
  String get workoutExactAlarmLater => 'Not now';
}
