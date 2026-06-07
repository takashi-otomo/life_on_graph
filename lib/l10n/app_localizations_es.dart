// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabSummary => 'Resumen';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get today => 'Hoy';

  @override
  String get sleep => 'Sueño';

  @override
  String get steps => 'Pasos';

  @override
  String get heartRate => 'Frecuencia cardíaca';

  @override
  String get sleepStages => 'Fases del sueño';

  @override
  String get noSleepDataForDay => 'Sin datos de sueño para este día';

  @override
  String get noSleepData => 'Sin datos de sueño';

  @override
  String get noStepsDataForDay => 'Sin datos de pasos para este día';

  @override
  String get noHeartRateData => 'Sin datos de frecuencia cardíaca';

  @override
  String stepsValue(String count) {
    return '$count pasos';
  }

  @override
  String bpmValue(int value) {
    return '$value bpm';
  }

  @override
  String get resting => 'Reposo';

  @override
  String get max => 'Máx';

  @override
  String get allDay => 'Todo el día';

  @override
  String get duringSleep => 'Durante el sueño';

  @override
  String get stageDeep => 'Profundo';

  @override
  String get stageLight => 'Ligero';

  @override
  String get stageRem => 'REM';

  @override
  String get stageAwake => 'Despierto';

  @override
  String get stageUnknown => 'Desconocido';

  @override
  String get summaryTitle => 'Resumen';

  @override
  String get periodDay => 'Día';

  @override
  String get periodWeek => 'Semana';

  @override
  String get periodMonth => 'Mes';

  @override
  String get avgSleep => 'Sueño med.';

  @override
  String get avgSteps => 'Pasos med.';

  @override
  String get avgHeartRate => 'FC media';

  @override
  String get restingHeartRate => 'FC en reposo';

  @override
  String get deltaDay => 'vs. ayer';

  @override
  String get deltaWeek => 'vs. semana pasada';

  @override
  String get deltaMonth => 'vs. mes pasado';

  @override
  String get viewTodayDetail => 'Ver detalle de hoy';

  @override
  String get sleepDuration => 'Duración del sueño';

  @override
  String get summaryHint =>
      'Cada dato en su propia franja sobre un eje de tiempo común';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionDataSync => 'Sincronización';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String get notSynced => 'Sin sincronizar';

  @override
  String lastSynced(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get healthConnectLink => 'Health Connect';

  @override
  String get healthConnectLinkSubtitle =>
      'Lee sueño, pasos y frecuencia cardíaca (solo lectura)';

  @override
  String get sectionPrivacy => 'Privacidad y seguridad';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataSubtitle =>
      'Borrar el sueño, los pasos y la frecuencia cardíaca de este dispositivo';

  @override
  String get cannotDeleteWhileSyncing =>
      'No se puede eliminar durante la sincronización';

  @override
  String get sectionInfo => 'Información';

  @override
  String get version => 'Versión';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get contact => 'Contacto';

  @override
  String get deleteDialogTitle => 'Eliminar todos los datos';

  @override
  String get deleteDialogContent =>
      'Esto elimina de forma permanente los datos de sueño, pasos y frecuencia cardíaca almacenados en este dispositivo. No se puede deshacer.\n\n(Los datos en Health Connect no se eliminan; se volverán a obtener en la próxima sincronización.)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deletedSnack => 'Datos locales eliminados';

  @override
  String get deleteAbortedSyncing =>
      'Eliminación cancelada porque hay una sincronización en curso';

  @override
  String get statusUnavailableTitle => 'Se requiere Health Connect';

  @override
  String get statusUnavailableMessage =>
      'Health Connect debe estar instalado para leer el sueño, los pasos y la frecuencia cardíaca.';

  @override
  String get install => 'Instalar';

  @override
  String get statusPermissionTitle => 'Se necesita acceso a los datos de salud';

  @override
  String get statusPermissionMessage =>
      'Se requiere permiso de lectura en Health Connect para mostrar el sueño, los pasos y la frecuencia cardíaca.';

  @override
  String get allow => 'Permitir';

  @override
  String get statusSyncFailedTitle => 'Error de sincronización';

  @override
  String get statusSyncFailedMessage => 'Mostrando datos guardados localmente.';

  @override
  String get retry => 'Reintentar';

  @override
  String durationHm(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String get prevDay => 'Día anterior';

  @override
  String get nextDay => 'Día siguiente';

  @override
  String get crossTitle => 'Vista integrada (sueño × FC × pasos)';

  @override
  String get crossSubtitle => '24 h hasta despertar. Desplázate en horizontal.';

  @override
  String get crossEmpty => 'Sin datos de sueño; vista integrada no disponible';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';
}
