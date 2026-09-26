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
  String get workoutFinishBody => 'Sets without a ✓ will be removed.';

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
  String get workoutDebugSeed => 'DEBUG: add sample exercises';
}
