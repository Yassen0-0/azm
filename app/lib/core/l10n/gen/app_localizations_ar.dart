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
  String get exercisesSearchHint => 'ابحث بالعربي أو English';

  @override
  String get exercisesSearchClear => 'مسح البحث';

  @override
  String get exercisesFilterAll => 'الكل';

  @override
  String get exercisesFilterMore => 'المزيد';

  @override
  String get exercisesFilterEquipment => 'الأداة';

  @override
  String get exercisesEquipmentSheetTitle => 'فلتر بالأداة';

  @override
  String get exercisesEquipmentAll => 'كل الأدوات';

  @override
  String exercisesRemoveEquipmentFilter(String equipment) {
    return 'شيل فلتر $equipment';
  }

  @override
  String exercisesResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تمرين',
      many: '$count تمرين',
      few: '$count تمارين',
      two: 'تمرينين',
      one: 'تمرين واحد',
      zero: 'مفيش تمارين',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoResultsTitle => 'مفيش تمرين بالاسم ده';

  @override
  String get exercisesNoResultsBody => 'جرّب اسم تاني، أو شيل الفلاتر.';

  @override
  String get exercisesClearFilters => 'شيل الفلاتر';

  @override
  String get exercisesLibraryEmpty => 'مكتبة التمارين مش جاهزة لسه';

  @override
  String exercisesPrBadge(String weight) {
    return 'رقمك القياسي: $weight';
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
  String get exercisesPickerTitle => 'اختار التمارين';

  @override
  String get exercisesPickerCancel => 'إلغاء';

  @override
  String get exercisesPickerAdd => 'إضافة';

  @override
  String exercisesPickerAddCount(int count) {
    return 'إضافة ($count)';
  }

  @override
  String exercisesPickerSelected(int index) {
    return 'مختار رقم $index';
  }

  @override
  String get exercisesUnknown => 'تمرين غير معروف';

  @override
  String get exercisesDetailTarget => 'العضلة الأساسية';

  @override
  String get exercisesDetailSecondary => 'عضلات مساعدة';

  @override
  String get exercisesDetailEquipment => 'الأداة';

  @override
  String get exercisesDetailBodyPart => 'منطقة الجسم';

  @override
  String get exercisesDetailInstructions => 'طريقة الأداء';

  @override
  String get exercisesDetailInstructionsEnglishOnly =>
      'الشرح بالإنجليزي بس لحد دلوقتي.';

  @override
  String get exercisesDetailAttribution =>
      '© Gym visual — https://gymvisual.com/';

  @override
  String get exercisesDetailRecords => 'أرقامك القياسية';

  @override
  String get exercisesRecordHeaviest => 'أتقل وزن';

  @override
  String get exercisesRecordBest1Rm => 'أقصى 1RM تقديري';

  @override
  String get exercisesRecordBestVolume => 'أحسن حجم لمجموعة';

  @override
  String get exercisesDetailProgress => 'تطورك';

  @override
  String get exercisesChartHeaviest => 'أتقل وزن';

  @override
  String get exercisesChart1Rm => '1RM';

  @override
  String get exercisesChartVolume => 'الحجم';

  @override
  String get exercisesChartEmpty => 'الرسم هيظهر بعد تمرينين على الأقل.';

  @override
  String get exercisesDetailHistory => 'سجلك';

  @override
  String get exercisesHistoryEmpty =>
      'لسه ملعبتش التمرين ده. سجّل أول مجموعة وتاريخك هيظهر هنا.';

  @override
  String get exercisesSetLabelWarmup => 'إ';

  @override
  String get exercisesSetLabelDrop => 'د';

  @override
  String get exercisesSetLabelFailure => 'ف';

  @override
  String get exercisesMuscleAbs => 'بطن';

  @override
  String get exercisesMusclePectorals => 'صدر';

  @override
  String get exercisesMuscleBiceps => 'باي';

  @override
  String get exercisesMuscleGlutes => 'جلوتس';

  @override
  String get exercisesMuscleDelts => 'كتف';

  @override
  String get exercisesMuscleTriceps => 'تراي';

  @override
  String get exercisesMuscleUpperBack => 'ظهر علوي';

  @override
  String get exercisesMuscleLats => 'لاتس';

  @override
  String get exercisesMuscleCalves => 'سمانة';

  @override
  String get exercisesMuscleQuads => 'فخذ أمامي';

  @override
  String get exercisesMuscleForearms => 'ساعد';

  @override
  String get exercisesMuscleCardiovascularSystem => 'كارديو';

  @override
  String get exercisesMuscleHamstrings => 'فخذ خلفي';

  @override
  String get exercisesMuscleSpine => 'فقرات الظهر';

  @override
  String get exercisesMuscleTraps => 'ترابيس';

  @override
  String get exercisesMuscleAdductors => 'فخذ داخلي';

  @override
  String get exercisesMuscleSerratusAnterior => 'المنشارية';

  @override
  String get exercisesMuscleAbductors => 'فخذ خارجي';

  @override
  String get exercisesMuscleLevatorScapulae => 'رافعة اللوح';

  @override
  String get exercisesMuscleAbdominals => 'بطن';

  @override
  String get exercisesMuscleAnkleStabilizers => 'مثبتات الكاحل';

  @override
  String get exercisesMuscleAnkles => 'كاحل';

  @override
  String get exercisesMuscleBack => 'ظهر';

  @override
  String get exercisesMuscleBrachialis => 'العضدية';

  @override
  String get exercisesMuscleChest => 'صدر';

  @override
  String get exercisesMuscleCore => 'عضلات الجذع';

  @override
  String get exercisesMuscleDeltoids => 'كتف';

  @override
  String get exercisesMuscleFeet => 'قدم';

  @override
  String get exercisesMuscleGripMuscles => 'قبضة';

  @override
  String get exercisesMuscleGroin => 'أعلى الفخذ الداخلي';

  @override
  String get exercisesMuscleHands => 'إيد';

  @override
  String get exercisesMuscleHipFlexors => 'قابضات الورك';

  @override
  String get exercisesMuscleInnerThighs => 'فخذ داخلي';

  @override
  String get exercisesMuscleLatissimusDorsi => 'لاتس';

  @override
  String get exercisesMuscleLowerAbs => 'بطن سفلي';

  @override
  String get exercisesMuscleLowerBack => 'أسفل الظهر';

  @override
  String get exercisesMuscleObliques => 'جوانب البطن';

  @override
  String get exercisesMuscleQuadriceps => 'فخذ أمامي';

  @override
  String get exercisesMuscleRearDeltoids => 'كتف خلفي';

  @override
  String get exercisesMuscleRhomboids => 'المعينية';

  @override
  String get exercisesMuscleRotatorCuff => 'الكفة المدورة';

  @override
  String get exercisesMuscleShins => 'قصبة الرجل';

  @override
  String get exercisesMuscleShoulders => 'كتف';

  @override
  String get exercisesMuscleSoleus => 'السمانة العميقة';

  @override
  String get exercisesMuscleSternocleidomastoid => 'عضلة الرقبة';

  @override
  String get exercisesMuscleTrapezius => 'ترابيس';

  @override
  String get exercisesMuscleUpperChest => 'صدر علوي';

  @override
  String get exercisesMuscleWristExtensors => 'باسطات الرسغ';

  @override
  String get exercisesMuscleWristFlexors => 'قابضات الرسغ';

  @override
  String get exercisesMuscleWrists => 'رسغ';

  @override
  String get exercisesEquipmentBodyWeight => 'وزن الجسم';

  @override
  String get exercisesEquipmentDumbbell => 'دمبل';

  @override
  String get exercisesEquipmentCable => 'كابل';

  @override
  String get exercisesEquipmentBarbell => 'بار';

  @override
  String get exercisesEquipmentLeverageMachine => 'جهاز';

  @override
  String get exercisesEquipmentBand => 'أستك';

  @override
  String get exercisesEquipmentSmithMachine => 'سميث';

  @override
  String get exercisesEquipmentKettlebell => 'كيتل بل';

  @override
  String get exercisesEquipmentWeighted => 'بوزن إضافي';

  @override
  String get exercisesEquipmentStabilityBall => 'كورة توازن';

  @override
  String get exercisesEquipmentEzBarbell => 'بار زد';

  @override
  String get exercisesEquipmentSledMachine => 'جهاز سليد';

  @override
  String get exercisesEquipmentAssisted => 'بمساعدة';

  @override
  String get exercisesEquipmentMedicineBall => 'كورة طبية';

  @override
  String get exercisesEquipmentRope => 'حبل';

  @override
  String get exercisesEquipmentRoller => 'رولر';

  @override
  String get exercisesEquipmentResistanceBand => 'أستك مقاومة';

  @override
  String get exercisesEquipmentBosuBall => 'بوسو بول';

  @override
  String get exercisesEquipmentWheelRoller => 'عجلة بطن';

  @override
  String get exercisesEquipmentOlympicBarbell => 'بار أوليمبي';

  @override
  String get exercisesEquipmentUpperBodyErgometer => 'عجلة إيد';

  @override
  String get exercisesEquipmentTrapBar => 'تراب بار';

  @override
  String get exercisesEquipmentTire => 'كاوتش';

  @override
  String get exercisesEquipmentStepmillMachine => 'جهاز سلالم';

  @override
  String get exercisesEquipmentStationaryBike => 'عجلة ثابتة';

  @override
  String get exercisesEquipmentSkiergMachine => 'جهاز سكي';

  @override
  String get exercisesEquipmentHammer => 'مرزبة';

  @override
  String get exercisesEquipmentEllipticalMachine => 'أوربتراك';

  @override
  String get exercisesBodyPartUpperArms => 'دراع';

  @override
  String get exercisesBodyPartUpperLegs => 'فخذ';

  @override
  String get exercisesBodyPartBack => 'ظهر';

  @override
  String get exercisesBodyPartWaist => 'بطن ووسط';

  @override
  String get exercisesBodyPartChest => 'صدر';

  @override
  String get exercisesBodyPartShoulders => 'أكتاف';

  @override
  String get exercisesBodyPartLowerLegs => 'سمانة';

  @override
  String get exercisesBodyPartLowerArms => 'ساعد';

  @override
  String get exercisesBodyPartCardio => 'كارديو';

  @override
  String get exercisesBodyPartNeck => 'رقبة';

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
}
