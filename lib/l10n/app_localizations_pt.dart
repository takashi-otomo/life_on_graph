// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get tabHome => 'Início';

  @override
  String get tabSummary => 'Resumo';

  @override
  String get tabSettings => 'Configurações';

  @override
  String get today => 'Hoje';

  @override
  String get sleep => 'Sono';

  @override
  String get steps => 'Passos';

  @override
  String get heartRate => 'Frequência cardíaca';

  @override
  String get sleepStages => 'Fases do sono';

  @override
  String get noSleepDataForDay => 'Sem dados de sono neste dia';

  @override
  String get noSleepData => 'Sem dados de sono';

  @override
  String get noStepsDataForDay => 'Sem dados de passos neste dia';

  @override
  String get noHeartRateData => 'Sem dados de frequência cardíaca';

  @override
  String stepsValue(String count) {
    return '$count passos';
  }

  @override
  String bpmValue(int value) {
    return '$value bpm';
  }

  @override
  String get resting => 'Repouso';

  @override
  String get max => 'Máx';

  @override
  String get allDay => 'Dia todo';

  @override
  String get duringSleep => 'Durante o sono';

  @override
  String get stageDeep => 'Profundo';

  @override
  String get stageLight => 'Leve';

  @override
  String get stageRem => 'REM';

  @override
  String get stageAwake => 'Acordado';

  @override
  String get stageUnknown => 'Desconhecido';

  @override
  String get summaryTitle => 'Resumo';

  @override
  String get periodDay => 'Dia';

  @override
  String get periodWeek => 'Semana';

  @override
  String get periodMonth => 'Mês';

  @override
  String get avgSleep => 'Sono méd.';

  @override
  String get avgSteps => 'Passos méd.';

  @override
  String get avgHeartRate => 'FC média';

  @override
  String get restingHeartRate => 'FC em repouso';

  @override
  String get deltaDay => 'vs. ontem';

  @override
  String get deltaWeek => 'vs. semana passada';

  @override
  String get deltaMonth => 'vs. mês passado';

  @override
  String get viewTodayDetail => 'Ver detalhes de hoje';

  @override
  String get sleepDuration => 'Duração do sono';

  @override
  String get summaryHint =>
      'Cada dado em uma faixa separada no mesmo eixo de tempo';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get sectionDataSync => 'Sincronização';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String get notSynced => 'Não sincronizado';

  @override
  String lastSynced(String time) {
    return 'Última sincronização: $time';
  }

  @override
  String get healthConnectLink => 'Health Connect';

  @override
  String get healthConnectLinkSubtitle =>
      'Lê sono, passos e frequência cardíaca (somente leitura)';

  @override
  String get sectionPrivacy => 'Privacidade e segurança';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get deleteAllData => 'Excluir todos os dados';

  @override
  String get deleteAllDataSubtitle =>
      'Apagar sono, passos e frequência cardíaca armazenados neste dispositivo';

  @override
  String get cannotDeleteWhileSyncing =>
      'Não é possível excluir durante a sincronização';

  @override
  String get sectionInfo => 'Informações';

  @override
  String get version => 'Versão';

  @override
  String get openSourceLicenses => 'Licenças de código aberto';

  @override
  String get contact => 'Contato';

  @override
  String get deleteDialogTitle => 'Excluir todos os dados';

  @override
  String get deleteDialogContent =>
      'Isso exclui permanentemente os dados de sono, passos e frequência cardíaca armazenados neste dispositivo. Não pode ser desfeito.\n\n(Os dados no Health Connect não são excluídos; serão obtidos novamente na próxima sincronização.)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get deletedSnack => 'Dados locais excluídos';

  @override
  String get deleteAbortedSyncing =>
      'Exclusão cancelada porque há uma sincronização em andamento';

  @override
  String get statusUnavailableTitle => 'O Health Connect é necessário';

  @override
  String get statusUnavailableMessage =>
      'O Health Connect precisa estar instalado para ler sono, passos e frequência cardíaca.';

  @override
  String get install => 'Instalar';

  @override
  String get statusPermissionTitle => 'Acesso aos dados de saúde necessário';

  @override
  String get statusPermissionMessage =>
      'A permissão de leitura no Health Connect é necessária para exibir sono, passos e frequência cardíaca.';

  @override
  String get allow => 'Permitir';

  @override
  String get statusSyncFailedTitle => 'Falha na sincronização';

  @override
  String get statusSyncFailedMessage => 'Exibindo dados salvos localmente.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String durationHm(int h, int m) {
    return '${h}h ${m}min';
  }

  @override
  String durationMin(int m) {
    return '${m}min';
  }

  @override
  String get prevDay => 'Dia anterior';

  @override
  String get nextDay => 'Próximo dia';

  @override
  String get crossTitle => 'Visão integrada (sono × FC × passos)';

  @override
  String get crossSubtitle => '24h até acordar. Role na horizontal.';

  @override
  String get crossEmpty => 'Sem dados de sono; visão integrada indisponível';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get rationaleTitle => 'Sobre o uso de dados de saúde';

  @override
  String rationaleIntro(String app) {
    return 'O $app lê os seguintes dados do Health Connect e os usa apenas para exibir gráficos neste dispositivo. Nenhum dado é enviado para fora.';
  }

  @override
  String get rationaleSleepDesc =>
      'Lido para visualizar as fases do sono (profundo / leve / REM / acordado).';

  @override
  String get rationaleStepsDesc =>
      'Lido para visualizar os passos por hora do dia e por dia / semana / mês.';

  @override
  String get rationaleHeartDesc =>
      'Lido para visualizar a frequência cardíaca, em repouso / máxima e durante o sono.';

  @override
  String get rationaleHistoryTitle => 'Dados anteriores (histórico)';

  @override
  String get rationaleHistoryDesc =>
      'No primeiro uso, os dados anteriores aos últimos 30 dias são obtidos uma vez para mostrar tendências passadas. Nenhuma coleta contínua em segundo plano é realizada.';

  @override
  String get rationaleSecurity =>
      'Os dados obtidos são criptografados com AES-256 e armazenados apenas neste dispositivo. Sem envio para a nuvem nem compartilhamento com terceiros.';

  @override
  String get readPolicy => 'Ler a política de privacidade';

  @override
  String get openPolicyBrowser => 'Abrir versão publicada no navegador';

  @override
  String get openApp => 'Abrir o aplicativo';

  @override
  String weekShort(int n) {
    return 'Sem $n';
  }

  @override
  String get jumpToday => 'Ir para hoje';

  @override
  String get jumpThisMonth => 'Ir para este mês';

  @override
  String onbWelcomeTitle(String app) {
    return 'Bem-vindo ao $app';
  }

  @override
  String get onbWelcomeBody =>
      'Visualize seu sono, passos e frequência cardíaca totalmente no seu dispositivo. Nenhum dado é enviado para fora.';

  @override
  String get onbStart => 'Começar';

  @override
  String get onbNext => 'Avançar';

  @override
  String get onbLangBody =>
      'Seguimos o idioma do seu dispositivo. Você pode alterá-lo a qualquer momento nas configurações.';

  @override
  String get onbPermTitle => 'Conectar o Health Connect';

  @override
  String get onbConnect => 'Conectar e sincronizar';

  @override
  String get onbSkipSetup => 'Configurar depois';

  @override
  String get onbSyncing => 'Sincronizando seus dados…';

  @override
  String get onbDoneTitle => 'Tudo pronto';

  @override
  String get onbDoneBody =>
      'Seus dados estão prontos. Veja suas tendências na tela inicial.';

  @override
  String get onbFinish => 'Iniciar';

  @override
  String get tutSkip => 'Pular';

  @override
  String get tutDone => 'Concluir';

  @override
  String get tutDateTitle => 'Toque na data';

  @override
  String get tutDateBody =>
      'Toque na data para ir a um dia, semana ou mês específico no calendário. Dias com dados mostram um ponto.';

  @override
  String get tutCardsTitle => 'Seus dados do dia';

  @override
  String get tutCardsBody =>
      'Fases do sono, passos e frequência cardíaca do dia selecionado, além de uma visão integrada no mesmo eixo de tempo.';

  @override
  String get tutTabsTitle => 'Alternar telas';

  @override
  String get tutTabsBody =>
      'Alterne entre Início (detalhe do dia), Resumo (tendências dia/semana/mês) e Configurações.';

  @override
  String get appLock => 'Bloqueio do app';

  @override
  String get appLockSubtitle => 'Exigir biometria ou PIN para abrir o app';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get lockReason => 'Autentique-se para desbloquear o Life On Graph';

  @override
  String get lockUnavailable =>
      'Nenhuma biometria ou PIN está configurado neste dispositivo';

  @override
  String get syncReadingSleep => 'Lendo dados de sono…';

  @override
  String get syncReadingSteps => 'Lendo dados de passos…';

  @override
  String get syncReadingHeart => 'Lendo dados de frequência cardíaca…';

  @override
  String syncRecordsRead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString registros';
  }

  @override
  String get syncInitialNote =>
      'A primeira sincronização carrega os últimos 3 meses. Dados mais antigos podem ser carregados a qualquer momento em “Recarregar todos os dados” nas Configurações.';

  @override
  String get reloadAll => 'Recarregar todos os dados';

  @override
  String get reloadAllSubtitle => 'Busca o histórico mais antigo';

  @override
  String get reloadAllStarted => 'Recarregando todos os dados…';
}
