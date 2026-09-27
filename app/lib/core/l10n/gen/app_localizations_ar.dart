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
  String get exercisesSetLabelWarmup => 'ح';

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
  String onboardingStep(String step, String total) {
    return 'خطوة $step من $total';
  }

  @override
  String get onboardingWelcome => 'أهلاً بيك في عزم';

  @override
  String get onboardingUnitTitle => 'بتشيل بالكيلو ولا بالباوند؟';

  @override
  String get onboardingUnitBody => 'تقدر تغيّرها بعدين من الإعدادات.';

  @override
  String get onboardingUnitKg => 'كيلو';

  @override
  String get onboardingUnitLb => 'باوند';

  @override
  String get onboardingUnitKgExample => 'مثلاً بنش 60 kg';

  @override
  String get onboardingUnitLbExample => 'مثلاً بنش 135 lb';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingProgramTitle => 'تحب تبدأ ببرنامج جاهز؟';

  @override
  String get onboardingProgramBody =>
      'أيامه هتتضاف لروتيناتك وتقدر تعدّل فيها براحتك.';

  @override
  String get onboardingStartWithProgram => 'ضيف البرنامج وابدأ';

  @override
  String get onboardingSkip => 'تخطّى، وابدأ من غير برنامج';

  @override
  String get routinesMyRoutines => 'روتيناتي';

  @override
  String get routinesNew => 'روتين جديد';

  @override
  String get routinesEmptyTitle => 'لسه معندكش روتين';

  @override
  String get routinesEmptyBody =>
      'اعمل الروتين مرة واحدة وابدأه بضغطة واحدة. أو خد برنامج جاهز.';

  @override
  String routinesExerciseCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText تمرين',
      few: '$countText تمارين',
      two: 'تمرينين',
      one: 'تمرين واحد',
      zero: 'مفيش تمارين',
    );
    return '$_temp0';
  }

  @override
  String routinesStart(String name) {
    return 'ابدأ $name';
  }

  @override
  String get routinesReadyPrograms => 'برامج جاهزة';

  @override
  String get routinesReadyProgramsHint => 'خد برنامج مجرّب وعدّل فيه براحتك';

  @override
  String get routinesUntitled => 'روتين من غير اسم';

  @override
  String get routinesEditTitle => 'تعديل الروتين';

  @override
  String get routinesNameHint => 'اسم الروتين';

  @override
  String get routinesNotesHint => 'ملاحظات (اختياري)';

  @override
  String get routinesAddExercises => 'ضيف تمارين';

  @override
  String get routinesEditorEmpty =>
      'ضيف تمارين الروتين، وحدّد السِتات المطلوبة لكل تمرين.';

  @override
  String get routinesColSet => 'سِت';

  @override
  String routinesColWeight(String unit) {
    return '$unit';
  }

  @override
  String get routinesColReps => 'عدّات';

  @override
  String get routinesUnitKg => 'kg';

  @override
  String get routinesUnitLb => 'lb';

  @override
  String get routinesNoTarget => '—';

  @override
  String get routinesAddSet => 'ضيف سِت';

  @override
  String get routinesDeleteSet => 'امسح السِت';

  @override
  String get routinesSetTypeTitle => 'نوع السِت';

  @override
  String routinesRestValue(String time) {
    return 'راحة $time';
  }

  @override
  String routinesRestDefault(String time) {
    return 'راحة $time (الافتراضي)';
  }

  @override
  String get routinesRestTitle => 'وقت الراحة';

  @override
  String routinesRestUseDefault(String time) {
    return 'الافتراضي من الإعدادات ($time)';
  }

  @override
  String get routinesExerciseOptions => 'اختيارات التمرين';

  @override
  String get routinesReorder => 'رتّب التمارين';

  @override
  String get routinesRemoveExercise => 'شيل التمرين';

  @override
  String get routinesRemoveExerciseTitle => 'تشيل التمرين ده؟';

  @override
  String get routinesRemoveExerciseBody => 'السِتات بتاعته هتتشال من الروتين.';

  @override
  String get routinesRemove => 'شيل';

  @override
  String get routinesDelete => 'امسح الروتين';

  @override
  String get routinesDeleteTitle => 'تمسح الروتين ده؟';

  @override
  String get routinesDeleteBody => 'التمارين اللي عملتها بيه هتفضل في السجل.';

  @override
  String get routinesDeleteConfirm => 'امسح';

  @override
  String get routinesCancel => 'إلغاء';

  @override
  String get routinesDone => 'تم';

  @override
  String get routinesStartWorkout => 'ابدأ التمرين';

  @override
  String routinesKeypadWeight(String unit) {
    return 'الوزن المطلوب ($unit)';
  }

  @override
  String get routinesKeypadReps => 'العدّات المطلوبة';

  @override
  String get routinesKeypadNext => 'التالي';

  @override
  String get routinesKeypadDone => 'تم';

  @override
  String get routinesKeypadBackspace => 'امسح رقم';

  @override
  String get routinesKeypadHide => 'اقفل الكيبورد';

  @override
  String get routinesKeypadDecrease => 'نقّص';

  @override
  String get routinesKeypadIncrease => 'زوّد';

  @override
  String routinesProgramDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText يوم في الأسبوع',
      few: '$countText أيام في الأسبوع',
      two: 'يومين في الأسبوع',
      one: 'يوم واحد في الأسبوع',
    );
    return '$_temp0';
  }

  @override
  String routinesProgramRoutineCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText روتين',
      few: '$countText روتينات',
      two: 'روتينين',
      one: 'روتين واحد',
    );
    return '$_temp0';
  }

  @override
  String get routinesLevelBeginner => 'مبتدئ';

  @override
  String get routinesLevelIntermediate => 'متوسط';

  @override
  String get routinesProgramAdd => 'ضيفه لروتيناتي';

  @override
  String routinesProgramAdded(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اتضاف $countText روتين لروتيناتك',
      few: 'اتضاف $countText روتينات لروتيناتك',
      two: 'اتضاف روتينين لروتيناتك',
      one: 'اتضاف روتين واحد لروتيناتك',
    );
    return '$_temp0';
  }

  @override
  String routinesSetsReps(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get routinesProgramMissing => 'البرنامج ده مش موجود.';

  @override
  String get routinesListSeparator => '، ';

  @override
  String get routinesResumed => 'فيه تمرين شغال، ففتحناهولك.';

  @override
  String routinesUnknownExercise(String id) {
    return 'تمرين مش معروف ($id)';
  }

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
  String get workoutSetTypeWarmupShort => 'ح';

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
  String get workoutFinishAllDoneBody =>
      'كل السِتات متعلّم عليها ✓. نحفظ التمرين؟';

  @override
  String workoutFinishUncheckedBody(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فيه $countText سِت من غير ✓.',
      few: 'فيه $countText سِتات من غير ✓.',
      two: 'فيه سِتّين من غير ✓.',
      one: 'فيه سِت واحد من غير ✓.',
    );
    return '$_temp0';
  }

  @override
  String workoutFinishEmptyNote(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منهم $countText سِت فاضي هيتشالوا.',
      few: 'منهم $countText سِتات فاضية هتتشال.',
      two: 'منهم سِتّين فاضيين هيتشالوا.',
      one: 'منهم سِت فاضي هيتشال.',
    );
    return '$_temp0';
  }

  @override
  String get workoutFinishMarkAllDone => 'علّم عليهم كلهم ✓';

  @override
  String get workoutFinishRemoveThem => 'شيلهم';

  @override
  String get workoutExactAlarmTitle => 'خلّي تنبيه الراحة ييجي في معاده';

  @override
  String get workoutExactAlarmBody =>
      'والشاشة مقفولة، أندرويد ممكن يأخّر تنبيه «الراحة خلصت» كام دقيقة. اسمح لعزم بـ«المنبّهات والتذكيرات» عشان يرن بالظبط لما الراحة تخلص. تقدر تغيّر ده في أي وقت من إعدادات الموبايل.';

  @override
  String get workoutExactAlarmAllow => 'افتح الإعدادات';

  @override
  String get workoutExactAlarmLater => 'مش دلوقتي';
}
