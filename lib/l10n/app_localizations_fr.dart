// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabSummary => 'Résumé';

  @override
  String get tabSettings => 'Paramètres';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get sleep => 'Sommeil';

  @override
  String get steps => 'Pas';

  @override
  String get heartRate => 'Fréquence cardiaque';

  @override
  String get sleepStages => 'Phases de sommeil';

  @override
  String get noSleepDataForDay => 'Aucune donnée de sommeil pour ce jour';

  @override
  String get noSleepData => 'Aucune donnée de sommeil';

  @override
  String get noStepsDataForDay => 'Aucune donnée de pas pour ce jour';

  @override
  String get noHeartRateData => 'Aucune donnée de fréquence cardiaque';

  @override
  String stepsValue(String count) {
    return '$count pas';
  }

  @override
  String bpmValue(int value) {
    return '$value bpm';
  }

  @override
  String get resting => 'Repos';

  @override
  String get max => 'Max';

  @override
  String get allDay => 'Journée';

  @override
  String get duringSleep => 'Pendant le sommeil';

  @override
  String get stageDeep => 'Profond';

  @override
  String get stageLight => 'Léger';

  @override
  String get stageRem => 'Paradoxal';

  @override
  String get stageAwake => 'Éveillé';

  @override
  String get stageUnknown => 'Inconnu';

  @override
  String get summaryTitle => 'Résumé';

  @override
  String get periodDay => 'Jour';

  @override
  String get periodWeek => 'Semaine';

  @override
  String get periodMonth => 'Mois';

  @override
  String get avgSleep => 'Sommeil moy.';

  @override
  String get avgSteps => 'Pas moy.';

  @override
  String get avgHeartRate => 'FC moyenne';

  @override
  String get restingHeartRate => 'FC au repos';

  @override
  String get deltaDay => 'vs hier';

  @override
  String get deltaWeek => 'vs sem. dernière';

  @override
  String get deltaMonth => 'vs mois dernier';

  @override
  String get viewTodayDetail => 'Voir le détail du jour';

  @override
  String get sleepDuration => 'Durée de sommeil';

  @override
  String get summaryHint =>
      'Chaque donnée sur sa propre piste, axe temporel commun';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionDataSync => 'Synchronisation';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get syncing => 'Synchronisation…';

  @override
  String get notSynced => 'Non synchronisé';

  @override
  String lastSynced(String time) {
    return 'Dernière synchro : $time';
  }

  @override
  String get healthConnectLink => 'Health Connect';

  @override
  String get healthConnectLinkSubtitle =>
      'Lit le sommeil, les pas et la fréquence cardiaque (lecture seule)';

  @override
  String get sectionPrivacy => 'Confidentialité et sécurité';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get deleteAllDataSubtitle =>
      'Effacer le sommeil, les pas et la fréquence cardiaque de cet appareil';

  @override
  String get cannotDeleteWhileSyncing =>
      'Suppression impossible pendant la synchronisation';

  @override
  String get sectionInfo => 'Informations';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get contact => 'Contact';

  @override
  String get deleteDialogTitle => 'Supprimer toutes les données';

  @override
  String get deleteDialogContent =>
      'Cette action supprime définitivement les données de sommeil, de pas et de fréquence cardiaque stockées sur cet appareil. Action irréversible.\n\n(Les données dans Health Connect ne sont pas supprimées ; elles seront récupérées à la prochaine synchronisation.)';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get deletedSnack => 'Données locales supprimées';

  @override
  String get deleteAbortedSyncing =>
      'Suppression annulée car une synchronisation est en cours';

  @override
  String get statusUnavailableTitle => 'Health Connect est requis';

  @override
  String get statusUnavailableMessage =>
      'Health Connect doit être installé pour lire le sommeil, les pas et la fréquence cardiaque.';

  @override
  String get install => 'Installer';

  @override
  String get statusPermissionTitle => 'Accès aux données de santé requis';

  @override
  String get statusPermissionMessage =>
      'L\'autorisation de lecture dans Health Connect est nécessaire pour afficher le sommeil, les pas et la fréquence cardiaque.';

  @override
  String get allow => 'Autoriser';

  @override
  String get statusSyncFailedTitle => 'Échec de la synchronisation';

  @override
  String get statusSyncFailedMessage =>
      'Affichage des données enregistrées localement.';

  @override
  String get retry => 'Réessayer';

  @override
  String durationHm(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String get prevDay => 'Jour précédent';

  @override
  String get nextDay => 'Jour suivant';

  @override
  String get crossTitle => 'Vue intégrée (sommeil × FC × pas)';

  @override
  String get crossSubtitle => '24 h jusqu\'au réveil. Défilez horizontalement.';

  @override
  String get crossEmpty =>
      'Aucune donnée de sommeil : vue intégrée indisponible';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Paramètre système';

  @override
  String get rationaleTitle =>
      'À propos de l\'utilisation des données de santé';

  @override
  String rationaleIntro(String app) {
    return '$app lit les données suivantes depuis Health Connect et les utilise uniquement pour afficher des graphiques sur cet appareil. Aucune donnée n\'est envoyée à l\'extérieur.';
  }

  @override
  String get rationaleSleepDesc =>
      'Lu pour visualiser les phases de sommeil (profond / léger / paradoxal / éveillé).';

  @override
  String get rationaleStepsDesc =>
      'Lu pour visualiser les pas par heure et par jour / semaine / mois.';

  @override
  String get rationaleHeartDesc =>
      'Lu pour visualiser la fréquence cardiaque, au repos / maximale, et pendant le sommeil.';

  @override
  String get rationaleHistoryTitle => 'Données passées (historique)';

  @override
  String get rationaleHistoryDesc =>
      'Au premier lancement, les données antérieures aux 30 derniers jours sont récupérées une fois pour afficher les tendances passées. Aucune collecte continue en arrière-plan n\'est effectuée.';

  @override
  String get rationaleSecurity =>
      'Les données récupérées sont chiffrées en AES-256 et stockées uniquement sur cet appareil. Aucun envoi vers le cloud ni partage avec des tiers.';

  @override
  String get readPolicy => 'Lire la politique de confidentialité';

  @override
  String get openPolicyBrowser =>
      'Ouvrir la version publiée dans le navigateur';

  @override
  String get openApp => 'Ouvrir l\'application';

  @override
  String weekShort(int n) {
    return 'S$n';
  }

  @override
  String get jumpToday => 'Aller à aujourd\'hui';

  @override
  String get jumpThisMonth => 'Aller à ce mois';

  @override
  String onbWelcomeTitle(String app) {
    return 'Bienvenue dans $app';
  }

  @override
  String get onbWelcomeBody =>
      'Visualisez votre sommeil, vos pas et votre fréquence cardiaque entièrement sur votre appareil. Aucune donnée n\'est envoyée à l\'extérieur.';

  @override
  String get onbStart => 'Commencer';

  @override
  String get onbNext => 'Suivant';

  @override
  String get onbLangBody =>
      'Nous suivons la langue de votre appareil. Vous pouvez la changer à tout moment dans les paramètres.';

  @override
  String get onbPermTitle => 'Connecter Health Connect';

  @override
  String get onbConnect => 'Connecter et synchroniser';

  @override
  String get onbSkipSetup => 'Configurer plus tard';

  @override
  String get onbSyncing => 'Synchronisation de vos données…';

  @override
  String get onbDoneTitle => 'Tout est prêt';

  @override
  String get onbDoneBody =>
      'Vos données sont prêtes. Découvrez vos tendances sur l\'écran d\'accueil.';

  @override
  String get onbFinish => 'Démarrer';

  @override
  String get tutSkip => 'Passer';

  @override
  String get tutDone => 'Terminé';

  @override
  String get tutDateTitle => 'Appuyez sur la date';

  @override
  String get tutDateBody =>
      'Appuyez sur la date pour aller à un jour, une semaine ou un mois précis dans le calendrier. Les jours avec données affichent un point.';

  @override
  String get tutCardsTitle => 'Vos données du jour';

  @override
  String get tutCardsBody =>
      'Phases de sommeil, pas et fréquence cardiaque du jour sélectionné, avec une vue intégrée sur un axe temporel commun.';

  @override
  String get tutTabsTitle => 'Changer d\'écran';

  @override
  String get tutTabsBody =>
      'Basculez entre Accueil (détail du jour), Résumé (tendances jour/semaine/mois) et Paramètres.';

  @override
  String get appLock => 'Verrouillage de l\'app';

  @override
  String get appLockSubtitle =>
      'Exiger la biométrie ou le code pour ouvrir l\'app';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get lockReason => 'Authentifiez-vous pour déverrouiller Life On Graph';

  @override
  String get lockUnavailable =>
      'Aucune biométrie ni code n\'est configuré sur cet appareil';

  @override
  String get syncReadingSleep => 'Lecture des données de sommeil…';

  @override
  String get syncReadingSteps => 'Lecture des données de pas…';

  @override
  String get syncReadingHeart => 'Lecture des données de fréquence cardiaque…';

  @override
  String syncRecordsRead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString enregistrements';
  }

  @override
  String get syncInitialNote =>
      'La première synchronisation charge les 3 derniers mois. Les données plus anciennes peuvent être chargées à tout moment via « Recharger toutes les données » dans les Réglages.';

  @override
  String get reloadAll => 'Recharger toutes les données';

  @override
  String get reloadAllSubtitle => 'Récupère l\'historique plus ancien';

  @override
  String get reloadAllStarted => 'Rechargement de toutes les données…';
}
