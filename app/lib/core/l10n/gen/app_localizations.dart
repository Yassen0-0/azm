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

  /// Set-table column header: set number / type label (SetRow, shared by workout, history, routines).
  ///
  /// In ar, this message translates to:
  /// **'سِت'**
  String get commonSetColSet;

  /// Set-table column header: same set in the last workout.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get commonSetColPrevious;

  /// Set-table column header: repetitions. Also the keypad title when editing reps.
  ///
  /// In ar, this message translates to:
  /// **'عدّات'**
  String get commonSetColReps;

  /// Weight unit label (kept Latin in Arabic, as in the SPEC). Set-table column header and keypad title.
  ///
  /// In ar, this message translates to:
  /// **'kg'**
  String get commonUnitKg;

  /// Weight unit label (kept Latin in Arabic). Set-table column header and keypad title.
  ///
  /// In ar, this message translates to:
  /// **'lb'**
  String get commonUnitLb;

  /// Placeholder for a missing value (no previous set, empty keypad value).
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get commonNoData;

  /// Title of the set type menu (tap on a set label).
  ///
  /// In ar, this message translates to:
  /// **'نوع السِت'**
  String get commonSetTypeTitle;

  /// Set type: normal working set.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get commonSetTypeNormal;

  /// Set type: warm-up.
  ///
  /// In ar, this message translates to:
  /// **'إحماء'**
  String get commonSetTypeWarmup;

  /// Set type: drop set (gym slang).
  ///
  /// In ar, this message translates to:
  /// **'دروب سِت'**
  String get commonSetTypeDrop;

  /// Set type: to failure.
  ///
  /// In ar, this message translates to:
  /// **'للفشل'**
  String get commonSetTypeFailure;

  /// One-letter label of a warm-up set: ح (from إحماء; owner decision 2026-09-26 — إ looked like '!'). Shown in amber.
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get commonSetTypeWarmupShort;

  /// One-letter label of a drop set (from دروب).
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get commonSetTypeDropShort;

  /// One-letter label of a failure set (from فشل). Never shown in red.
  ///
  /// In ar, this message translates to:
  /// **'ف'**
  String get commonSetTypeFailureShort;

  /// Semantics label / swipe action: delete a set.
  ///
  /// In ar, this message translates to:
  /// **'امسح السِت'**
  String get commonSetDelete;

  /// Semantics label of the ✓ button of a set in the live workout.
  ///
  /// In ar, this message translates to:
  /// **'علّم السِت خلصان'**
  String get commonSetComplete;

  /// Keypad preview label when editing a weight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن ({unit})'**
  String commonKeypadWeight(String unit);

  /// Keypad key: go to the next field.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get commonKeypadNext;

  /// Keypad key on the last field: close the keypad.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get commonKeypadDone;

  /// Semantics label of the keypad backspace key.
  ///
  /// In ar, this message translates to:
  /// **'امسح رقم'**
  String get commonKeypadBackspace;

  /// Semantics label of the key that hides the keypad.
  ///
  /// In ar, this message translates to:
  /// **'اقفل الكيبورد'**
  String get commonKeypadHide;

  /// Semantics label of the keypad − step key.
  ///
  /// In ar, this message translates to:
  /// **'نقّص'**
  String get commonKeypadDecrease;

  /// Semantics label of the keypad + step key.
  ///
  /// In ar, this message translates to:
  /// **'زوّد'**
  String get commonKeypadIncrease;

  /// Compact number in thousands (e.g. 450K). value has Western digits. Shared compact number format (LiftedCounter compact: true), used above 100,000.
  ///
  /// In ar, this message translates to:
  /// **'{value} ألف'**
  String commonCompactThousand(String value);

  /// Compact number in millions (e.g. 1.2M). Shared compact number format (LiftedCounter compact: true), used above 100,000.
  ///
  /// In ar, this message translates to:
  /// **'{value} مليون'**
  String commonCompactMillion(String value);

  /// Compact number in billions. Shared compact number format (LiftedCounter compact: true), used above 100,000.
  ///
  /// In ar, this message translates to:
  /// **'{value} مليار'**
  String commonCompactBillion(String value);

  /// Semantics label of a list thumbnail: tapping it opens the quick preview sheet with the exercise GIF. name = exercise name in the app language.
  ///
  /// In ar, this message translates to:
  /// **'معاينة حركة {name}'**
  String commonExercisePreview(String name);

  /// Attribution line under exercise media wherever it is shown (preview sheet). Required by docs/LICENSES.md; keep the exact text.
  ///
  /// In ar, this message translates to:
  /// **'© Gym visual — https://gymvisual.com/'**
  String get commonMediaCredit;

  /// Snackbar after a set was deleted (swipe or long-press menu); shown ~4 s with an Undo action.
  ///
  /// In ar, this message translates to:
  /// **'السِت اتمسح'**
  String get commonSetDeleted;

  /// Snackbar action: undo the last deletion.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get commonUndo;

  /// Label of the red button revealed by swiping a set row (next to a trash icon; hidden, icon only, when it doesn't fit).
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get commonSwipeDelete;

  /// Label of the start date/time in the workout time sheet.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get commonTimeStart;

  /// Label of the end date/time in the workout time sheet.
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get commonTimeEnd;

  /// Save button of the workout time sheet.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonTimeSave;

  /// Day wheel item: today.
  ///
  /// In ar, this message translates to:
  /// **'النهاردة'**
  String get commonTimeToday;

  /// Day wheel item: yesterday.
  ///
  /// In ar, this message translates to:
  /// **'امبارح'**
  String get commonTimeYesterday;

  /// Error in the workout time sheet: the chosen time is after now.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش يبقى في المستقبل'**
  String get commonTimeFuture;

  /// Error in the workout time sheet: end is not after start.
  ///
  /// In ar, this message translates to:
  /// **'النهاية لازم تبقى بعد البداية'**
  String get commonTimeOrder;

  /// Title of the sheet that edits a finished workout's start and end.
  ///
  /// In ar, this message translates to:
  /// **'عدّل وقت التمرين'**
  String get commonTimeEditTitle;

  /// Title of the sheet that edits the running workout's start time.
  ///
  /// In ar, this message translates to:
  /// **'بدأت التمرين إمتى؟'**
  String get commonTimeStartTitle;

  /// Live duration preview in the workout time sheet.
  ///
  /// In ar, this message translates to:
  /// **'المدة {time}'**
  String commonTimeDuration(String time);

  /// Screen-reader label of the day wheel.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get commonTimeDay;

  /// Screen-reader label of the hour wheel.
  ///
  /// In ar, this message translates to:
  /// **'الساعة'**
  String get commonTimeHour;

  /// Screen-reader label of the minute wheel.
  ///
  /// In ar, this message translates to:
  /// **'الدقيقة'**
  String get commonTimeMinute;

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

  /// Button that opens the equipment filter sheet (no equipment chosen).
  ///
  /// In ar, this message translates to:
  /// **'الأداة'**
  String get exercisesFilterEquipment;

  /// Number of exercises in the list under the filters. count picks the plural form; countText is the same number formatted with a thousands separator and Western digits (1,324).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش تمارين} =1{تمرين واحد} =2{تمرينين} few{{countText} تمارين} many{{countText} تمرين} other{{countText} تمرين}}'**
  String exercisesResultCount(int count, String countText);

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

  /// Clears every filter: the result bar's link while any filter is active, and the no-results button (also clears the search text). Same wording as exercisesFilterClearSheet.
  ///
  /// In ar, this message translates to:
  /// **'امسح الفلاتر'**
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

  /// Filter-bar chip + sheet title: where you train (gym / home / resistance bands).
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get exercisesFilterPlace;

  /// Filter-bar chip + sheet title: muscle group.
  ///
  /// In ar, this message translates to:
  /// **'العضلة'**
  String get exercisesFilterMuscle;

  /// Screen-reader label of a filter chip with active cards: chip name + number of selected cards (Western digits).
  ///
  /// In ar, this message translates to:
  /// **'{filter}، {count} مختار'**
  String exercisesFilterActiveCount(String filter, int count);

  /// Primary button of a filter sheet: applies the selection; shows the live number of results with it (search text and the other filters included). countText = the number with a thousands separator, Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش نتايج} =1{اعرض تمرين واحد} =2{اعرض تمرينين} few{اعرض {countText} تمارين} many{اعرض {countText} تمرين} other{اعرض {countText} تمرين}}'**
  String exercisesFilterShowResults(int count, String countText);

  /// Secondary button of a filter sheet: unselects every card of this sheet (the result count updates; nothing applies until Show).
  ///
  /// In ar, this message translates to:
  /// **'امسح الفلاتر'**
  String get exercisesFilterClearSheet;

  /// Screen-reader hint of a selected filter card.
  ///
  /// In ar, this message translates to:
  /// **'مختار'**
  String get exercisesFilterCardSelected;

  /// Muscle Group sheet: section title.
  ///
  /// In ar, this message translates to:
  /// **'الجزء العلوي'**
  String get exercisesMuscleSectionUpper;

  /// Muscle Group sheet: section title.
  ///
  /// In ar, this message translates to:
  /// **'الجزء السفلي'**
  String get exercisesMuscleSectionLower;

  /// Muscle Group sheet: section title (cardio, full body, other).
  ///
  /// In ar, this message translates to:
  /// **'تاني'**
  String get exercisesMuscleSectionOther;

  /// Place filter card: everything (a gym has all equipment).
  ///
  /// In ar, this message translates to:
  /// **'جيم'**
  String get exercisesPlaceGym;

  /// Place filter card: bodyweight, dumbbells, kettlebells and bands (data/place_mapping.json).
  ///
  /// In ar, this message translates to:
  /// **'البيت'**
  String get exercisesPlaceHome;

  /// Place filter card: band exercises only.
  ///
  /// In ar, this message translates to:
  /// **'أحبال مقاومة'**
  String get exercisesPlaceBands;

  /// Muscle Group card (Egyptian gym term).
  ///
  /// In ar, this message translates to:
  /// **'بطن'**
  String get exercisesGroupAbs;

  /// Muscle Group card (Egyptian gym term).
  ///
  /// In ar, this message translates to:
  /// **'باي'**
  String get exercisesGroupBiceps;

  /// Muscle Group card.
  ///
  /// In ar, this message translates to:
  /// **'صدر'**
  String get exercisesGroupChest;

  /// Muscle Group card.
  ///
  /// In ar, this message translates to:
  /// **'سواعد'**
  String get exercisesGroupForearms;

  /// Muscle Group card (same word as the owner-reviewed muscle label).
  ///
  /// In ar, this message translates to:
  /// **'لاتس'**
  String get exercisesGroupLats;

  /// Muscle Group card (Egyptian spelling ضهر, as said in the gym).
  ///
  /// In ar, this message translates to:
  /// **'ضهر سفلي'**
  String get exercisesGroupLowerBack;

  /// Muscle Group card.
  ///
  /// In ar, this message translates to:
  /// **'رقبة'**
  String get exercisesGroupNeck;

  /// Muscle Group card (Egyptian gym term).
  ///
  /// In ar, this message translates to:
  /// **'كتف'**
  String get exercisesGroupShoulders;

  /// Muscle Group card (Egyptian gym term).
  ///
  /// In ar, this message translates to:
  /// **'ترابيس'**
  String get exercisesGroupTraps;

  /// Muscle Group card (Egyptian gym term).
  ///
  /// In ar, this message translates to:
  /// **'تراي'**
  String get exercisesGroupTriceps;

  /// Muscle Group card: upper/mid back (Egyptian gym term ضهر; lats are their own card).
  ///
  /// In ar, this message translates to:
  /// **'ضهر'**
  String get exercisesGroupUpperBack;

  /// Muscle Group card: hip abductors (Egyptian gyms name them after the machine: خارجي).
  ///
  /// In ar, this message translates to:
  /// **'خارجي'**
  String get exercisesGroupAbductors;

  /// Muscle Group card: hip adductors (the داخلي machine).
  ///
  /// In ar, this message translates to:
  /// **'داخلي'**
  String get exercisesGroupAdductors;

  /// Muscle Group card (Egyptian gym term).
  ///
  /// In ar, this message translates to:
  /// **'سمانة'**
  String get exercisesGroupCalves;

  /// Muscle Group card.
  ///
  /// In ar, this message translates to:
  /// **'مؤخرة'**
  String get exercisesGroupGlutes;

  /// Muscle Group card (Egyptian gym term for the back of the thigh).
  ///
  /// In ar, this message translates to:
  /// **'خلفي'**
  String get exercisesGroupHamstrings;

  /// Muscle Group card (Egyptian gym term for the front of the thigh).
  ///
  /// In ar, this message translates to:
  /// **'رجل أمامي'**
  String get exercisesGroupQuads;

  /// Muscle Group card.
  ///
  /// In ar, this message translates to:
  /// **'كارديو'**
  String get exercisesGroupCardio;

  /// Muscle Group card: compound total-body moves (list in data/muscle_mapping.json).
  ///
  /// In ar, this message translates to:
  /// **'جسم كامل'**
  String get exercisesGroupFullBody;

  /// Muscle Group card: anything the mapping can't place (0 in the current dataset).
  ///
  /// In ar, this message translates to:
  /// **'تاني'**
  String get exercisesGroupOther;

  /// Equipment filter card: bodyweight / no equipment.
  ///
  /// In ar, this message translates to:
  /// **'من غير أداة'**
  String get exercisesEquipGroupNone;

  /// Equipment filter card (bar, EZ bar, Olympic bar, trap bar).
  ///
  /// In ar, this message translates to:
  /// **'بار'**
  String get exercisesEquipGroupBarbell;

  /// Equipment filter card.
  ///
  /// In ar, this message translates to:
  /// **'دمبل'**
  String get exercisesEquipGroupDumbbell;

  /// Equipment filter card.
  ///
  /// In ar, this message translates to:
  /// **'كيتل بل'**
  String get exercisesEquipGroupKettlebell;

  /// Equipment filter card (lever, Smith, sled, cardio machines).
  ///
  /// In ar, this message translates to:
  /// **'جهاز'**
  String get exercisesEquipGroupMachine;

  /// Equipment filter card.
  ///
  /// In ar, this message translates to:
  /// **'كابل'**
  String get exercisesEquipGroupCable;

  /// Equipment filter card (weighted moves with a plate; Egyptian gym term طارة).
  ///
  /// In ar, this message translates to:
  /// **'طارة'**
  String get exercisesEquipGroupPlate;

  /// Equipment filter card.
  ///
  /// In ar, this message translates to:
  /// **'أحبال مقاومة'**
  String get exercisesEquipGroupResistanceBand;

  /// Equipment filter card (TRX-style; no dataset exercise yet).
  ///
  /// In ar, this message translates to:
  /// **'أحبال تعليق'**
  String get exercisesEquipGroupSuspensionBand;

  /// Equipment filter card (balls, rollers, ropes, hammer, tire).
  ///
  /// In ar, this message translates to:
  /// **'تاني'**
  String get exercisesEquipGroupOther;

  /// Short visible label of the Muscle group chip in the filter bar (three chips share the row; the full name is the sheet title and the screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'العضلة'**
  String get exercisesFilterMuscleChip;

  /// History header label above the all-time Lifted total (sum of weight x reps of every completed set).
  ///
  /// In ar, this message translates to:
  /// **'شِلت لحد دلوقتي'**
  String get historyLiftedSoFar;

  /// Number of finished workouts. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش تمارين} =1{تمرين واحد} =2{تمرينين} few{{countText} تمارين} other{{countText} تمرين}}'**
  String historyWorkoutCount(int count, String countText);

  /// Number of completed sets. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش سِتات} =1{سِت واحد} =2{سِتّين} few{{countText} سِتات} other{{countText} سِت}}'**
  String historySetCount(int count, String countText);

  /// Button on the History header that opens the Stats screen.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get historyOpenStats;

  /// Segmented control: show history as a list of workout cards.
  ///
  /// In ar, this message translates to:
  /// **'قائمة'**
  String get historyViewList;

  /// Segmented control: show history as a month calendar.
  ///
  /// In ar, this message translates to:
  /// **'تقويم'**
  String get historyViewCalendar;

  /// History empty state title.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش تمارين'**
  String get historyEmptyTitle;

  /// History empty state body.
  ///
  /// In ar, this message translates to:
  /// **'خلّص أول تمرين وهتلاقيه هنا، ومعاه كل اللي شِلته.'**
  String get historyEmptyBody;

  /// Workout duration under an hour. minutes has Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} د'**
  String historyDurationMinutes(String minutes);

  /// Workout duration of an hour or more.
  ///
  /// In ar, this message translates to:
  /// **'{hours} س {minutes} د'**
  String historyDurationHours(String hours, String minutes);

  /// A weight with its unit, e.g. 62.5 kg.
  ///
  /// In ar, this message translates to:
  /// **'{value} {unit}'**
  String historyWeightValue(String value, String unit);

  /// One set: weight x reps (kept left-to-right).
  ///
  /// In ar, this message translates to:
  /// **'{weight} × {reps}'**
  String historySetValue(String weight, String reps);

  /// Workout card line: number of sets x exercise name.
  ///
  /// In ar, this message translates to:
  /// **'{count} × {name}'**
  String historyExerciseSets(String count, String name);

  /// Workout card: number of personal records set in that workout.
  ///
  /// In ar, this message translates to:
  /// **'🏆 {count}'**
  String historyPrBadge(String count);

  /// Screen-reader label of the PR badge.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{رقم قياسي واحد} =2{رقمين قياسيين} few{{countText} أرقام قياسية} other{{countText} رقم قياسي}}'**
  String historyPrCountLabel(int count, String countText);

  /// No data yet (grey dash, never 0).
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get historyNoData;

  /// Name shown for an exercise that is no longer in the catalog.
  ///
  /// In ar, this message translates to:
  /// **'تمرين مش معروف ({id})'**
  String historyUnknownExercise(String id);

  /// Calendar: go to the previous month (screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'الشهر اللي فات'**
  String get historyPrevMonth;

  /// Calendar: go to the next month (screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'الشهر الجاي'**
  String get historyNextMonth;

  /// Calendar: the selected day has no workouts.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تمارين في اليوم ده'**
  String get historyDayEmpty;

  /// Calendar: hint when no day is selected.
  ///
  /// In ar, this message translates to:
  /// **'دوس على يوم معلّم عشان تشوف تمارينه'**
  String get historyPickDay;

  /// Past workout header menu button (screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'خيارات التمرين'**
  String get historyWorkoutOptions;

  /// Menu action: rename the workout.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الاسم'**
  String get historyRename;

  /// Rename dialog title.
  ///
  /// In ar, this message translates to:
  /// **'اسم التمرين'**
  String get historyRenameTitle;

  /// Dialog button: save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get historySave;

  /// Dialog button: cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get historyCancel;

  /// Menu action / button: delete this past workout.
  ///
  /// In ar, this message translates to:
  /// **'امسح التمرين'**
  String get historyDeleteWorkout;

  /// Delete confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'تمسح التمرين ده؟'**
  String get historyDeleteTitle;

  /// Delete confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'هيتمسح بكل سِتاته، واللي شِلته والأرقام القياسية هيتحسبوا من تاني. مفيش رجوع.'**
  String get historyDeleteBody;

  /// Delete confirmation button.
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get historyDeleteConfirm;

  /// Stat label: workout duration.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get historyStatDuration;

  /// Stat label: Lifted (weight x reps of completed sets).
  ///
  /// In ar, this message translates to:
  /// **'شِلت'**
  String get historyStatLifted;

  /// Stat label: completed sets.
  ///
  /// In ar, this message translates to:
  /// **'السِتات'**
  String get historyStatSets;

  /// Stat label: personal records.
  ///
  /// In ar, this message translates to:
  /// **'أرقام قياسية'**
  String get historyStatPrs;

  /// Stat label: number of finished workouts.
  ///
  /// In ar, this message translates to:
  /// **'التمارين'**
  String get historyStatWorkouts;

  /// Button under an exercise's sets.
  ///
  /// In ar, this message translates to:
  /// **'ضيف سِت'**
  String get historyAddSet;

  /// Button: add exercises to this past workout.
  ///
  /// In ar, this message translates to:
  /// **'ضيف تمرين'**
  String get historyAddExercise;

  /// Exercise menu button (screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'خيارات التمرين'**
  String get historyExerciseOptions;

  /// Exercise menu action.
  ///
  /// In ar, this message translates to:
  /// **'شيل التمرين'**
  String get historyRemoveExercise;

  /// Hint at the top of a past workout being edited: edits are saved immediately; delete a set by swiping it toward the START edge (right in Arabic, left in English) or long-pressing it (menu → Delete set); Undo shows for ~4 s.
  ///
  /// In ar, this message translates to:
  /// **'التعديلات بتتحفظ على طول. اسحب السِت لليمين أو دوس عليه مطوّلًا عشان تمسحه.'**
  String get historyEditHint;

  /// Past workout: id not found or not finished.
  ///
  /// In ar, this message translates to:
  /// **'التمرين ده مش موجود'**
  String get historyNotFound;

  /// Stats screen title.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get historyStatsTitle;

  /// Stats section: weekly workout chart.
  ///
  /// In ar, this message translates to:
  /// **'تمارين في الأسبوع'**
  String get historyStatsPerWeek;

  /// Stats chart headline: workouts in the current week.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{الأسبوع ده: مفيش لسه} =1{الأسبوع ده: تمرين واحد} =2{الأسبوع ده: تمرينين} few{الأسبوع ده: {countText} تمارين} other{الأسبوع ده: {countText} تمرين}}'**
  String historyStatsThisWeek(int count, String countText);

  /// Stats chart subline: average workouts per week over the chart.
  ///
  /// In ar, this message translates to:
  /// **'متوسط {value} في الأسبوع'**
  String historyStatsAverage(String value);

  /// Stats section: per-exercise records.
  ///
  /// In ar, this message translates to:
  /// **'أرقامك القياسية'**
  String get historyStatsRecords;

  /// Stats: no records yet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش أرقام قياسية. خلّص تمرين فيه أوزان وهتظهر هنا.'**
  String get historyStatsRecordsEmpty;

  /// Record: heaviest weight.
  ///
  /// In ar, this message translates to:
  /// **'أتقل وزن'**
  String get historyRecordHeaviest;

  /// Record: best estimated one-rep max (Epley).
  ///
  /// In ar, this message translates to:
  /// **'1RM تقديري'**
  String get historyRecord1Rm;

  /// Record: best single-set volume (weight x reps).
  ///
  /// In ar, this message translates to:
  /// **'أحسن حجم'**
  String get historyRecordVolume;

  /// Exercise detail: opens the full history of the exercise. count = number of workouts.
  ///
  /// In ar, this message translates to:
  /// **'شوف كل السجل ({count})'**
  String historySeeAll(String count);

  /// Full exercise history: records card title.
  ///
  /// In ar, this message translates to:
  /// **'أرقامك في التمرين ده'**
  String get historyExerciseRecords;

  /// Past workout menu action: edit its start and end time.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الوقت'**
  String get historyEditTime;

  /// Progress label at the top of onboarding.
  ///
  /// In ar, this message translates to:
  /// **'خطوة {step} من {total}'**
  String onboardingStep(String step, String total);

  /// Small heading on the first onboarding step.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بيك في عزم'**
  String get onboardingWelcome;

  /// Title of the unit step.
  ///
  /// In ar, this message translates to:
  /// **'بتشيل بالكيلو ولا بالباوند؟'**
  String get onboardingUnitTitle;

  /// Body of the unit step.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تغيّرها بعدين من الإعدادات.'**
  String get onboardingUnitBody;

  /// Unit option (kg).
  ///
  /// In ar, this message translates to:
  /// **'كيلو'**
  String get onboardingUnitKg;

  /// Unit option (lb).
  ///
  /// In ar, this message translates to:
  /// **'باوند'**
  String get onboardingUnitLb;

  /// Example under a unit option; weight = e.g. 60 kg (kept left-to-right).
  ///
  /// In ar, this message translates to:
  /// **'مثلاً بنش {weight}'**
  String onboardingUnitExample(String weight);

  /// Button: next onboarding step.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// Title of the ready program step.
  ///
  /// In ar, this message translates to:
  /// **'تحب تبدأ ببرنامج جاهز؟'**
  String get onboardingProgramTitle;

  /// Body of the ready program step.
  ///
  /// In ar, this message translates to:
  /// **'أيامه هتتضاف لروتيناتك وتقدر تعدّل فيها براحتك.'**
  String get onboardingProgramBody;

  /// Primary button when a program is selected.
  ///
  /// In ar, this message translates to:
  /// **'ضيف البرنامج وابدأ'**
  String get onboardingStartWithProgram;

  /// Button that finishes onboarding without a program.
  ///
  /// In ar, this message translates to:
  /// **'تخطّى، وابدأ من غير برنامج'**
  String get onboardingSkip;

  /// Button of the single onboarding screen (unit only).
  ///
  /// In ar, this message translates to:
  /// **'يلا بينا'**
  String get onboardingStart;

  /// Section title on the Workout tab.
  ///
  /// In ar, this message translates to:
  /// **'روتيناتي'**
  String get routinesMyRoutines;

  /// Button that creates a routine; also the editor title for a new routine.
  ///
  /// In ar, this message translates to:
  /// **'روتين جديد'**
  String get routinesNew;

  /// Empty state title under My routines.
  ///
  /// In ar, this message translates to:
  /// **'لسه معندكش روتين'**
  String get routinesEmptyTitle;

  /// Empty state body under My routines.
  ///
  /// In ar, this message translates to:
  /// **'اعمل الروتين مرة واحدة وابدأه بضغطة واحدة. أو خد برنامج جاهز.'**
  String get routinesEmptyBody;

  /// Number of exercises in a routine card. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش تمارين} =1{تمرين واحد} =2{تمرينين} few{{countText} تمارين} other{{countText} تمرين}}'**
  String routinesExerciseCount(int count, String countText);

  /// Semantics label of the play button on a routine card.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ {name}'**
  String routinesStart(String name);

  /// Entry to the ready programs list; screen title.
  ///
  /// In ar, this message translates to:
  /// **'برامج جاهزة'**
  String get routinesReadyPrograms;

  /// Subtitle of the ready programs entry.
  ///
  /// In ar, this message translates to:
  /// **'خد برنامج مجرّب وعدّل فيه براحتك'**
  String get routinesReadyProgramsHint;

  /// Shown for a routine whose name is empty.
  ///
  /// In ar, this message translates to:
  /// **'روتين من غير اسم'**
  String get routinesUntitled;

  /// Editor title for an existing routine.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الروتين'**
  String get routinesEditTitle;

  /// Hint of the routine name field.
  ///
  /// In ar, this message translates to:
  /// **'اسم الروتين'**
  String get routinesNameHint;

  /// Hint of the routine notes field.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get routinesNotesHint;

  /// Button that opens the exercise picker in the routine editor.
  ///
  /// In ar, this message translates to:
  /// **'ضيف تمارين'**
  String get routinesAddExercises;

  /// Hint in the editor while the routine has no exercises.
  ///
  /// In ar, this message translates to:
  /// **'ضيف تمارين الروتين، وحدّد السِتات المطلوبة لكل تمرين.'**
  String get routinesEditorEmpty;

  /// Kilogram unit label.
  ///
  /// In ar, this message translates to:
  /// **'kg'**
  String get routinesUnitKg;

  /// Pound unit label.
  ///
  /// In ar, this message translates to:
  /// **'lb'**
  String get routinesUnitLb;

  /// Adds a target set to an exercise.
  ///
  /// In ar, this message translates to:
  /// **'ضيف سِت'**
  String get routinesAddSet;

  /// Rest override chip on a routine exercise, e.g. Rest 2:30.
  ///
  /// In ar, this message translates to:
  /// **'راحة {time}'**
  String routinesRestValue(String time);

  /// Rest chip when the exercise uses the default rest from settings.
  ///
  /// In ar, this message translates to:
  /// **'راحة {time} (الافتراضي)'**
  String routinesRestDefault(String time);

  /// Title of the rest time menu.
  ///
  /// In ar, this message translates to:
  /// **'وقت الراحة'**
  String get routinesRestTitle;

  /// Rest menu option that removes the override.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي من الإعدادات ({time})'**
  String routinesRestUseDefault(String time);

  /// Semantics label of the ⋯ button on an exercise card.
  ///
  /// In ar, this message translates to:
  /// **'اختيارات التمرين'**
  String get routinesExerciseOptions;

  /// Exercise menu: opens drag-to-reorder.
  ///
  /// In ar, this message translates to:
  /// **'رتّب التمارين'**
  String get routinesReorder;

  /// Exercise menu: removes the exercise from the routine.
  ///
  /// In ar, this message translates to:
  /// **'شيل التمرين'**
  String get routinesRemoveExercise;

  /// Confirmation title before removing an exercise.
  ///
  /// In ar, this message translates to:
  /// **'تشيل التمرين ده؟'**
  String get routinesRemoveExerciseTitle;

  /// Confirmation body before removing an exercise.
  ///
  /// In ar, this message translates to:
  /// **'السِتات بتاعته هتتشال من الروتين.'**
  String get routinesRemoveExerciseBody;

  /// Confirm button: remove an exercise.
  ///
  /// In ar, this message translates to:
  /// **'شيل'**
  String get routinesRemove;

  /// Button at the bottom of the editor.
  ///
  /// In ar, this message translates to:
  /// **'امسح الروتين'**
  String get routinesDelete;

  /// Confirmation title before deleting a routine.
  ///
  /// In ar, this message translates to:
  /// **'تمسح الروتين ده؟'**
  String get routinesDeleteTitle;

  /// Confirmation body before deleting a routine.
  ///
  /// In ar, this message translates to:
  /// **'التمارين اللي عملتها بيه هتفضل في السجل.'**
  String get routinesDeleteBody;

  /// Confirm button: delete a routine.
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get routinesDeleteConfirm;

  /// Cancel button in dialogs.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get routinesCancel;

  /// Closes a sheet (reorder).
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get routinesDone;

  /// Primary button in the editor: starts a workout from this routine.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التمرين'**
  String get routinesStartWorkout;

  /// Keypad title while editing a target weight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن المطلوب ({unit})'**
  String routinesKeypadWeight(String unit);

  /// Keypad title while editing target reps.
  ///
  /// In ar, this message translates to:
  /// **'العدّات المطلوبة'**
  String get routinesKeypadReps;

  /// Program frequency. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{يوم واحد في الأسبوع} =2{يومين في الأسبوع} few{{countText} أيام في الأسبوع} other{{countText} يوم في الأسبوع}}'**
  String routinesProgramDays(int count, String countText);

  /// Number of routines (days) in a program. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{روتين واحد} =2{روتينين} few{{countText} روتينات} other{{countText} روتين}}'**
  String routinesProgramRoutineCount(int count, String countText);

  /// Program level.
  ///
  /// In ar, this message translates to:
  /// **'مبتدئ'**
  String get routinesLevelBeginner;

  /// Program level.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get routinesLevelIntermediate;

  /// Primary button on a program preview: copies each day as a routine.
  ///
  /// In ar, this message translates to:
  /// **'ضيفه لروتيناتي'**
  String get routinesProgramAdd;

  /// Toast after copying a program. countText = count with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{اتضاف روتين واحد لروتيناتك} =2{اتضاف روتينين لروتيناتك} few{اتضاف {countText} روتينات لروتيناتك} other{اتضاف {countText} روتين لروتيناتك}}'**
  String routinesProgramAdded(int count, String countText);

  /// Sets × reps range of a program exercise, e.g. 3 × 8–12.
  ///
  /// In ar, this message translates to:
  /// **'{sets} × {reps}'**
  String routinesSetsReps(String sets, String reps);

  /// Shown when a program id is not in the catalog.
  ///
  /// In ar, this message translates to:
  /// **'البرنامج ده مش موجود.'**
  String get routinesProgramMissing;

  /// Separator between exercise names in a routine card preview.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get routinesListSeparator;

  /// Toast when starting a routine while another workout is active.
  ///
  /// In ar, this message translates to:
  /// **'فيه تمرين شغال، ففتحناهولك.'**
  String get routinesResumed;

  /// Name of an exercise that left the catalog.
  ///
  /// In ar, this message translates to:
  /// **'تمرين مش معروف ({id})'**
  String routinesUnknownExercise(String id);

  /// Section header on the Workout tab with the number of routines.
  ///
  /// In ar, this message translates to:
  /// **'روتيناتي ({count})'**
  String routinesMyRoutinesCount(String count);

  /// Screen-reader label of the dumbbell start button (icon only).
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الروتين'**
  String get routinesStartRoutine;

  /// Screen-reader label of the ⋯ menu on a routine card.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الروتين'**
  String get routinesOptions;

  /// Action on the routine detail: open the editor.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get routinesEditShort;

  /// Title bar of the read-only routine detail.
  ///
  /// In ar, this message translates to:
  /// **'الروتين'**
  String get routinesDetailTitle;

  /// Section label on the routine detail.
  ///
  /// In ar, this message translates to:
  /// **'التمارين'**
  String get routinesDetailExercises;

  /// Routine detail of a routine without exercises.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش تمارين. دوس تعديل وضيف.'**
  String get routinesDetailEmpty;

  /// Empty state of My routines while ready programs are hidden.
  ///
  /// In ar, this message translates to:
  /// **'اعمل الروتين مرة واحدة وابدأه بضغطة واحدة.'**
  String get routinesEmptyBodyNoPrograms;

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

  /// Settings group: weight unit and default rest time.
  ///
  /// In ar, this message translates to:
  /// **'التمرين'**
  String get settingsTraining;

  /// Settings row + sheet title: kg or lb (display only; weights are stored in kg).
  ///
  /// In ar, this message translates to:
  /// **'وحدة الوزن'**
  String get settingsUnit;

  /// Unit choice: kilograms.
  ///
  /// In ar, this message translates to:
  /// **'كيلو (kg)'**
  String get settingsUnitKg;

  /// Unit choice: pounds.
  ///
  /// In ar, this message translates to:
  /// **'باوند (lb)'**
  String get settingsUnitLb;

  /// Short current value of the unit row (Latin 'kg' in both languages, like the rest of the app).
  ///
  /// In ar, this message translates to:
  /// **'kg'**
  String get settingsUnitValueKg;

  /// Short current value of the unit row (Latin 'lb' in both languages).
  ///
  /// In ar, this message translates to:
  /// **'lb'**
  String get settingsUnitValueLb;

  /// Settings row + sheet title: default rest between sets (routines can override it per exercise).
  ///
  /// In ar, this message translates to:
  /// **'وقت الراحة الافتراضي'**
  String get settingsDefaultRest;

  /// Small line under the rest sheet title.
  ///
  /// In ar, this message translates to:
  /// **'الروتين يقدر يغيّره لكل تمرين'**
  String get settingsDefaultRestHint;

  /// Settings group: export / import a JSON backup file.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الاحتياطية'**
  String get settingsBackup;

  /// Backup row: create the backup file and open the share sheet.
  ///
  /// In ar, this message translates to:
  /// **'صدّر نسخة احتياطية'**
  String get settingsExport;

  /// Subtitle of the export row.
  ///
  /// In ar, this message translates to:
  /// **'روتيناتك وسجلّك وإعداداتك في ملف واحد'**
  String get settingsExportHint;

  /// Backup row: pick a backup file and restore it.
  ///
  /// In ar, this message translates to:
  /// **'استرجع نسخة احتياطية'**
  String get settingsImport;

  /// Subtitle of the import row (warns that import replaces everything).
  ///
  /// In ar, this message translates to:
  /// **'هيبدّل كل البيانات اللي على الموبايل ده'**
  String get settingsImportHint;

  /// Toast when writing/sharing the backup file fails.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نعمل النسخة. جرّب تاني.'**
  String get settingsExportFailed;

  /// Import confirmation dialog title.
  ///
  /// In ar, this message translates to:
  /// **'تسترجع النسخة دي؟'**
  String get settingsImportConfirmTitle;

  /// First line of the import confirmation: when the backup was made. {date} is a formatted date + time with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'نسخة من {date}'**
  String settingsImportFrom(String date);

  /// Import confirmation count line. {count} is formatted with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'الروتينات: {count}'**
  String settingsImportCountRoutines(String count);

  /// Import confirmation count line: finished + active workouts in the file.
  ///
  /// In ar, this message translates to:
  /// **'التمارين: {count}'**
  String settingsImportCountWorkouts(String count);

  /// Import confirmation count line: logged sets in the file (same word as the History stat).
  ///
  /// In ar, this message translates to:
  /// **'السِتات: {count}'**
  String settingsImportCountSets(String count);

  /// Import confirmation warning.
  ///
  /// In ar, this message translates to:
  /// **'كل اللي على الموبايل ده هيتمسح ويتبدّل بالنسخة دي. مفيش رجوع.'**
  String get settingsImportWarning;

  /// Destructive confirm button of the import dialog.
  ///
  /// In ar, this message translates to:
  /// **'استرجع'**
  String get settingsImportConfirm;

  /// Cancel button in settings dialogs.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get settingsCancel;

  /// Dismiss button of the import error dialog.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get settingsOk;

  /// Toast after a successful import.
  ///
  /// In ar, this message translates to:
  /// **'النسخة رجعت ✓'**
  String get settingsImportDone;

  /// Title of the import error dialog.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نسترجع الملف ده'**
  String get settingsImportErrorTitle;

  /// Import error: the file is not JSON.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده مش نسخة احتياطية (مش ملف JSON).'**
  String get settingsImportErrorNotJson;

  /// Import error: JSON without the Azm backup marker.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده مش نسخة احتياطية من عزم.'**
  String get settingsImportErrorNotAzm;

  /// Import error: the backup version is newer than this app understands.
  ///
  /// In ar, this message translates to:
  /// **'النسخة دي معمولة بإصدار أحدث من عزم. حدّث التطبيق وجرّب تاني.'**
  String get settingsImportErrorNewer;

  /// Import error: an Azm backup with broken content (types, ids, links).
  ///
  /// In ar, this message translates to:
  /// **'الملف ده بايظ أو ناقص.'**
  String get settingsImportErrorCorrupt;

  /// Import error: the picked file could not be opened.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا الملف.'**
  String get settingsImportErrorRead;

  /// Import refused while a workout is running.
  ///
  /// In ar, this message translates to:
  /// **'خلّص التمرين اللي شغال أو الغيه الأول، وبعدين استرجع النسخة.'**
  String get settingsImportErrorActive;

  /// Second line of every import error: nothing was modified.
  ///
  /// In ar, this message translates to:
  /// **'بياناتك زي ما هي، محصلش أي تغيير.'**
  String get settingsImportUnchanged;

  /// Settings group: licences and version.
  ///
  /// In ar, this message translates to:
  /// **'عن عزم'**
  String get settingsAbout;

  /// Settings row + licences screen title.
  ///
  /// In ar, this message translates to:
  /// **'التراخيص والمصادر'**
  String get settingsLicenses;

  /// App version line under the About group. {version} like 1.0.0.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String settingsVersion(String version);

  /// Intro line on the licences screen.
  ///
  /// In ar, this message translates to:
  /// **'عزم مبني على شغل ناس تانية. شكراً ليهم.'**
  String get settingsLicensesIntro;

  /// Licences card title: the exercise dataset.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التمارين'**
  String get settingsLicensesExerciseData;

  /// What the dataset provides.
  ///
  /// In ar, this message translates to:
  /// **'أسماء التمارين بالإنجليزي والعضلات والأدوات والتعليمات.'**
  String get settingsLicensesExerciseDataBody;

  /// Attribution text from docs/LICENSES.md. Keep it in English, word for word.
  ///
  /// In ar, this message translates to:
  /// **'Exercise data © 2026 Hasan Emir Yıldırım, MIT License'**
  String get settingsLicensesExerciseDataCredit;

  /// Licences card title: the typeface.
  ///
  /// In ar, this message translates to:
  /// **'الخط'**
  String get settingsLicensesFont;

  /// Attribution text from docs/LICENSES.md. Keep it in English, word for word.
  ///
  /// In ar, this message translates to:
  /// **'Readex Pro © The Readex Pro Project Authors, SIL OFL 1.1'**
  String get settingsLicensesFontCredit;

  /// Licences card title: exercise media.
  ///
  /// In ar, this message translates to:
  /// **'صور وحركات التمارين'**
  String get settingsLicensesMedia;

  /// Media is shown only when licensed (docs/LICENSES.md).
  ///
  /// In ar, this message translates to:
  /// **'بتظهر بس للتمارين اللي معانا ترخيص لصورها.'**
  String get settingsLicensesMediaBody;

  /// Mandatory media attribution. Keep it word for word.
  ///
  /// In ar, this message translates to:
  /// **'© Gym visual — https://gymvisual.com/'**
  String get settingsLicensesMediaCredit;

  /// Licences card title: our own content.
  ///
  /// In ar, this message translates to:
  /// **'الأسماء العربية والبرامج'**
  String get settingsLicensesOurs;

  /// Our own content credit.
  ///
  /// In ar, this message translates to:
  /// **'الأسماء المصري والبرامج الجاهزة من عمل فريق عزم.'**
  String get settingsLicensesOursBody;

  /// Licences row: opens Flutter's licence page.
  ///
  /// In ar, this message translates to:
  /// **'مكتبات مفتوحة المصدر'**
  String get settingsLicensesPackages;

  /// Subtitle of the open-source packages row.
  ///
  /// In ar, this message translates to:
  /// **'النص الكامل لكل التراخيص، ومعاهم بيانات التمارين والخط.'**
  String get settingsLicensesPackagesBody;

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

  /// Exercise no longer in the catalog.
  ///
  /// In ar, this message translates to:
  /// **'تمرين مش معروف ({id})'**
  String workoutUnknownExercise(String id);

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

  /// Compact row on the Workout tab that starts an empty workout.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ تمرين فاضي'**
  String get workoutStartEmpty;

  /// Placeholder of the one-line notes field under an exercise in the live workout.
  ///
  /// In ar, this message translates to:
  /// **'ضيف ملاحظة...'**
  String get workoutNotesHint;

  /// Tappable rest line under an exercise (time like 1:30, or OFF).
  ///
  /// In ar, this message translates to:
  /// **'الراحة: {time}'**
  String workoutRestLine(String time);

  /// Rest line value when this exercise has no rest timer.
  ///
  /// In ar, this message translates to:
  /// **'مقفولة'**
  String get workoutRestOff;

  /// Title of the per-exercise rest picker in the live workout.
  ///
  /// In ar, this message translates to:
  /// **'وقت الراحة'**
  String get workoutRestPickerTitle;

  /// Rest picker option: use the routine / settings default.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي ({time})'**
  String workoutRestPickerDefault(String time);

  /// Rest picker option: no rest timer for this exercise.
  ///
  /// In ar, this message translates to:
  /// **'من غير تايمر'**
  String get workoutRestPickerOff;

  /// Top-bar button + sheet title: start a manual rest countdown.
  ///
  /// In ar, this message translates to:
  /// **'تايمر الراحة'**
  String get workoutTimerTitle;

  /// Body of the manual rest timer sheet.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ عدّ تنازلي للراحة دلوقتي.'**
  String get workoutTimerBody;

  /// Manual rest sheet: the running timer's remaining time.
  ///
  /// In ar, this message translates to:
  /// **'فاضل {time}'**
  String workoutTimerRunning(String time);

  /// Screen-reader label of the elapsed time in the live workout top bar.
  ///
  /// In ar, this message translates to:
  /// **'عدّى {time}. دوس عشان تغيّر وقت البداية'**
  String workoutElapsedEdit(String time);

  /// Hint in the sheet that edits the running workout's start time.
  ///
  /// In ar, this message translates to:
  /// **'نسيت تفتح الأبلكيشن في ميعادك؟ رجّع وقت البداية والمدة هتتظبط.'**
  String get workoutStartTimeHint;

  /// Workout summary action: edit start and end time.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الوقت'**
  String get workoutEditTimes;
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
