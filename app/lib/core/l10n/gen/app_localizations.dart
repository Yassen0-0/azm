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

  /// One-letter label of a warm-up set.
  ///
  /// In ar, this message translates to:
  /// **'إ'**
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

  /// Finish confirmation dialog body.
  ///
  /// In ar, this message translates to:
  /// **'السِتات اللي مش متعلّم عليها ✓ هتتشال.'**
  String get workoutFinishBody;

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

  /// DEBUG-ONLY button (kDebugMode) until the exercise picker is merged. Remove at merge.
  ///
  /// In ar, this message translates to:
  /// **'DEBUG: ضيف تمارين تجريبية'**
  String get workoutDebugSeed;
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
