import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'My Torrent'**
  String get appTitle;

  /// No description provided for @addTorrent.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar torrent'**
  String get addTorrent;

  /// No description provided for @addTorrentDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cole um magnet, URL .torrent ou escolha um arquivo local.'**
  String get addTorrentDescription;

  /// No description provided for @cancel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @chooseTorrentFile.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolher arquivo .torrent'**
  String get chooseTorrentFile;

  /// No description provided for @prepareTorrentFailed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível preparar o torrent'**
  String get prepareTorrentFailed;

  /// No description provided for @close.
  ///
  /// In pt_BR, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @magnetLinkFound.
  ///
  /// In pt_BR, this message translates to:
  /// **'Link magnet encontrado'**
  String get magnetLinkFound;

  /// No description provided for @torrentFileFound.
  ///
  /// In pt_BR, this message translates to:
  /// **'Arquivo .torrent encontrado'**
  String get torrentFileFound;

  /// No description provided for @magnetDetected.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detectado na área de transferência.'**
  String get magnetDetected;

  /// No description provided for @torrentFileDetected.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detectado na pasta Downloads do Windows.'**
  String get torrentFileDetected;

  /// No description provided for @ignore.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ignorar'**
  String get ignore;

  /// No description provided for @import.
  ///
  /// In pt_BR, this message translates to:
  /// **'Importar'**
  String get import;

  /// No description provided for @downloads.
  ///
  /// In pt_BR, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @settings.
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// No description provided for @engineConnected.
  ///
  /// In pt_BR, this message translates to:
  /// **'Motor conectado'**
  String get engineConnected;

  /// No description provided for @activeDownloads.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, =0{Nenhum download ativo} =1{1 download ativo} other{{count} downloads ativos}}'**
  String activeDownloads(num count);

  /// No description provided for @downloadsIntro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acompanhe e gerencie seus torrents.'**
  String get downloadsIntro;

  /// No description provided for @downloading.
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixando'**
  String get downloading;

  /// No description provided for @paused.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pausados'**
  String get paused;

  /// No description provided for @completed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Concluídos'**
  String get completed;

  /// No description provided for @noDownloads.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum download ainda.'**
  String get noDownloads;

  /// No description provided for @tableName.
  ///
  /// In pt_BR, this message translates to:
  /// **'NOME'**
  String get tableName;

  /// No description provided for @tableProgress.
  ///
  /// In pt_BR, this message translates to:
  /// **'PROGRESSO'**
  String get tableProgress;

  /// No description provided for @tableSpeed.
  ///
  /// In pt_BR, this message translates to:
  /// **'VELOCIDADE'**
  String get tableSpeed;

  /// No description provided for @tableStatus.
  ///
  /// In pt_BR, this message translates to:
  /// **'STATUS'**
  String get tableStatus;

  /// No description provided for @tableActions.
  ///
  /// In pt_BR, this message translates to:
  /// **'AÇÕES'**
  String get tableActions;

  /// No description provided for @statusError.
  ///
  /// In pt_BR, this message translates to:
  /// **'ERRO'**
  String get statusError;

  /// No description provided for @statusCompleted.
  ///
  /// In pt_BR, this message translates to:
  /// **'CONCLUÍDO'**
  String get statusCompleted;

  /// No description provided for @statusPaused.
  ///
  /// In pt_BR, this message translates to:
  /// **'PAUSADO'**
  String get statusPaused;

  /// No description provided for @statusDownloading.
  ///
  /// In pt_BR, this message translates to:
  /// **'BAIXANDO'**
  String get statusDownloading;

  /// No description provided for @removeDownload.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover download?'**
  String get removeDownload;

  /// No description provided for @removeDownloadDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'\"{name}\" será removido da lista.'**
  String removeDownloadDescription(String name);

  /// No description provided for @keepFiles.
  ///
  /// In pt_BR, this message translates to:
  /// **'Manter arquivos'**
  String get keepFiles;

  /// No description provided for @deleteFiles.
  ///
  /// In pt_BR, this message translates to:
  /// **'Apagar arquivos'**
  String get deleteFiles;

  /// No description provided for @selectFiles.
  ///
  /// In pt_BR, this message translates to:
  /// **'Selecionar arquivos'**
  String get selectFiles;

  /// No description provided for @torrentFilesFound.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, =0{Nenhum arquivo encontrado no torrent.} =1{1 arquivo encontrado no torrent.} other{{count} arquivos encontrados no torrent.}}'**
  String torrentFilesFound(num count);

  /// No description provided for @starting.
  ///
  /// In pt_BR, this message translates to:
  /// **'Iniciando...'**
  String get starting;

  /// No description provided for @startDownload.
  ///
  /// In pt_BR, this message translates to:
  /// **'Iniciar download'**
  String get startDownload;

  /// No description provided for @selectedFiles.
  ///
  /// In pt_BR, this message translates to:
  /// **'{selected} de {total} arquivos selecionados'**
  String selectedFiles(num selected, num total);

  /// No description provided for @baseFolder.
  ///
  /// In pt_BR, this message translates to:
  /// **'PASTA BASE'**
  String get baseFolder;

  /// No description provided for @downloadFolder.
  ///
  /// In pt_BR, this message translates to:
  /// **'NOME DA PASTA'**
  String get downloadFolder;

  /// No description provided for @limitsMustBePositive.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os limites devem ser maiores que zero.'**
  String get limitsMustBePositive;

  /// No description provided for @settingsSaved.
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações salvas.'**
  String get settingsSaved;

  /// No description provided for @restartFailed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível reiniciar o aplicativo: {error}'**
  String restartFailed(String error);

  /// No description provided for @restartToApply.
  ///
  /// In pt_BR, this message translates to:
  /// **'Reiniciar para aplicar?'**
  String get restartToApply;

  /// No description provided for @restartDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os downloads ativos serão pausados, o app será reiniciado e eles serão retomados automaticamente.'**
  String get restartDescription;

  /// No description provided for @restartNow.
  ///
  /// In pt_BR, this message translates to:
  /// **'Reiniciar agora'**
  String get restartNow;

  /// No description provided for @settingsIntro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Controle como seus torrents são baixados e armazenados.'**
  String get settingsIntro;

  /// No description provided for @downloadLocation.
  ///
  /// In pt_BR, this message translates to:
  /// **'Local de download'**
  String get downloadLocation;

  /// No description provided for @downloadLocationDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este diretório será usado para novos downloads.'**
  String get downloadLocationDescription;

  /// No description provided for @choose.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolher'**
  String get choose;

  /// No description provided for @speedLimits.
  ///
  /// In pt_BR, this message translates to:
  /// **'Limites de velocidade'**
  String get speedLimits;

  /// No description provided for @speedLimitsDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Deixe em branco para não limitar a velocidade global.'**
  String get speedLimitsDescription;

  /// No description provided for @maximumDownload.
  ///
  /// In pt_BR, this message translates to:
  /// **'Download máximo (MB/s)'**
  String get maximumDownload;

  /// No description provided for @maximumUpload.
  ///
  /// In pt_BR, this message translates to:
  /// **'Upload máximo (MB/s)'**
  String get maximumUpload;

  /// No description provided for @unlimited.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem limite'**
  String get unlimited;

  /// No description provided for @peerDiscovery.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descoberta de pares'**
  String get peerDiscovery;

  /// No description provided for @peerDiscoveryDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Defina como o app encontra trackers e pares para novos torrents.'**
  String get peerDiscoveryDescription;

  /// No description provided for @useDht.
  ///
  /// In pt_BR, this message translates to:
  /// **'Usar DHT'**
  String get useDht;

  /// No description provided for @useDhtDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Encontra pares na rede pública descentralizada. Pode conectar a IPs desconhecidos.'**
  String get useDhtDescription;

  /// No description provided for @fetchPublicTrackers.
  ///
  /// In pt_BR, this message translates to:
  /// **'Buscar trackers públicos'**
  String get fetchPublicTrackers;

  /// No description provided for @fetchPublicTrackersDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixa uma lista pública ao reiniciar. Salvar esta alteração pausa e retoma seus downloads.'**
  String get fetchPublicTrackersDescription;

  /// No description provided for @behavior.
  ///
  /// In pt_BR, this message translates to:
  /// **'Comportamento'**
  String get behavior;

  /// No description provided for @behaviorDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'As transferências continuam enquanto o app estiver na bandeja.'**
  String get behaviorDescription;

  /// No description provided for @restoreDownloads.
  ///
  /// In pt_BR, this message translates to:
  /// **'Restaurar downloads ao iniciar'**
  String get restoreDownloads;

  /// No description provided for @notifyOnComplete.
  ///
  /// In pt_BR, this message translates to:
  /// **'Notificar ao concluir download'**
  String get notifyOnComplete;

  /// No description provided for @downloadCompletedNotification.
  ///
  /// In pt_BR, this message translates to:
  /// **'Download concluído'**
  String get downloadCompletedNotification;

  /// No description provided for @notifications.
  ///
  /// In pt_BR, this message translates to:
  /// **'Notificações'**
  String get notifications;

  /// No description provided for @notificationsDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha quando o My Torrent deve chamar sua atenção.'**
  String get notificationsDescription;

  /// No description provided for @soundOnImport.
  ///
  /// In pt_BR, this message translates to:
  /// **'Som ao detectar magnet ou .torrent'**
  String get soundOnImport;

  /// No description provided for @soundOnComplete.
  ///
  /// In pt_BR, this message translates to:
  /// **'Som ao concluir download'**
  String get soundOnComplete;

  /// No description provided for @automaticDetection.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detecção automática'**
  String get automaticDetection;

  /// No description provided for @automaticDetectionDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Procure novos itens para importar sem abrir o aplicativo.'**
  String get automaticDetectionDescription;

  /// No description provided for @detectMagnetLinks.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detectar links magnet na área de transferência'**
  String get detectMagnetLinks;

  /// No description provided for @detectTorrentFiles.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detectar arquivos .torrent em Downloads'**
  String get detectTorrentFiles;

  /// No description provided for @language.
  ///
  /// In pt_BR, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha o idioma usado pelo aplicativo.'**
  String get languageDescription;

  /// No description provided for @portugueseBrazil.
  ///
  /// In pt_BR, this message translates to:
  /// **'Português (Brasil)'**
  String get portugueseBrazil;

  /// No description provided for @english.
  ///
  /// In pt_BR, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @saveSettings.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar configurações'**
  String get saveSettings;

  /// No description provided for @trayOpen.
  ///
  /// In pt_BR, this message translates to:
  /// **'Abrir My Torrent'**
  String get trayOpen;

  /// No description provided for @trayExit.
  ///
  /// In pt_BR, this message translates to:
  /// **'Encerrar'**
  String get trayExit;

  /// No description provided for @errorSourceRequired.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um link magnet, URL ou arquivo .torrent.'**
  String get errorSourceRequired;

  /// No description provided for @errorSourceInvalid.
  ///
  /// In pt_BR, this message translates to:
  /// **'Use um magnet, uma URL HTTP(S) ou um arquivo .torrent existente.'**
  String get errorSourceInvalid;

  /// No description provided for @errorNoSelectableFiles.
  ///
  /// In pt_BR, this message translates to:
  /// **'O torrent não contém arquivos selecionáveis.'**
  String get errorNoSelectableFiles;

  /// No description provided for @errorMetadataTimeout.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível obter os metadados do torrent a tempo.'**
  String get errorMetadataTimeout;

  /// No description provided for @errorHttpStatus.
  ///
  /// In pt_BR, this message translates to:
  /// **'A URL retornou HTTP {statusCode}.'**
  String errorHttpStatus(int statusCode);

  /// No description provided for @errorTorrentFileTooLarge.
  ///
  /// In pt_BR, this message translates to:
  /// **'O arquivo .torrent excede 10 MB.'**
  String get errorTorrentFileTooLarge;

  /// No description provided for @errorFileSelectionRequired.
  ///
  /// In pt_BR, this message translates to:
  /// **'Selecione ao menos um arquivo para iniciar o download.'**
  String get errorFileSelectionRequired;

  /// No description provided for @errorDestinationNotFound.
  ///
  /// In pt_BR, this message translates to:
  /// **'A pasta de destino não existe.'**
  String get errorDestinationNotFound;

  /// No description provided for @errorDownloadFolderInvalid.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um nome de pasta válido.'**
  String get errorDownloadFolderInvalid;

  /// No description provided for @errorDownloadFolderConflict.
  ///
  /// In pt_BR, this message translates to:
  /// **'Já existe uma pasta com o nome original do torrent no destino escolhido.'**
  String get errorDownloadFolderConflict;

  /// No description provided for @errorDownloadDirectoryNotFound.
  ///
  /// In pt_BR, this message translates to:
  /// **'A pasta de download não existe.'**
  String get errorDownloadDirectoryNotFound;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
