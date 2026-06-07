// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get tabHome => 'Start';

  @override
  String get tabSummary => 'Übersicht';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get today => 'Heute';

  @override
  String get sleep => 'Schlaf';

  @override
  String get steps => 'Schritte';

  @override
  String get heartRate => 'Herzfrequenz';

  @override
  String get sleepStages => 'Schlafphasen';

  @override
  String get noSleepDataForDay => 'Keine Schlafdaten für diesen Tag';

  @override
  String get noSleepData => 'Keine Schlafdaten';

  @override
  String get noStepsDataForDay => 'Keine Schrittdaten für diesen Tag';

  @override
  String get noHeartRateData => 'Keine Herzfrequenzdaten';

  @override
  String stepsValue(String count) {
    return '$count Schritte';
  }

  @override
  String bpmValue(int value) {
    return '$value bpm';
  }

  @override
  String get resting => 'Ruhe';

  @override
  String get max => 'Max';

  @override
  String get allDay => 'Ganzer Tag';

  @override
  String get duringSleep => 'Im Schlaf';

  @override
  String get stageDeep => 'Tief';

  @override
  String get stageLight => 'Leicht';

  @override
  String get stageRem => 'REM';

  @override
  String get stageAwake => 'Wach';

  @override
  String get stageUnknown => 'Unbekannt';

  @override
  String get summaryTitle => 'Übersicht';

  @override
  String get periodDay => 'Tag';

  @override
  String get periodWeek => 'Woche';

  @override
  String get periodMonth => 'Monat';

  @override
  String get avgSleep => 'Ø Schlaf';

  @override
  String get avgSteps => 'Ø Schritte';

  @override
  String get avgHeartRate => 'Ø Herzfrequenz';

  @override
  String get restingHeartRate => 'Ruhe-HF';

  @override
  String get deltaDay => 'vs. Vortag';

  @override
  String get deltaWeek => 'vs. Vorwoche';

  @override
  String get deltaMonth => 'vs. Vormonat';

  @override
  String get viewTodayDetail => 'Heutige Details anzeigen';

  @override
  String get sleepDuration => 'Schlafdauer';

  @override
  String get summaryHint =>
      'Jede Datenart in einer eigenen Spur auf gemeinsamer Zeitachse';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get sectionDataSync => 'Datensynchronisierung';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncing => 'Synchronisierung…';

  @override
  String get notSynced => 'Nicht synchronisiert';

  @override
  String lastSynced(String time) {
    return 'Zuletzt synchronisiert: $time';
  }

  @override
  String get healthConnectLink => 'Health Connect';

  @override
  String get healthConnectLinkSubtitle =>
      'Liest Schlaf, Schritte und Herzfrequenz (nur Lesen)';

  @override
  String get sectionPrivacy => 'Datenschutz & Sicherheit';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllDataSubtitle =>
      'Auf dem Gerät gespeicherte Schlaf-, Schritt- und Herzfrequenzdaten löschen';

  @override
  String get cannotDeleteWhileSyncing =>
      'Löschen während der Synchronisierung nicht möglich';

  @override
  String get sectionInfo => 'Informationen';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get contact => 'Kontakt';

  @override
  String get deleteDialogTitle => 'Alle Daten löschen';

  @override
  String get deleteDialogContent =>
      'Dadurch werden die auf diesem Gerät gespeicherten Schlaf-, Schritt- und Herzfrequenzdaten dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.\n\n(Daten in Health Connect werden nicht gelöscht; sie werden bei der nächsten Synchronisierung erneut abgerufen.)';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get deletedSnack => 'Lokale Daten gelöscht';

  @override
  String get deleteAbortedSyncing =>
      'Löschen abgebrochen, da eine Synchronisierung läuft';

  @override
  String get statusUnavailableTitle => 'Health Connect erforderlich';

  @override
  String get statusUnavailableMessage =>
      'Health Connect muss installiert sein, um Schlaf, Schritte und Herzfrequenz zu lesen.';

  @override
  String get install => 'Installieren';

  @override
  String get statusPermissionTitle =>
      'Zugriff auf Gesundheitsdaten erforderlich';

  @override
  String get statusPermissionMessage =>
      'Zum Anzeigen von Schlaf, Schritten und Herzfrequenz ist die Leseberechtigung in Health Connect erforderlich.';

  @override
  String get allow => 'Zulassen';

  @override
  String get statusSyncFailedTitle => 'Synchronisierung fehlgeschlagen';

  @override
  String get statusSyncFailedMessage =>
      'Lokal gespeicherte Daten werden angezeigt.';

  @override
  String get retry => 'Wiederholen';

  @override
  String durationHm(int h, int m) {
    return '$h Std. $m Min.';
  }

  @override
  String durationMin(int m) {
    return '$m Min.';
  }

  @override
  String get prevDay => 'Vorheriger Tag';

  @override
  String get nextDay => 'Nächster Tag';

  @override
  String get crossTitle => 'Integrierte Ansicht (Schlaf × HF × Schritte)';

  @override
  String get crossSubtitle => '24 Std. bis zum Aufwachen. Horizontal scrollen.';

  @override
  String get crossEmpty =>
      'Keine Schlafdaten – integrierte Ansicht nicht verfügbar';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get rationaleTitle => 'Über die Nutzung von Gesundheitsdaten';

  @override
  String rationaleIntro(String app) {
    return '$app liest die folgenden Daten aus Health Connect und verwendet sie nur, um Diagramme auf diesem Gerät anzuzeigen. Es werden keine Daten extern gesendet.';
  }

  @override
  String get rationaleSleepDesc =>
      'Wird gelesen, um Schlafphasen (Tief / Leicht / REM / Wach) darzustellen.';

  @override
  String get rationaleStepsDesc =>
      'Wird gelesen, um Schritte nach Tageszeit und täglich / wöchentlich / monatlich darzustellen.';

  @override
  String get rationaleHeartDesc =>
      'Wird gelesen, um Herzfrequenz, Ruhe-/Maximalwert und Herzfrequenz im Schlaf darzustellen.';

  @override
  String get rationaleHistoryTitle => 'Vergangene Daten (Verlauf)';

  @override
  String get rationaleHistoryDesc =>
      'Beim ersten Start werden Daten, die älter als die letzten 30 Tage sind, einmalig abgerufen, um vergangene Trends anzuzeigen. Es erfolgt keine fortlaufende Hintergrunderfassung.';

  @override
  String get rationaleSecurity =>
      'Abgerufene Daten werden mit AES-256 verschlüsselt und nur auf diesem Gerät gespeichert. Kein Cloud-Upload und keine Weitergabe an Dritte.';

  @override
  String get readPolicy => 'Datenschutzerklärung lesen';

  @override
  String get openPolicyBrowser => 'Veröffentlichte Version im Browser öffnen';

  @override
  String get openApp => 'App öffnen';

  @override
  String weekShort(int n) {
    return 'W$n';
  }

  @override
  String get jumpToday => 'Zu heute';

  @override
  String get jumpThisMonth => 'Zu diesem Monat';

  @override
  String onbWelcomeTitle(String app) {
    return 'Willkommen bei $app';
  }

  @override
  String get onbWelcomeBody =>
      'Visualisiere Schlaf, Schritte und Herzfrequenz ausschließlich auf deinem Gerät. Es werden keine Daten extern gesendet.';

  @override
  String get onbStart => 'Loslegen';

  @override
  String get onbNext => 'Weiter';

  @override
  String get onbLangBody =>
      'Wir folgen deiner Gerätesprache. Du kannst sie jederzeit in den Einstellungen ändern.';

  @override
  String get onbPermTitle => 'Health Connect verbinden';

  @override
  String get onbConnect => 'Verbinden & synchronisieren';

  @override
  String get onbSkipSetup => 'Später einrichten';

  @override
  String get onbSyncing => 'Deine Daten werden synchronisiert…';

  @override
  String get onbDoneTitle => 'Alles bereit';

  @override
  String get onbDoneBody =>
      'Deine Daten sind bereit. Entdecke deine Trends auf dem Startbildschirm.';

  @override
  String get onbFinish => 'Starten';
}
