// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'عزم';

  @override
  String get shellTabWorkout => 'تمرين';

  @override
  String get shellTabHistory => 'السجل';

  @override
  String get shellTabExercises => 'التمارين';

  @override
  String get shellOpenSettings => 'الإعدادات';

  @override
  String get shellComingSoon => 'الشاشة دي لسه بتتبني';

  @override
  String get commonBack => 'رجوع';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSystem => 'لغة الجهاز';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get workoutStart => 'ابدأ تمرين';

  @override
  String get workoutStartHint => 'تمرين فاضي، وضيف التمارين وانت شغال';

  @override
  String get workoutResume => 'كمّل التمرين';

  @override
  String get workoutInProgress => 'تمرين شغال';

  @override
  String get workoutNameMorning => 'تمرين الصبح';

  @override
  String get workoutNameAfternoon => 'تمرين الضهر';

  @override
  String get workoutNameEvening => 'تمرين بالليل';

  @override
  String get workoutNameNight => 'تمرين آخر الليل';

  @override
  String get workoutMinimize => 'صغّر التمرين';

  @override
  String get workoutFinish => 'إنهاء';

  @override
  String get workoutStatDuration => 'المدة';

  @override
  String get workoutStatLifted => 'شِلت';

  @override
  String get workoutStatSets => 'السِتات';

  @override
  String get workoutStatPrs => 'أرقام قياسية';

  @override
  String get workoutColSet => 'سِت';

  @override
  String get workoutColPrevious => 'السابق';

  @override
  String get workoutColReps => 'عدّات';

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
  String get workoutSetTypeWarmupShort => 'إ';

  @override
  String get workoutSetTypeDropShort => 'د';

  @override
  String get workoutSetTypeFailureShort => 'ف';

  @override
  String get workoutSetTypeTitle => 'نوع السِت';

  @override
  String get workoutSetTypeNormal => 'عادي';

  @override
  String get workoutSetTypeWarmup => 'إحماء';

  @override
  String get workoutSetTypeDrop => 'دروب سِت';

  @override
  String get workoutSetTypeFailure => 'للفشل';

  @override
  String get workoutAddSet => 'ضيف سِت';

  @override
  String get workoutAddExercise => 'ضيف تمرين';

  @override
  String get workoutEmpty => 'ضيف أول تمرين عشان تبدأ تسجّل';

  @override
  String get workoutExerciseOptions => 'خيارات التمرين';

  @override
  String get workoutReorder => 'رتّب التمارين';

  @override
  String get workoutRemoveExercise => 'شيل التمرين';

  @override
  String get workoutDone => 'تم';

  @override
  String get workoutCancel => 'إلغاء';

  @override
  String get workoutDeleteSet => 'امسح السِت';

  @override
  String get workoutCompleteSet => 'علّم السِت خلصان';

  @override
  String workoutUnknownExercise(String id) {
    return 'تمرين مش معروف ($id)';
  }

  @override
  String workoutKeypadWeight(String unit) {
    return 'الوزن ($unit)';
  }

  @override
  String get workoutKeypadNext => 'التالي';

  @override
  String get workoutKeypadBackspace => 'امسح رقم';

  @override
  String get workoutKeypadHide => 'اقفل الكيبورد';

  @override
  String get workoutKeypadDecrease => 'نقّص';

  @override
  String get workoutKeypadIncrease => 'زوّد';

  @override
  String get workoutRest => 'راحة';

  @override
  String get workoutRestSkip => 'تخطّي';

  @override
  String get workoutRestLess => 'نقّص 15 ثانية';

  @override
  String get workoutRestMore => 'زوّد 15 ثانية';

  @override
  String get workoutRestNotificationTitle => 'الراحة خلصت 💪';

  @override
  String get workoutRestNotificationBody => 'يلا على السِت اللي بعده';

  @override
  String get workoutRestChannelName => 'مؤقت الراحة';

  @override
  String get workoutRestChannelDescription => 'تنبيه لما وقت الراحة يخلص';

  @override
  String get workoutFinishTitle => 'تنهي التمرين؟';

  @override
  String get workoutFinishBody => 'السِتات اللي مش متعلّم عليها ✓ هتتشال.';

  @override
  String get workoutFinishNothing =>
      'مفيش ولا سِت متعلّم عليها ✓ لسه. تحب تلغي التمرين؟';

  @override
  String get workoutDiscard => 'إلغاء التمرين';

  @override
  String get workoutDiscardTitle => 'تلغي التمرين؟';

  @override
  String get workoutDiscardBody => 'كل اللي سجّلته في التمرين ده هيتمسح.';

  @override
  String get workoutDiscardConfirm => 'امسح';

  @override
  String get workoutSummaryTitle => 'عاش! التمرين خلص';

  @override
  String get workoutSummaryPrs => 'أرقام قياسية جديدة';

  @override
  String get workoutSummaryBestSets => 'أحسن سِت في كل تمرين';

  @override
  String get workoutSummaryNotFound => 'التمرين ده مش موجود';

  @override
  String get workoutPrHeaviest => 'أتقل وزن';

  @override
  String get workoutPr1Rm => 'أعلى 1RM متوقّع';

  @override
  String get workoutPrVolume => 'أعلى حجم في سِت';

  @override
  String workoutCompareCar(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وزن $countText عربية ملاكي 🚗',
      few: 'وزن $countText عربيات ملاكي 🚗',
      two: 'وزن عربيتين ملاكي 🚗',
      one: 'وزن عربية ملاكي 🚗',
    );
    return '$_temp0';
  }

  @override
  String workoutComparePyramid(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وزن $countText حجر من الهرم 🗿',
      few: 'وزن $countText حجارة من الهرم 🗿',
      two: 'وزن حجرين من الهرم 🗿',
      one: 'وزن حجر من الهرم 🗿',
    );
    return '$_temp0';
  }

  @override
  String workoutCompareElephant(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وزن $countText فيل 🐘',
      few: 'وزن $countText فيلة 🐘',
      two: 'وزن فيلين 🐘',
      one: 'وزن فيل 🐘',
    );
    return '$_temp0';
  }

  @override
  String get workoutBarOpen => 'افتح التمرين';

  @override
  String get workoutDebugSeed => 'DEBUG: ضيف تمارين تجريبية';
}
