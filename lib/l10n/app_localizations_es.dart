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

  @override
  String get rationaleTitle => 'Sobre el uso de datos de salud';

  @override
  String rationaleIntro(String app) {
    return '$app lee los siguientes datos de Health Connect y los usa solo para mostrar gráficos en este dispositivo. Ningún dato se envía al exterior.';
  }

  @override
  String get rationaleSleepDesc =>
      'Se lee para visualizar las fases del sueño (profundo / ligero / REM / despierto).';

  @override
  String get rationaleStepsDesc =>
      'Se lee para visualizar los pasos por franja horaria y por día / semana / mes.';

  @override
  String get rationaleHeartDesc =>
      'Se lee para visualizar la frecuencia cardíaca, en reposo / máxima y durante el sueño.';

  @override
  String get rationaleHistoryTitle => 'Datos anteriores (historial)';

  @override
  String get rationaleHistoryDesc =>
      'En el primer inicio, los datos anteriores a los últimos 30 días se obtienen una vez para mostrar tendencias pasadas. No se realiza recopilación continua en segundo plano.';

  @override
  String get rationaleSecurity =>
      'Los datos obtenidos se cifran con AES-256 y se almacenan solo en este dispositivo. Sin subida a la nube ni intercambio con terceros.';

  @override
  String get readPolicy => 'Leer la política de privacidad';

  @override
  String get openPolicyBrowser => 'Abrir la versión publicada en el navegador';

  @override
  String get openApp => 'Abrir la aplicación';

  @override
  String weekShort(int n) {
    return 'Sem $n';
  }

  @override
  String get jumpToday => 'Ir a hoy';

  @override
  String get jumpThisMonth => 'Ir a este mes';

  @override
  String onbWelcomeTitle(String app) {
    return 'Te damos la bienvenida a $app';
  }

  @override
  String get onbWelcomeBody =>
      'Visualiza tu sueño, pasos y frecuencia cardíaca totalmente en tu dispositivo. Ningún dato se envía al exterior.';

  @override
  String get onbStart => 'Empezar';

  @override
  String get onbNext => 'Siguiente';

  @override
  String get onbLangBody =>
      'Seguimos el idioma de tu dispositivo. Puedes cambiarlo cuando quieras en Ajustes.';

  @override
  String get onbPermTitle => 'Conectar Health Connect';

  @override
  String get onbConnect => 'Conectar y sincronizar';

  @override
  String get onbSkipSetup => 'Configurar más tarde';

  @override
  String get onbSyncing => 'Sincronizando tus datos…';

  @override
  String get onbDoneTitle => 'Todo listo';

  @override
  String get onbDoneBody =>
      'Tus datos están listos. Explora tus tendencias en la pantalla de inicio.';

  @override
  String get onbFinish => 'Empezar';

  @override
  String get tutSkip => 'Saltar';

  @override
  String get tutDone => 'Listo';

  @override
  String get tutDateTitle => 'Toca la fecha';

  @override
  String get tutDateBody =>
      'Toca la fecha para ir a un día, semana o mes concreto en el calendario. Los días con datos muestran un punto.';

  @override
  String get tutCardsTitle => 'Tus datos del día';

  @override
  String get tutCardsBody =>
      'Fases del sueño, pasos y frecuencia cardíaca del día seleccionado, además de una vista integrada en un eje de tiempo común.';

  @override
  String get tutTabsTitle => 'Cambiar de pantalla';

  @override
  String get tutTabsBody =>
      'Cambia entre Inicio (detalle del día), Resumen (tendencias día/semana/mes) y Ajustes.';

  @override
  String get appLock => 'Bloqueo de la app';

  @override
  String get appLockSubtitle => 'Requerir biometría o PIN para abrir la app';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get lockReason => 'Autentícate para desbloquear Life On Graph';

  @override
  String get lockUnavailable =>
      'No hay biometría ni PIN configurados en este dispositivo';

  @override
  String get syncReadingSleep => 'Leyendo datos de sueño…';

  @override
  String get syncReadingSteps => 'Leyendo datos de pasos…';

  @override
  String get syncReadingHeart => 'Leyendo datos de frecuencia cardíaca…';

  @override
  String syncRecordsRead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString registros';
  }
}
