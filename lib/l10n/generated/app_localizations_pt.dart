// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'My Torrent';

  @override
  String get addTorrent => 'Adicionar torrent';

  @override
  String get addTorrentDescription =>
      'Cole um magnet, URL .torrent ou escolha um arquivo local.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get chooseTorrentFile => 'Escolher arquivo .torrent';

  @override
  String get prepareTorrentFailed => 'Não foi possível preparar o torrent';

  @override
  String get close => 'Fechar';

  @override
  String get magnetLinkFound => 'Link magnet encontrado';

  @override
  String get torrentFileFound => 'Arquivo .torrent encontrado';

  @override
  String get magnetDetected => 'Detectado na área de transferência.';

  @override
  String get torrentFileDetected => 'Detectado na pasta Downloads do Windows.';

  @override
  String get ignore => 'Ignorar';

  @override
  String get import => 'Importar';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Configurações';

  @override
  String get engineConnected => 'Motor conectado';

  @override
  String activeDownloads(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads ativos',
      one: '1 download ativo',
      zero: 'Nenhum download ativo',
    );
    return '$_temp0';
  }

  @override
  String get downloadsIntro => 'Acompanhe e gerencie seus torrents.';

  @override
  String get downloading => 'Baixando';

  @override
  String get paused => 'Pausados';

  @override
  String get completed => 'Concluídos';

  @override
  String get noDownloads => 'Nenhum download ainda.';

  @override
  String get tableName => 'NOME';

  @override
  String get tableProgress => 'PROGRESSO';

  @override
  String get tableSpeed => 'VELOCIDADE';

  @override
  String get tableStatus => 'STATUS';

  @override
  String get tableActions => 'AÇÕES';

  @override
  String get statusError => 'ERRO';

  @override
  String get statusCompleted => 'CONCLUÍDO';

  @override
  String get statusPaused => 'PAUSADO';

  @override
  String get statusDownloading => 'BAIXANDO';

  @override
  String get removeDownload => 'Remover download?';

  @override
  String removeDownloadDescription(String name) {
    return '\"$name\" será removido da lista.';
  }

  @override
  String get keepFiles => 'Manter arquivos';

  @override
  String get deleteFiles => 'Apagar arquivos';

  @override
  String get selectFiles => 'Selecionar arquivos';

  @override
  String torrentFilesFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos encontrados no torrent.',
      one: '1 arquivo encontrado no torrent.',
      zero: 'Nenhum arquivo encontrado no torrent.',
    );
    return '$_temp0';
  }

  @override
  String get starting => 'Iniciando...';

  @override
  String get startDownload => 'Iniciar download';

  @override
  String selectedFiles(num selected, num total) {
    return '$selected de $total arquivos selecionados';
  }

  @override
  String get baseFolder => 'PASTA BASE';

  @override
  String get downloadFolder => 'NOME DA PASTA';

  @override
  String get limitsMustBePositive => 'Os limites devem ser maiores que zero.';

  @override
  String get settingsSaved => 'Configurações salvas.';

  @override
  String restartFailed(String error) {
    return 'Não foi possível reiniciar o aplicativo: $error';
  }

  @override
  String get restartToApply => 'Reiniciar para aplicar?';

  @override
  String get restartDescription =>
      'Os downloads ativos serão pausados, o app será reiniciado e eles serão retomados automaticamente.';

  @override
  String get restartNow => 'Reiniciar agora';

  @override
  String get settingsIntro =>
      'Controle como seus torrents são baixados e armazenados.';

  @override
  String get downloadLocation => 'Local de download';

  @override
  String get downloadLocationDescription =>
      'Este diretório será usado para novos downloads.';

  @override
  String get choose => 'Escolher';

  @override
  String get speedLimits => 'Limites de velocidade';

  @override
  String get speedLimitsDescription =>
      'Deixe em branco para não limitar a velocidade global.';

  @override
  String get maximumDownload => 'Download máximo (MB/s)';

  @override
  String get maximumUpload => 'Upload máximo (MB/s)';

  @override
  String get unlimited => 'Sem limite';

  @override
  String get peerDiscovery => 'Descoberta de pares';

  @override
  String get peerDiscoveryDescription =>
      'Defina como o app encontra trackers e pares para novos torrents.';

  @override
  String get useDht => 'Usar DHT';

  @override
  String get useDhtDescription =>
      'Encontra pares na rede pública descentralizada. Pode conectar a IPs desconhecidos.';

  @override
  String get fetchPublicTrackers => 'Buscar trackers públicos';

  @override
  String get fetchPublicTrackersDescription =>
      'Baixa uma lista pública ao reiniciar. Salvar esta alteração pausa e retoma seus downloads.';

  @override
  String get behavior => 'Comportamento';

  @override
  String get behaviorDescription =>
      'As transferências continuam enquanto o app estiver na bandeja.';

  @override
  String get restoreDownloads => 'Restaurar downloads ao iniciar';

  @override
  String get notifyOnComplete => 'Notificar ao concluir download';

  @override
  String get downloadCompletedNotification => 'Download concluído';

  @override
  String get notifications => 'Notificações';

  @override
  String get notificationsDescription =>
      'Escolha quando o My Torrent deve chamar sua atenção.';

  @override
  String get soundOnImport => 'Som ao detectar magnet ou .torrent';

  @override
  String get soundOnComplete => 'Som ao concluir download';

  @override
  String get automaticDetection => 'Detecção automática';

  @override
  String get automaticDetectionDescription =>
      'Procure novos itens para importar sem abrir o aplicativo.';

  @override
  String get detectMagnetLinks =>
      'Detectar links magnet na área de transferência';

  @override
  String get detectTorrentFiles => 'Detectar arquivos .torrent em Downloads';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription => 'Escolha o idioma usado pelo aplicativo.';

  @override
  String get portugueseBrazil => 'Português (Brasil)';

  @override
  String get english => 'English';

  @override
  String get saveSettings => 'Salvar configurações';

  @override
  String get trayOpen => 'Abrir My Torrent';

  @override
  String get trayExit => 'Encerrar';

  @override
  String get errorSourceRequired =>
      'Informe um link magnet, URL ou arquivo .torrent.';

  @override
  String get errorSourceInvalid =>
      'Use um magnet, uma URL HTTP(S) ou um arquivo .torrent existente.';

  @override
  String get errorNoSelectableFiles =>
      'O torrent não contém arquivos selecionáveis.';

  @override
  String get errorMetadataTimeout =>
      'Não foi possível obter os metadados do torrent a tempo.';

  @override
  String errorHttpStatus(int statusCode) {
    return 'A URL retornou HTTP $statusCode.';
  }

  @override
  String get errorTorrentFileTooLarge => 'O arquivo .torrent excede 10 MB.';

  @override
  String get errorFileSelectionRequired =>
      'Selecione ao menos um arquivo para iniciar o download.';

  @override
  String get errorDestinationNotFound => 'A pasta de destino não existe.';

  @override
  String get errorDownloadFolderInvalid => 'Informe um nome de pasta válido.';

  @override
  String get errorDownloadFolderConflict =>
      'A pasta escolhida já contém arquivos.';

  @override
  String get errorDownloadDirectoryNotFound =>
      'A pasta de download não existe.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'My Torrent';

  @override
  String get addTorrent => 'Adicionar torrent';

  @override
  String get addTorrentDescription =>
      'Cole um magnet, URL .torrent ou escolha um arquivo local.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get chooseTorrentFile => 'Escolher arquivo .torrent';

  @override
  String get prepareTorrentFailed => 'Não foi possível preparar o torrent';

  @override
  String get close => 'Fechar';

  @override
  String get magnetLinkFound => 'Link magnet encontrado';

  @override
  String get torrentFileFound => 'Arquivo .torrent encontrado';

  @override
  String get magnetDetected => 'Detectado na área de transferência.';

  @override
  String get torrentFileDetected => 'Detectado na pasta Downloads do Windows.';

  @override
  String get ignore => 'Ignorar';

  @override
  String get import => 'Importar';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Configurações';

  @override
  String get engineConnected => 'Motor conectado';

  @override
  String activeDownloads(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads ativos',
      one: '1 download ativo',
      zero: 'Nenhum download ativo',
    );
    return '$_temp0';
  }

  @override
  String get downloadsIntro => 'Acompanhe e gerencie seus torrents.';

  @override
  String get downloading => 'Baixando';

  @override
  String get paused => 'Pausados';

  @override
  String get completed => 'Concluídos';

  @override
  String get noDownloads => 'Nenhum download ainda.';

  @override
  String get tableName => 'NOME';

  @override
  String get tableProgress => 'PROGRESSO';

  @override
  String get tableSpeed => 'VELOCIDADE';

  @override
  String get tableStatus => 'STATUS';

  @override
  String get tableActions => 'AÇÕES';

  @override
  String get statusError => 'ERRO';

  @override
  String get statusCompleted => 'CONCLUÍDO';

  @override
  String get statusPaused => 'PAUSADO';

  @override
  String get statusDownloading => 'BAIXANDO';

  @override
  String get removeDownload => 'Remover download?';

  @override
  String removeDownloadDescription(String name) {
    return '\"$name\" será removido da lista.';
  }

  @override
  String get keepFiles => 'Manter arquivos';

  @override
  String get deleteFiles => 'Apagar arquivos';

  @override
  String get selectFiles => 'Selecionar arquivos';

  @override
  String torrentFilesFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos encontrados no torrent.',
      one: '1 arquivo encontrado no torrent.',
      zero: 'Nenhum arquivo encontrado no torrent.',
    );
    return '$_temp0';
  }

  @override
  String get starting => 'Iniciando...';

  @override
  String get startDownload => 'Iniciar download';

  @override
  String selectedFiles(num selected, num total) {
    return '$selected de $total arquivos selecionados';
  }

  @override
  String get baseFolder => 'PASTA BASE';

  @override
  String get downloadFolder => 'NOME DA PASTA';

  @override
  String get limitsMustBePositive => 'Os limites devem ser maiores que zero.';

  @override
  String get settingsSaved => 'Configurações salvas.';

  @override
  String restartFailed(String error) {
    return 'Não foi possível reiniciar o aplicativo: $error';
  }

  @override
  String get restartToApply => 'Reiniciar para aplicar?';

  @override
  String get restartDescription =>
      'Os downloads ativos serão pausados, o app será reiniciado e eles serão retomados automaticamente.';

  @override
  String get restartNow => 'Reiniciar agora';

  @override
  String get settingsIntro =>
      'Controle como seus torrents são baixados e armazenados.';

  @override
  String get downloadLocation => 'Local de download';

  @override
  String get downloadLocationDescription =>
      'Este diretório será usado para novos downloads.';

  @override
  String get choose => 'Escolher';

  @override
  String get speedLimits => 'Limites de velocidade';

  @override
  String get speedLimitsDescription =>
      'Deixe em branco para não limitar a velocidade global.';

  @override
  String get maximumDownload => 'Download máximo (MB/s)';

  @override
  String get maximumUpload => 'Upload máximo (MB/s)';

  @override
  String get unlimited => 'Sem limite';

  @override
  String get peerDiscovery => 'Descoberta de pares';

  @override
  String get peerDiscoveryDescription =>
      'Defina como o app encontra trackers e pares para novos torrents.';

  @override
  String get useDht => 'Usar DHT';

  @override
  String get useDhtDescription =>
      'Encontra pares na rede pública descentralizada. Pode conectar a IPs desconhecidos.';

  @override
  String get fetchPublicTrackers => 'Buscar trackers públicos';

  @override
  String get fetchPublicTrackersDescription =>
      'Baixa uma lista pública ao reiniciar. Salvar esta alteração pausa e retoma seus downloads.';

  @override
  String get behavior => 'Comportamento';

  @override
  String get behaviorDescription =>
      'As transferências continuam enquanto o app estiver na bandeja.';

  @override
  String get restoreDownloads => 'Restaurar downloads ao iniciar';

  @override
  String get notifyOnComplete => 'Notificar ao concluir download';

  @override
  String get downloadCompletedNotification => 'Download concluído';

  @override
  String get notifications => 'Notificações';

  @override
  String get notificationsDescription =>
      'Escolha quando o My Torrent deve chamar sua atenção.';

  @override
  String get soundOnImport => 'Som ao detectar magnet ou .torrent';

  @override
  String get soundOnComplete => 'Som ao concluir download';

  @override
  String get automaticDetection => 'Detecção automática';

  @override
  String get automaticDetectionDescription =>
      'Procure novos itens para importar sem abrir o aplicativo.';

  @override
  String get detectMagnetLinks =>
      'Detectar links magnet na área de transferência';

  @override
  String get detectTorrentFiles => 'Detectar arquivos .torrent em Downloads';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription => 'Escolha o idioma usado pelo aplicativo.';

  @override
  String get portugueseBrazil => 'Português (Brasil)';

  @override
  String get english => 'English';

  @override
  String get saveSettings => 'Salvar configurações';

  @override
  String get trayOpen => 'Abrir My Torrent';

  @override
  String get trayExit => 'Encerrar';

  @override
  String get errorSourceRequired =>
      'Informe um link magnet, URL ou arquivo .torrent.';

  @override
  String get errorSourceInvalid =>
      'Use um magnet, uma URL HTTP(S) ou um arquivo .torrent existente.';

  @override
  String get errorNoSelectableFiles =>
      'O torrent não contém arquivos selecionáveis.';

  @override
  String get errorMetadataTimeout =>
      'Não foi possível obter os metadados do torrent a tempo.';

  @override
  String errorHttpStatus(int statusCode) {
    return 'A URL retornou HTTP $statusCode.';
  }

  @override
  String get errorTorrentFileTooLarge => 'O arquivo .torrent excede 10 MB.';

  @override
  String get errorFileSelectionRequired =>
      'Selecione ao menos um arquivo para iniciar o download.';

  @override
  String get errorDestinationNotFound => 'A pasta de destino não existe.';

  @override
  String get errorDownloadFolderInvalid => 'Informe um nome de pasta válido.';

  @override
  String get errorDownloadFolderConflict =>
      'A pasta escolhida já contém arquivos.';

  @override
  String get errorDownloadDirectoryNotFound =>
      'A pasta de download não existe.';
}
