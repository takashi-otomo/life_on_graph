// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabSummary => 'Summary';

  @override
  String get tabSettings => 'Settings';

  @override
  String get today => 'Today';

  @override
  String get sleep => 'Sleep';

  @override
  String get steps => 'Steps';

  @override
  String get heartRate => 'Heart rate';

  @override
  String get sleepStages => 'Sleep stages';

  @override
  String get noSleepDataForDay => 'No sleep data for this day';

  @override
  String get noSleepData => 'No sleep data';

  @override
  String get noStepsDataForDay => 'No step data for this day';

  @override
  String get noHeartRateData => 'No heart rate data';

  @override
  String stepsValue(String count) {
    return '$count steps';
  }

  @override
  String bpmValue(int value) {
    return '$value bpm';
  }

  @override
  String get resting => 'Resting';

  @override
  String get max => 'Max';

  @override
  String get allDay => 'All day';

  @override
  String get duringSleep => 'During sleep';

  @override
  String get stageDeep => 'Deep';

  @override
  String get stageLight => 'Light';

  @override
  String get stageRem => 'REM';

  @override
  String get stageAwake => 'Awake';

  @override
  String get stageUnknown => 'Unknown';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get avgSleep => 'Avg. sleep';

  @override
  String get avgSteps => 'Avg. steps';

  @override
  String get avgHeartRate => 'Avg. heart rate';

  @override
  String get restingHeartRate => 'Resting HR';

  @override
  String get deltaDay => 'vs prev day';

  @override
  String get deltaWeek => 'vs last week';

  @override
  String get deltaMonth => 'vs last month';

  @override
  String get viewTodayDetail => 'View today\'s detail';

  @override
  String get sleepDuration => 'Sleep duration';

  @override
  String get summaryHint =>
      'Each data shown in a separate lane on a shared timeline';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionDataSync => 'Data sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing…';

  @override
  String get notSynced => 'Not synced';

  @override
  String lastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get healthConnectLink => 'Health Connect';

  @override
  String get healthConnectLinkSubtitle =>
      'Reads sleep, steps and heart rate (READ only)';

  @override
  String get sectionPrivacy => 'Privacy & security';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataSubtitle =>
      'Erase sleep, steps and heart rate stored on this device';

  @override
  String get cannotDeleteWhileSyncing => 'Cannot delete while syncing';

  @override
  String get sectionInfo => 'Info';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get contact => 'Contact';

  @override
  String get deleteDialogTitle => 'Delete all data';

  @override
  String get deleteDialogContent =>
      'This permanently deletes the sleep, steps and heart rate data stored on this device. This cannot be undone.\n\n(Data in Health Connect is not deleted; it will be re-fetched on the next sync.)';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deletedSnack => 'Local data deleted';

  @override
  String get deleteAbortedSyncing =>
      'Deletion canceled because a sync is in progress';

  @override
  String get statusUnavailableTitle => 'Health Connect is required';

  @override
  String get statusUnavailableMessage =>
      'Health Connect must be installed to read sleep, steps and heart rate.';

  @override
  String get install => 'Install';

  @override
  String get statusPermissionTitle => 'Access to health data is needed';

  @override
  String get statusPermissionMessage =>
      'Read permission in Health Connect is required to show sleep, steps and heart rate.';

  @override
  String get allow => 'Allow';

  @override
  String get statusSyncFailedTitle => 'Sync failed';

  @override
  String get statusSyncFailedMessage => 'Showing locally saved data.';

  @override
  String get retry => 'Retry';

  @override
  String durationHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String durationMin(int m) {
    return '${m}m';
  }

  @override
  String get prevDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get crossTitle => 'Integrated view (sleep × heart rate × steps)';

  @override
  String get crossSubtitle => '24 hours up to wake time. Scroll horizontally.';

  @override
  String get crossEmpty =>
      'No sleep data, so the integrated view is unavailable';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get rationaleTitle => 'About health data use';

  @override
  String rationaleIntro(String app) {
    return '$app reads the following from Health Connect and uses it only to draw charts on this device. No data is ever sent externally.';
  }

  @override
  String get rationaleSleepDesc =>
      'Read to visualize sleep stages (deep / light / REM / awake).';

  @override
  String get rationaleStepsDesc =>
      'Read to visualize steps by time of day and daily / weekly / monthly.';

  @override
  String get rationaleHeartDesc =>
      'Read to visualize heart rate, resting / max, and heart rate during sleep.';

  @override
  String get rationaleHistoryTitle => 'Past data (history)';

  @override
  String get rationaleHistoryDesc =>
      'On first launch, data older than the past 30 days is fetched once to show past trends. No continuous background collection is performed.';

  @override
  String get rationaleSecurity =>
      'Fetched data is encrypted with AES-256 and stored only on this device. No cloud upload or third-party sharing.';

  @override
  String get readPolicy => 'Read privacy policy';

  @override
  String get openPolicyBrowser => 'Open published version in browser';

  @override
  String get openApp => 'Open app';

  @override
  String weekShort(int n) {
    return 'W$n';
  }

  @override
  String get jumpToday => 'Go to today';

  @override
  String get jumpThisMonth => 'Go to this month';

  @override
  String onbWelcomeTitle(String app) {
    return 'Welcome to $app';
  }

  @override
  String get onbWelcomeBody =>
      'Visualize your sleep, steps and heart rate entirely on your device. No data is sent externally.';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbNext => 'Next';

  @override
  String get onbLangBody =>
      'We follow your device language. You can change it anytime in Settings.';

  @override
  String get onbPermTitle => 'Connect Health Connect';

  @override
  String get onbConnect => 'Connect & sync';

  @override
  String get onbSkipSetup => 'Set up later';

  @override
  String get onbSyncing => 'Syncing your data…';

  @override
  String get onbDoneTitle => 'You\'re all set';

  @override
  String get onbDoneBody =>
      'Your data is ready. Explore your trends on the home screen.';

  @override
  String get onbFinish => 'Start';
}
