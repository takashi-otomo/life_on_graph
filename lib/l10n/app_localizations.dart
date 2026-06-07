import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
  ];

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get tabSummary;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get heartRate;

  /// No description provided for @sleepStages.
  ///
  /// In en, this message translates to:
  /// **'Sleep stages'**
  String get sleepStages;

  /// No description provided for @noSleepDataForDay.
  ///
  /// In en, this message translates to:
  /// **'No sleep data for this day'**
  String get noSleepDataForDay;

  /// No description provided for @noSleepData.
  ///
  /// In en, this message translates to:
  /// **'No sleep data'**
  String get noSleepData;

  /// No description provided for @noStepsDataForDay.
  ///
  /// In en, this message translates to:
  /// **'No step data for this day'**
  String get noStepsDataForDay;

  /// No description provided for @noHeartRateData.
  ///
  /// In en, this message translates to:
  /// **'No heart rate data'**
  String get noHeartRateData;

  /// No description provided for @stepsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String stepsValue(String count);

  /// No description provided for @bpmValue.
  ///
  /// In en, this message translates to:
  /// **'{value} bpm'**
  String bpmValue(int value);

  /// No description provided for @resting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get resting;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @duringSleep.
  ///
  /// In en, this message translates to:
  /// **'During sleep'**
  String get duringSleep;

  /// No description provided for @stageDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get stageDeep;

  /// No description provided for @stageLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get stageLight;

  /// No description provided for @stageRem.
  ///
  /// In en, this message translates to:
  /// **'REM'**
  String get stageRem;

  /// No description provided for @stageAwake.
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get stageAwake;

  /// No description provided for @stageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get stageUnknown;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @avgSleep.
  ///
  /// In en, this message translates to:
  /// **'Avg. sleep'**
  String get avgSleep;

  /// No description provided for @avgSteps.
  ///
  /// In en, this message translates to:
  /// **'Avg. steps'**
  String get avgSteps;

  /// No description provided for @avgHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Avg. heart rate'**
  String get avgHeartRate;

  /// No description provided for @restingHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Resting HR'**
  String get restingHeartRate;

  /// No description provided for @deltaDay.
  ///
  /// In en, this message translates to:
  /// **'vs prev day'**
  String get deltaDay;

  /// No description provided for @deltaWeek.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get deltaWeek;

  /// No description provided for @deltaMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get deltaMonth;

  /// No description provided for @viewTodayDetail.
  ///
  /// In en, this message translates to:
  /// **'View today\'s detail'**
  String get viewTodayDetail;

  /// No description provided for @sleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration'**
  String get sleepDuration;

  /// No description provided for @summaryHint.
  ///
  /// In en, this message translates to:
  /// **'Each data shown in a separate lane on a shared timeline'**
  String get summaryHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionDataSync.
  ///
  /// In en, this message translates to:
  /// **'Data sync'**
  String get sectionDataSync;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get notSynced;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String lastSynced(String time);

  /// No description provided for @healthConnectLink.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get healthConnectLink;

  /// No description provided for @healthConnectLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reads sleep, steps and heart rate (READ only)'**
  String get healthConnectLinkSubtitle;

  /// No description provided for @sectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get sectionPrivacy;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Erase sleep, steps and heart rate stored on this device'**
  String get deleteAllDataSubtitle;

  /// No description provided for @cannotDeleteWhileSyncing.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete while syncing'**
  String get cannotDeleteWhileSyncing;

  /// No description provided for @sectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get sectionInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the sleep, steps and heart rate data stored on this device. This cannot be undone.\n\n(Data in Health Connect is not deleted; it will be re-fetched on the next sync.)'**
  String get deleteDialogContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Local data deleted'**
  String get deletedSnack;

  /// No description provided for @deleteAbortedSyncing.
  ///
  /// In en, this message translates to:
  /// **'Deletion canceled because a sync is in progress'**
  String get deleteAbortedSyncing;

  /// No description provided for @statusUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is required'**
  String get statusUnavailableTitle;

  /// No description provided for @statusUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Health Connect must be installed to read sleep, steps and heart rate.'**
  String get statusUnavailableMessage;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @statusPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Access to health data is needed'**
  String get statusPermissionTitle;

  /// No description provided for @statusPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Read permission in Health Connect is required to show sleep, steps and heart rate.'**
  String get statusPermissionMessage;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @statusSyncFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get statusSyncFailedTitle;

  /// No description provided for @statusSyncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Showing locally saved data.'**
  String get statusSyncFailedMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @durationHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String durationHm(int h, int m);

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String durationMin(int m);

  /// No description provided for @prevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get prevDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @crossTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrated view (sleep × heart rate × steps)'**
  String get crossTitle;

  /// No description provided for @crossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24 hours up to wake time. Scroll horizontally.'**
  String get crossSubtitle;

  /// No description provided for @crossEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sleep data, so the integrated view is unavailable'**
  String get crossEmpty;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @rationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'About health data use'**
  String get rationaleTitle;

  /// No description provided for @rationaleIntro.
  ///
  /// In en, this message translates to:
  /// **'{app} reads the following from Health Connect and uses it only to draw charts on this device. No data is ever sent externally.'**
  String rationaleIntro(String app);

  /// No description provided for @rationaleSleepDesc.
  ///
  /// In en, this message translates to:
  /// **'Read to visualize sleep stages (deep / light / REM / awake).'**
  String get rationaleSleepDesc;

  /// No description provided for @rationaleStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'Read to visualize steps by time of day and daily / weekly / monthly.'**
  String get rationaleStepsDesc;

  /// No description provided for @rationaleHeartDesc.
  ///
  /// In en, this message translates to:
  /// **'Read to visualize heart rate, resting / max, and heart rate during sleep.'**
  String get rationaleHeartDesc;

  /// No description provided for @rationaleHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Past data (history)'**
  String get rationaleHistoryTitle;

  /// No description provided for @rationaleHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'On first launch, data older than the past 30 days is fetched once to show past trends. No continuous background collection is performed.'**
  String get rationaleHistoryDesc;

  /// No description provided for @rationaleSecurity.
  ///
  /// In en, this message translates to:
  /// **'Fetched data is encrypted with AES-256 and stored only on this device. No cloud upload or third-party sharing.'**
  String get rationaleSecurity;

  /// No description provided for @readPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read privacy policy'**
  String get readPolicy;

  /// No description provided for @openPolicyBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open published version in browser'**
  String get openPolicyBrowser;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get openApp;

  /// No description provided for @weekShort.
  ///
  /// In en, this message translates to:
  /// **'W{n}'**
  String weekShort(int n);

  /// No description provided for @jumpToday.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get jumpToday;

  /// No description provided for @jumpThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Go to this month'**
  String get jumpThisMonth;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {app}'**
  String onbWelcomeTitle(String app);

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Visualize your sleep, steps and heart rate entirely on your device. No data is sent externally.'**
  String get onbWelcomeBody;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbStart;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbLangBody.
  ///
  /// In en, this message translates to:
  /// **'We follow your device language. You can change it anytime in Settings.'**
  String get onbLangBody;

  /// No description provided for @onbPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Health Connect'**
  String get onbPermTitle;

  /// No description provided for @onbConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect & sync'**
  String get onbConnect;

  /// No description provided for @onbSkipSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up later'**
  String get onbSkipSetup;

  /// No description provided for @onbSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing your data…'**
  String get onbSyncing;

  /// No description provided for @onbDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onbDoneTitle;

  /// No description provided for @onbDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is ready. Explore your trends on the home screen.'**
  String get onbDoneBody;

  /// No description provided for @onbFinish.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onbFinish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
