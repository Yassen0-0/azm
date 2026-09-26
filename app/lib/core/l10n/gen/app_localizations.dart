import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown in the UI (launcher name is set natively).
  ///
  /// In ar, this message translates to:
  /// **'عزم'**
  String get appName;

  /// Bottom tab + screen title: workout home.
  ///
  /// In ar, this message translates to:
  /// **'تمرين'**
  String get shellTabWorkout;

  /// Bottom tab + screen title: workout history.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get shellTabHistory;

  /// Bottom tab + screen title: exercise library.
  ///
  /// In ar, this message translates to:
  /// **'التمارين'**
  String get shellTabExercises;

  /// Tooltip / semantics label of the settings icon in the header.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get shellOpenSettings;

  /// Placeholder body on screens not built yet.
  ///
  /// In ar, this message translates to:
  /// **'الشاشة دي لسه بتتبني'**
  String get shellComingSoon;

  /// Semantics label for a back button.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get commonBack;

  /// Hint in the exercise search box (Arabic, slang or English all work).
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالعربي أو English'**
  String get exercisesSearchHint;

  /// Accessibility label of the clear (x) button in the search box.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get exercisesSearchClear;

  /// First muscle chip: no muscle filter.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get exercisesFilterAll;

  /// Last muscle chip: shows the less common muscles inline.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get exercisesFilterMore;

  /// Button that opens the equipment filter sheet (no equipment chosen).
  ///
  /// In ar, this message translates to:
  /// **'الأداة'**
  String get exercisesFilterEquipment;

  /// Title of the equipment filter bottom sheet.
  ///
  /// In ar, this message translates to:
  /// **'فلتر بالأداة'**
  String get exercisesEquipmentSheetTitle;

  /// Equipment sheet option: no equipment filter.
  ///
  /// In ar, this message translates to:
  /// **'كل الأدوات'**
  String get exercisesEquipmentAll;

  /// Accessibility label of the active equipment pill; tapping it removes the filter.
  ///
  /// In ar, this message translates to:
  /// **'شيل فلتر {equipment}'**
  String exercisesRemoveEquipmentFilter(String equipment);

  /// Number of exercises in the list under the filters.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش تمارين} =1{تمرين واحد} =2{تمرينين} few{{count} تمارين} many{{count} تمرين} other{{count} تمرين}}'**
  String exercisesResultCount(int count);

  /// Empty state title when the search/filters match nothing.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تمرين بالاسم ده'**
  String get exercisesNoResultsTitle;

  /// Empty state hint when the search/filters match nothing.
  ///
  /// In ar, this message translates to:
  /// **'جرّب اسم تاني، أو شيل الفلاتر.'**
  String get exercisesNoResultsBody;

  /// Button in the no-results state: resets search text, muscle and equipment.
  ///
  /// In ar, this message translates to:
  /// **'شيل الفلاتر'**
  String get exercisesClearFilters;

  /// Empty state when the catalog could not be loaded (should not happen).
  ///
  /// In ar, this message translates to:
  /// **'مكتبة التمارين مش جاهزة لسه'**
  String get exercisesLibraryEmpty;

  /// Accessibility label of the 🏆 badge on an exercise row; weight includes the unit.
  ///
  /// In ar, this message translates to:
  /// **'رقمك القياسي: {weight}'**
  String exercisesPrBadge(String weight);

  /// Weight unit kilograms (Latin "kg" in both languages, as in the brief).
  ///
  /// In ar, this message translates to:
  /// **'kg'**
  String get exercisesUnitKg;

  /// Weight unit pounds (Latin "lb" in both languages).
  ///
  /// In ar, this message translates to:
  /// **'lb'**
  String get exercisesUnitLb;

  /// A weight with its unit, e.g. "60 kg".
  ///
  /// In ar, this message translates to:
  /// **'{value} {unit}'**
  String exercisesWeightValue(String value, String unit);

  /// One set: weight with unit × reps, e.g. "60 kg × 8".
  ///
  /// In ar, this message translates to:
  /// **'{weight} × {reps}'**
  String exercisesSetValue(String weight, String reps);

  /// Title of the multi-select exercise picker.
  ///
  /// In ar, this message translates to:
  /// **'اختار التمارين'**
  String get exercisesPickerTitle;

  /// Accessibility label of the close button of the picker (returns nothing).
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get exercisesPickerCancel;

  /// Picker confirm button when nothing is selected (disabled).
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get exercisesPickerAdd;

  /// Picker confirm button with the number of selected exercises.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ({count})'**
  String exercisesPickerAddCount(int count);

  /// Accessibility: this exercise is selected at position {index}.
  ///
  /// In ar, this message translates to:
  /// **'مختار رقم {index}'**
  String exercisesPickerSelected(int index);

  /// Shown when an exercise id is not in the catalog anymore.
  ///
  /// In ar, this message translates to:
  /// **'تمرين غير معروف'**
  String get exercisesUnknown;

  /// Detail: label of the primary muscle.
  ///
  /// In ar, this message translates to:
  /// **'العضلة الأساسية'**
  String get exercisesDetailTarget;

  /// Detail: label of the secondary muscles.
  ///
  /// In ar, this message translates to:
  /// **'عضلات مساعدة'**
  String get exercisesDetailSecondary;

  /// Detail: label of the equipment.
  ///
  /// In ar, this message translates to:
  /// **'الأداة'**
  String get exercisesDetailEquipment;

  /// Detail: label of the body part.
  ///
  /// In ar, this message translates to:
  /// **'منطقة الجسم'**
  String get exercisesDetailBodyPart;

  /// Detail: section title of the step-by-step instructions.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الأداء'**
  String get exercisesDetailInstructions;

  /// Detail: note shown in Arabic when an exercise has no Arabic instructions yet.
  ///
  /// In ar, this message translates to:
  /// **'الشرح بالإنجليزي بس لحد دلوقتي.'**
  String get exercisesDetailInstructionsEnglishOnly;

  /// Media attribution line, required whenever exercise media is shown (docs/LICENSES.md). Keep verbatim.
  ///
  /// In ar, this message translates to:
  /// **'© Gym visual — https://gymvisual.com/'**
  String get exercisesDetailAttribution;

  /// Detail: section title of the PR stats.
  ///
  /// In ar, this message translates to:
  /// **'أرقامك القياسية'**
  String get exercisesDetailRecords;

  /// PR type: heaviest weight lifted.
  ///
  /// In ar, this message translates to:
  /// **'أتقل وزن'**
  String get exercisesRecordHeaviest;

  /// PR type: best estimated one-rep max (Epley).
  ///
  /// In ar, this message translates to:
  /// **'أقصى 1RM تقديري'**
  String get exercisesRecordBest1Rm;

  /// PR type: best single-set volume (weight × reps).
  ///
  /// In ar, this message translates to:
  /// **'أحسن حجم لمجموعة'**
  String get exercisesRecordBestVolume;

  /// Detail: section title of the progress chart.
  ///
  /// In ar, this message translates to:
  /// **'تطورك'**
  String get exercisesDetailProgress;

  /// Chart metric: heaviest weight per workout.
  ///
  /// In ar, this message translates to:
  /// **'أتقل وزن'**
  String get exercisesChartHeaviest;

  /// Chart metric: best estimated 1RM per workout.
  ///
  /// In ar, this message translates to:
  /// **'1RM'**
  String get exercisesChart1Rm;

  /// Chart metric: total volume (weight × reps) per workout.
  ///
  /// In ar, this message translates to:
  /// **'الحجم'**
  String get exercisesChartVolume;

  /// Detail: empty state of the progress chart (fewer than 2 workouts).
  ///
  /// In ar, this message translates to:
  /// **'الرسم هيظهر بعد تمرينين على الأقل.'**
  String get exercisesChartEmpty;

  /// Detail: section title of the recent workouts with this exercise.
  ///
  /// In ar, this message translates to:
  /// **'سجلك'**
  String get exercisesDetailHistory;

  /// Detail: empty state when there is no history for the exercise.
  ///
  /// In ar, this message translates to:
  /// **'لسه ملعبتش التمرين ده. سجّل أول مجموعة وتاريخك هيظهر هنا.'**
  String get exercisesHistoryEmpty;

  /// Short label of a warm-up set in the history list: ح (from إحماء; owner decision 2026-09-26, same as the workout set label).
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get exercisesSetLabelWarmup;

  /// Short label of a drop set in the history list.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get exercisesSetLabelDrop;

  /// Short label of a failure set in the history list.
  ///
  /// In ar, this message translates to:
  /// **'ف'**
  String get exercisesSetLabelFailure;

  /// Dataset muscle "abs" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بطن'**
  String get exercisesMuscleAbs;

  /// Dataset muscle "pectorals" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'صدر'**
  String get exercisesMusclePectorals;

  /// Dataset muscle "biceps" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'باي'**
  String get exercisesMuscleBiceps;

  /// Dataset muscle "glutes" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'جلوتس'**
  String get exercisesMuscleGlutes;

  /// Dataset muscle "delts" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كتف'**
  String get exercisesMuscleDelts;

  /// Dataset muscle "triceps" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'تراي'**
  String get exercisesMuscleTriceps;

  /// Dataset muscle "upper back" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ظهر علوي'**
  String get exercisesMuscleUpperBack;

  /// Dataset muscle "lats" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'لاتس'**
  String get exercisesMuscleLats;

  /// Dataset muscle "calves" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'سمانة'**
  String get exercisesMuscleCalves;

  /// Dataset muscle "quads" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ أمامي'**
  String get exercisesMuscleQuads;

  /// Dataset muscle "forearms" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ساعد'**
  String get exercisesMuscleForearms;

  /// Dataset muscle "cardiovascular system" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كارديو'**
  String get exercisesMuscleCardiovascularSystem;

  /// Dataset muscle "hamstrings" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ خلفي'**
  String get exercisesMuscleHamstrings;

  /// Dataset muscle "spine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فقرات الظهر'**
  String get exercisesMuscleSpine;

  /// Dataset muscle "traps" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ترابيس'**
  String get exercisesMuscleTraps;

  /// Dataset muscle "adductors" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ داخلي'**
  String get exercisesMuscleAdductors;

  /// Dataset muscle "serratus anterior" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'المنشارية'**
  String get exercisesMuscleSerratusAnterior;

  /// Dataset muscle "abductors" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ خارجي'**
  String get exercisesMuscleAbductors;

  /// Dataset muscle "levator scapulae" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'رافعة اللوح'**
  String get exercisesMuscleLevatorScapulae;

  /// Dataset muscle "abdominals" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بطن'**
  String get exercisesMuscleAbdominals;

  /// Dataset muscle "ankle stabilizers" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'مثبتات الكاحل'**
  String get exercisesMuscleAnkleStabilizers;

  /// Dataset muscle "ankles" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كاحل'**
  String get exercisesMuscleAnkles;

  /// Dataset muscle "back" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ظهر'**
  String get exercisesMuscleBack;

  /// Dataset muscle "brachialis" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'العضدية'**
  String get exercisesMuscleBrachialis;

  /// Dataset muscle "chest" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'صدر'**
  String get exercisesMuscleChest;

  /// Dataset muscle "core" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'عضلات الجذع'**
  String get exercisesMuscleCore;

  /// Dataset muscle "deltoids" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كتف'**
  String get exercisesMuscleDeltoids;

  /// Dataset muscle "feet" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'قدم'**
  String get exercisesMuscleFeet;

  /// Dataset muscle "grip muscles" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'قبضة'**
  String get exercisesMuscleGripMuscles;

  /// Dataset muscle "groin" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'أعلى الفخذ الداخلي'**
  String get exercisesMuscleGroin;

  /// Dataset muscle "hands" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'إيد'**
  String get exercisesMuscleHands;

  /// Dataset muscle "hip flexors" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'قابضات الورك'**
  String get exercisesMuscleHipFlexors;

  /// Dataset muscle "inner thighs" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ داخلي'**
  String get exercisesMuscleInnerThighs;

  /// Dataset muscle "latissimus dorsi" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'لاتس'**
  String get exercisesMuscleLatissimusDorsi;

  /// Dataset muscle "lower abs" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بطن سفلي'**
  String get exercisesMuscleLowerAbs;

  /// Dataset muscle "lower back" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'أسفل الظهر'**
  String get exercisesMuscleLowerBack;

  /// Dataset muscle "obliques" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'جوانب البطن'**
  String get exercisesMuscleObliques;

  /// Dataset muscle "quadriceps" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ أمامي'**
  String get exercisesMuscleQuadriceps;

  /// Dataset muscle "rear deltoids" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كتف خلفي'**
  String get exercisesMuscleRearDeltoids;

  /// Dataset muscle "rhomboids" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'المعينية'**
  String get exercisesMuscleRhomboids;

  /// Dataset muscle "rotator cuff" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'الكفة المدورة'**
  String get exercisesMuscleRotatorCuff;

  /// Dataset muscle "shins" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'قصبة الرجل'**
  String get exercisesMuscleShins;

  /// Dataset muscle "shoulders" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كتف'**
  String get exercisesMuscleShoulders;

  /// Dataset muscle "soleus" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'السمانة العميقة'**
  String get exercisesMuscleSoleus;

  /// Dataset muscle "sternocleidomastoid" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'عضلة الرقبة'**
  String get exercisesMuscleSternocleidomastoid;

  /// Dataset muscle "trapezius" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ترابيس'**
  String get exercisesMuscleTrapezius;

  /// Dataset muscle "upper chest" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'صدر علوي'**
  String get exercisesMuscleUpperChest;

  /// Dataset muscle "wrist extensors" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'باسطات الرسغ'**
  String get exercisesMuscleWristExtensors;

  /// Dataset muscle "wrist flexors" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'قابضات الرسغ'**
  String get exercisesMuscleWristFlexors;

  /// Dataset muscle "wrists" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'رسغ'**
  String get exercisesMuscleWrists;

  /// Dataset equipment "body weight" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'وزن الجسم'**
  String get exercisesEquipmentBodyWeight;

  /// Dataset equipment "dumbbell" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'دمبل'**
  String get exercisesEquipmentDumbbell;

  /// Dataset equipment "cable" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كابل'**
  String get exercisesEquipmentCable;

  /// Dataset equipment "barbell" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بار'**
  String get exercisesEquipmentBarbell;

  /// Dataset equipment "leverage machine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'جهاز'**
  String get exercisesEquipmentLeverageMachine;

  /// Dataset equipment "band" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'أستك'**
  String get exercisesEquipmentBand;

  /// Dataset equipment "smith machine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'سميث'**
  String get exercisesEquipmentSmithMachine;

  /// Dataset equipment "kettlebell" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كيتل بل'**
  String get exercisesEquipmentKettlebell;

  /// Dataset equipment "weighted" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بوزن إضافي'**
  String get exercisesEquipmentWeighted;

  /// Dataset equipment "stability ball" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كورة توازن'**
  String get exercisesEquipmentStabilityBall;

  /// Dataset equipment "ez barbell" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بار زد'**
  String get exercisesEquipmentEzBarbell;

  /// Dataset equipment "sled machine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'جهاز سليد'**
  String get exercisesEquipmentSledMachine;

  /// Dataset equipment "assisted" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بمساعدة'**
  String get exercisesEquipmentAssisted;

  /// Dataset equipment "medicine ball" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كورة طبية'**
  String get exercisesEquipmentMedicineBall;

  /// Dataset equipment "rope" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'حبل'**
  String get exercisesEquipmentRope;

  /// Dataset equipment "roller" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'رولر'**
  String get exercisesEquipmentRoller;

  /// Dataset equipment "resistance band" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'أستك مقاومة'**
  String get exercisesEquipmentResistanceBand;

  /// Dataset equipment "bosu ball" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بوسو بول'**
  String get exercisesEquipmentBosuBall;

  /// Dataset equipment "wheel roller" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'عجلة بطن'**
  String get exercisesEquipmentWheelRoller;

  /// Dataset equipment "olympic barbell" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بار أوليمبي'**
  String get exercisesEquipmentOlympicBarbell;

  /// Dataset equipment "upper body ergometer" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'عجلة إيد'**
  String get exercisesEquipmentUpperBodyErgometer;

  /// Dataset equipment "trap bar" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'تراب بار'**
  String get exercisesEquipmentTrapBar;

  /// Dataset equipment "tire" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كاوتش'**
  String get exercisesEquipmentTire;

  /// Dataset equipment "stepmill machine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'جهاز سلالم'**
  String get exercisesEquipmentStepmillMachine;

  /// Dataset equipment "stationary bike" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'عجلة ثابتة'**
  String get exercisesEquipmentStationaryBike;

  /// Dataset equipment "skierg machine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'جهاز سكي'**
  String get exercisesEquipmentSkiergMachine;

  /// Dataset equipment "hammer" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'مرزبة'**
  String get exercisesEquipmentHammer;

  /// Dataset equipment "elliptical machine" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'أوربتراك'**
  String get exercisesEquipmentEllipticalMachine;

  /// Dataset body part "upper arms" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'دراع'**
  String get exercisesBodyPartUpperArms;

  /// Dataset body part "upper legs" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'فخذ'**
  String get exercisesBodyPartUpperLegs;

  /// Dataset body part "back" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ظهر'**
  String get exercisesBodyPartBack;

  /// Dataset body part "waist" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'بطن ووسط'**
  String get exercisesBodyPartWaist;

  /// Dataset body part "chest" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'صدر'**
  String get exercisesBodyPartChest;

  /// Dataset body part "shoulders" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'أكتاف'**
  String get exercisesBodyPartShoulders;

  /// Dataset body part "lower legs" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'سمانة'**
  String get exercisesBodyPartLowerLegs;

  /// Dataset body part "lower arms" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'ساعد'**
  String get exercisesBodyPartLowerArms;

  /// Dataset body part "cardio" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'كارديو'**
  String get exercisesBodyPartCardio;

  /// Dataset body part "neck" (localized label, owner-reviewed 2026-09-26).
  ///
  /// In ar, this message translates to:
  /// **'رقبة'**
  String get exercisesBodyPartNeck;

  /// Settings screen title.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// Settings group: app language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// Language option: follow the device language.
  ///
  /// In ar, this message translates to:
  /// **'لغة الجهاز'**
  String get settingsLanguageSystem;

  /// Language option: Arabic (always written in Arabic).
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// Language option: English (always written in English).
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Settings group: light/dark theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsTheme;

  /// Theme option: dark (default).
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get settingsThemeDark;

  /// Theme option: light.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settingsThemeLight;

  /// Big primary button on the Workout tab: starts an empty workout.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ تمرين'**
  String get workoutStart;

  /// Subtitle under the start button.
  ///
  /// In ar, this message translates to:
  /// **'تمرين فاضي، وضيف التمارين وانت شغال'**
  String get workoutStartHint;

  /// Button on the Workout tab when a workout is already running.
  ///
  /// In ar, this message translates to:
  /// **'كمّل التمرين'**
  String get workoutResume;

  /// Label above the running workout card on the Workout tab.
  ///
  /// In ar, this message translates to:
  /// **'تمرين شغال'**
  String get workoutInProgress;

  /// Default name of a workout started 05:00-11:59.
  ///
  /// In ar, this message translates to:
  /// **'تمرين الصبح'**
  String get workoutNameMorning;

  /// Default name of a workout started 12:00-16:59.
  ///
  /// In ar, this message translates to:
  /// **'تمرين الضهر'**
  String get workoutNameAfternoon;

  /// Default name of a workout started 17:00-21:59.
  ///
  /// In ar, this message translates to:
  /// **'تمرين بالليل'**
  String get workoutNameEvening;

  /// Default name of a workout started 22:00-04:59.
  ///
  /// In ar, this message translates to:
  /// **'تمرين آخر الليل'**
  String get workoutNameNight;

  /// Semantics label of the chevron that minimizes the active workout into the bar.
  ///
  /// In ar, this message translates to:
  /// **'صغّر التمرين'**
  String get workoutMinimize;

  /// Header button that finishes the active workout.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get workoutFinish;

  /// Header stat label: elapsed workout time.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get workoutStatDuration;

  /// Header/summary stat label: total weight x reps of completed sets (Egyptian: shilt = you lifted).
  ///
  /// In ar, this message translates to:
  /// **'شِلت'**
  String get workoutStatLifted;

  /// Header stat label: number of completed sets.
  ///
  /// In ar, this message translates to:
  /// **'السِتات'**
  String get workoutStatSets;

  /// Summary stat label: number of personal records.
  ///
  /// In ar, this message translates to:
  /// **'أرقام قياسية'**
  String get workoutStatPrs;

  /// Set-table column header: set number / type.
  ///
  /// In ar, this message translates to:
  /// **'سِت'**
  String get workoutColSet;

  /// Set-table column header: same set in the last workout.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get workoutColPrevious;

  /// Set-table column header: repetitions.
  ///
  /// In ar, this message translates to:
  /// **'عدّات'**
  String get workoutColReps;

  /// Weight unit label for kilograms (kept Latin in Arabic, as said in gyms).
  ///
  /// In ar, this message translates to:
  /// **'kg'**
  String get workoutUnitKg;

  /// Weight unit label for pounds.
  ///
  /// In ar, this message translates to:
  /// **'lb'**
  String get workoutUnitLb;

  /// Shown where there is no data yet (never 0).
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get workoutNoData;

  /// A set as weight x reps, e.g. 60 × 8.
  ///
  /// In ar, this message translates to:
  /// **'{weight} × {reps}'**
  String workoutSetValue(String weight, String reps);

  /// A weight with its unit, e.g. 62.5 kg.
  ///
  /// In ar, this message translates to:
  /// **'{value} {unit}'**
  String workoutWeightUnit(String value, String unit);

  /// One-letter label of a warm-up set: ح (from إحماء; owner decision 2026-09-26 — إ looked like '!'). Shown in amber.
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get workoutSetTypeWarmupShort;

  /// One-letter label of a drop set.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get workoutSetTypeDropShort;

  /// One-letter label of a set to failure.
  ///
  /// In ar, this message translates to:
  /// **'ف'**
  String get workoutSetTypeFailureShort;

  /// Title of the set-type menu (tap the set label).
  ///
  /// In ar, this message translates to:
  /// **'نوع السِت'**
  String get workoutSetTypeTitle;

  /// Set type: normal working set.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get workoutSetTypeNormal;

  /// Set type: warm-up.
  ///
  /// In ar, this message translates to:
  /// **'إحماء'**
  String get workoutSetTypeWarmup;

  /// Set type: drop set.
  ///
  /// In ar, this message translates to:
  /// **'دروب سِت'**
  String get workoutSetTypeDrop;

  /// Set type: to failure (intentional, never shown as an error).
  ///
  /// In ar, this message translates to:
  /// **'للفشل'**
  String get workoutSetTypeFailure;

  /// Button under an exercise's sets.
  ///
  /// In ar, this message translates to:
  /// **'ضيف سِت'**
  String get workoutAddSet;

  /// Button that opens the exercise picker.
  ///
  /// In ar, this message translates to:
  /// **'ضيف تمرين'**
  String get workoutAddExercise;

  /// Empty state of the active workout.
  ///
  /// In ar, this message translates to:
  /// **'ضيف أول تمرين عشان تبدأ تسجّل'**
  String get workoutEmpty;

  /// Semantics label of the exercise menu button.
  ///
  /// In ar, this message translates to:
  /// **'خيارات التمرين'**
  String get workoutExerciseOptions;

  /// Menu item + sheet title: reorder exercises in the workout.
  ///
  /// In ar, this message translates to:
  /// **'رتّب التمارين'**
  String get workoutReorder;

  /// Menu item: remove an exercise and its sets from the workout.
  ///
  /// In ar, this message translates to:
  /// **'شيل التمرين'**
  String get workoutRemoveExercise;

  /// Generic done/close button.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get workoutDone;

  /// Cancel button in dialogs.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get workoutCancel;

  /// Semantics label of the swipe-to-delete action on a set.
  ///
  /// In ar, this message translates to:
  /// **'امسح السِت'**
  String get workoutDeleteSet;

  /// Semantics label of the check button on a set row.
  ///
  /// In ar, this message translates to:
  /// **'علّم السِت خلصان'**
  String get workoutCompleteSet;

  /// Exercise no longer in the catalog.
  ///
  /// In ar, this message translates to:
  /// **'تمرين مش معروف ({id})'**
  String workoutUnknownExercise(String id);

  /// Keypad preview label when editing a weight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن ({unit})'**
  String workoutKeypadWeight(String unit);

  /// Keypad key: move to the next field.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get workoutKeypadNext;

  /// Semantics label of the keypad backspace key.
  ///
  /// In ar, this message translates to:
  /// **'امسح رقم'**
  String get workoutKeypadBackspace;

  /// Semantics label of the keypad close key.
  ///
  /// In ar, this message translates to:
  /// **'اقفل الكيبورد'**
  String get workoutKeypadHide;

  /// Semantics label of the keypad minus step key.
  ///
  /// In ar, this message translates to:
  /// **'نقّص'**
  String get workoutKeypadDecrease;

  /// Semantics label of the keypad plus step key.
  ///
  /// In ar, this message translates to:
  /// **'زوّد'**
  String get workoutKeypadIncrease;

  /// Rest timer bar label.
  ///
  /// In ar, this message translates to:
  /// **'راحة'**
  String get workoutRest;

  /// Rest timer button: end the rest now.
  ///
  /// In ar, this message translates to:
  /// **'تخطّي'**
  String get workoutRestSkip;

  /// Semantics label of the rest timer -15 button.
  ///
  /// In ar, this message translates to:
  /// **'نقّص 15 ثانية'**
  String get workoutRestLess;

  /// Semantics label of the rest timer +15 button.
  ///
  /// In ar, this message translates to:
  /// **'زوّد 15 ثانية'**
  String get workoutRestMore;

  /// Local notification title when the rest timer ends.
  ///
  /// In ar, this message translates to:
  /// **'الراحة خلصت 💪'**
  String get workoutRestNotificationTitle;

  /// Local notification body when the rest timer ends.
  ///
  /// In ar, this message translates to:
  /// **'يلا على السِت اللي بعده'**
  String get workoutRestNotificationBody;

  /// Android notification channel name.
  ///
  /// In ar, this message translates to:
  /// **'مؤقت الراحة'**
  String get workoutRestChannelName;

  /// Android notification channel description.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه لما وقت الراحة يخلص'**
  String get workoutRestChannelDescription;

  /// Finish confirmation dialog title.
  ///
  /// In ar, this message translates to:
  /// **'تنهي التمرين؟'**
  String get workoutFinishTitle;

  /// Dialog when finishing a workout with no completed sets.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ولا سِت متعلّم عليها ✓ لسه. تحب تلغي التمرين؟'**
  String get workoutFinishNothing;

  /// Button + dialog action that deletes the active workout.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التمرين'**
  String get workoutDiscard;

  /// Discard confirmation dialog title.
  ///
  /// In ar, this message translates to:
  /// **'تلغي التمرين؟'**
  String get workoutDiscardTitle;

  /// Discard confirmation dialog body.
  ///
  /// In ar, this message translates to:
  /// **'كل اللي سجّلته في التمرين ده هيتمسح.'**
  String get workoutDiscardBody;

  /// Destructive confirm button of the discard dialog.
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get workoutDiscardConfirm;

  /// Summary screen title.
  ///
  /// In ar, this message translates to:
  /// **'عاش! التمرين خلص'**
  String get workoutSummaryTitle;

  /// Summary section: personal records set in this workout.
  ///
  /// In ar, this message translates to:
  /// **'أرقام قياسية جديدة'**
  String get workoutSummaryPrs;

  /// Summary section: best set of each exercise.
  ///
  /// In ar, this message translates to:
  /// **'أحسن سِت في كل تمرين'**
  String get workoutSummaryBestSets;

  /// Summary shown for a missing workout id.
  ///
  /// In ar, this message translates to:
  /// **'التمرين ده مش موجود'**
  String get workoutSummaryNotFound;

  /// PR type: heaviest weight.
  ///
  /// In ar, this message translates to:
  /// **'أتقل وزن'**
  String get workoutPrHeaviest;

  /// PR type: best estimated one-rep max (Epley).
  ///
  /// In ar, this message translates to:
  /// **'أعلى 1RM متوقّع'**
  String get workoutPr1Rm;

  /// PR type: best single-set weight x reps.
  ///
  /// In ar, this message translates to:
  /// **'أعلى حجم في سِت'**
  String get workoutPrVolume;

  /// Lifted comparison in cars (1,400 kg each). countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{وزن عربية ملاكي 🚗} =2{وزن عربيتين ملاكي 🚗} few{وزن {countText} عربيات ملاكي 🚗} other{وزن {countText} عربية ملاكي 🚗}}'**
  String workoutCompareCar(int count, String countText);

  /// Lifted comparison in pyramid blocks (2,500 kg each).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{وزن حجر من الهرم 🗿} =2{وزن حجرين من الهرم 🗿} few{وزن {countText} حجارة من الهرم 🗿} other{وزن {countText} حجر من الهرم 🗿}}'**
  String workoutComparePyramid(int count, String countText);

  /// Lifted comparison in elephants (6,000 kg each).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{وزن فيل 🐘} =2{وزن فيلين 🐘} few{وزن {countText} فيلة 🐘} other{وزن {countText} فيل 🐘}}'**
  String workoutCompareElephant(int count, String countText);

  /// Semantics label of the minimized workout bar.
  ///
  /// In ar, this message translates to:
  /// **'افتح التمرين'**
  String get workoutBarOpen;

  /// Finish confirmation body when every set is ticked.
  ///
  /// In ar, this message translates to:
  /// **'كل السِتات متعلّم عليها ✓. نحفظ التمرين؟'**
  String get workoutFinishAllDoneBody;

  /// Finish dialog: number of sets without a tick. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فيه سِت واحد من غير ✓.} =2{فيه سِتّين من غير ✓.} few{فيه {countText} سِتات من غير ✓.} other{فيه {countText} سِت من غير ✓.}}'**
  String workoutFinishUncheckedBody(int count, String countText);

  /// Finish dialog: how many of the unticked sets have no reps (removed whatever the choice). countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{منهم سِت فاضي هيتشال.} =2{منهم سِتّين فاضيين هيتشالوا.} few{منهم {countText} سِتات فاضية هتتشال.} other{منهم {countText} سِت فاضي هيتشالوا.}}'**
  String workoutFinishEmptyNote(int count, String countText);

  /// Finish dialog action: tick every unticked set (empty reps taken from 'previous'), then finish.
  ///
  /// In ar, this message translates to:
  /// **'علّم عليهم كلهم ✓'**
  String get workoutFinishMarkAllDone;

  /// Finish dialog action: drop the unticked sets, then finish.
  ///
  /// In ar, this message translates to:
  /// **'شيلهم'**
  String get workoutFinishRemoveThem;

  /// Android-only one-time sheet on the first rest timer: title.
  ///
  /// In ar, this message translates to:
  /// **'خلّي تنبيه الراحة ييجي في معاده'**
  String get workoutExactAlarmTitle;

  /// Android-only one-time sheet: why the exact-alarm permission helps. «Alarms & reminders» is the Android settings page name.
  ///
  /// In ar, this message translates to:
  /// **'والشاشة مقفولة، أندرويد ممكن يأخّر تنبيه «الراحة خلصت» كام دقيقة. اسمح لعزم بـ«المنبّهات والتذكيرات» عشان يرن بالظبط لما الراحة تخلص. تقدر تغيّر ده في أي وقت من إعدادات الموبايل.'**
  String get workoutExactAlarmBody;

  /// Exact-alarm sheet: opens the system permission screen.
  ///
  /// In ar, this message translates to:
  /// **'افتح الإعدادات'**
  String get workoutExactAlarmAllow;

  /// Exact-alarm sheet: dismiss (never asked again automatically).
  ///
  /// In ar, this message translates to:
  /// **'مش دلوقتي'**
  String get workoutExactAlarmLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
