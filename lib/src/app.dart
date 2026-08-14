import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/generated/app_localizations.dart';
import 'activation_source.dart';
import 'app_controller.dart';
import 'app_error.dart';
import 'desktop_manager.dart';
import 'import_detection_service.dart';
import 'import_notification_service.dart';
import 'models.dart';
import 'torrent_service.dart';

const _accent = Color(0xffd6ff4d);
const _surface = Color(0xff18181b);
const _panel = Color(0xff111113);
const _border = Color(0xff27272a);
const _muted = Color(0xffa1a1aa);

Locale _localeFor(AppLanguage language) => switch (language) {
  AppLanguage.ptBr => const Locale('pt', 'BR'),
  AppLanguage.en => const Locale('en'),
};

String _localizedError(AppLocalizations l10n, Object error) {
  if (error is AppException) {
    return switch (error.code) {
      AppErrorCode.sourceRequired => l10n.errorSourceRequired,
      AppErrorCode.sourceInvalid => l10n.errorSourceInvalid,
      AppErrorCode.noSelectableFiles => l10n.errorNoSelectableFiles,
      AppErrorCode.metadataTimeout => l10n.errorMetadataTimeout,
      AppErrorCode.httpStatus => l10n.errorHttpStatus(error.statusCode ?? 0),
      AppErrorCode.torrentFileTooLarge => l10n.errorTorrentFileTooLarge,
      AppErrorCode.fileSelectionRequired => l10n.errorFileSelectionRequired,
      AppErrorCode.destinationNotFound => l10n.errorDestinationNotFound,
      AppErrorCode.downloadFolderInvalid => l10n.errorDownloadFolderInvalid,
      AppErrorCode.downloadFolderConflict => l10n.errorDownloadFolderConflict,
      AppErrorCode.downloadDirectoryNotFound =>
        l10n.errorDownloadDirectoryNotFound,
    };
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class MyTorrent extends StatelessWidget {
  const MyTorrent({
    super.key,
    required this.controller,
    required this.desktopManager,
    required this.notificationService,
    this.initialSource,
  });

  final AppController controller;
  final DesktopManager desktopManager;
  final ImportNotificationService notificationService;
  final String? initialSource;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ShadApp(
        title: 'My Torrent',
        locale: _localeFor(controller.settings.language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadZincColorScheme.dark(),
        ),
        backgroundColor: const Color(0xff09090b),
        home: DashboardShell(
          controller: controller,
          desktopManager: desktopManager,
          notificationService: notificationService,
          initialSource: initialSource,
        ),
      ),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.controller,
    required this.desktopManager,
    required this.notificationService,
    this.initialSource,
  });

  final AppController controller;
  final DesktopManager desktopManager;
  final ImportNotificationService notificationService;
  final String? initialSource;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> with ProtocolListener {
  bool _settingsOpen = false;
  final List<ImportCandidate> _importQueue = <ImportCandidate>[];
  final List<_QueuedSource> _sourceQueue = <_QueuedSource>[];
  StreamSubscription<ImportCandidate>? _importSubscription;
  StreamSubscription<ImportCandidate>? _notificationSubscription;
  StreamSubscription<TorrentInfo>? _completionSubscription;
  bool _showingImportPrompt = false;
  bool _preparingSource = false;
  String? _currentImportSource;

  @override
  void initState() {
    super.initState();
    protocolHandler.addListener(this);
    _importSubscription = widget.controller.importCandidates.listen(
      _onImportCandidate,
    );
    _notificationSubscription = widget.notificationService.activations.listen(
      _onNotificationActivation,
    );
    _completionSubscription = widget.controller.downloadCompletions.listen(
      _onDownloadComplete,
    );
    final source = widget.initialSource;
    if (source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _queueSource(source));
    }
    final notificationCandidate = widget.notificationService
        .takeInitialCandidate();
    if (notificationCandidate != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onNotificationActivation(notificationCandidate),
      );
    }
  }

  @override
  void dispose() {
    _importSubscription?.cancel();
    _notificationSubscription?.cancel();
    _completionSubscription?.cancel();
    protocolHandler.removeListener(this);
    super.dispose();
  }

  @override
  void onProtocolUrlReceived(String url) {
    final source = activationSource(<String>[url]);
    if (source == null) return;
    unawaited(widget.desktopManager.showWindow());
    _queueSource(source);
  }

  void _onImportCandidate(ImportCandidate candidate) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      widget.notificationService.showCandidate(
        candidate: candidate,
        title: candidate.type == ImportCandidateType.magnet
            ? l10n.magnetLinkFound
            : l10n.torrentFileFound,
        playSound: widget.controller.settings.soundOnImport,
      ),
    );
    _queueImportCandidate(candidate);
  }

  void _onNotificationActivation(ImportCandidate candidate) {
    unawaited(widget.desktopManager.showWindow());
    _queueImportCandidate(candidate);
  }

  void _onDownloadComplete(TorrentInfo torrent) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      widget.notificationService.showDownloadComplete(
        title: l10n.downloadCompletedNotification,
        body: torrent.name,
        playSound: widget.controller.settings.soundOnComplete,
      ),
    );
  }

  void _queueImportCandidate(ImportCandidate candidate) {
    if (_currentImportSource == candidate.source ||
        _importQueue.any((queued) => queued.source == candidate.source)) {
      return;
    }
    _importQueue.add(candidate);
    _showNextImportPrompt();
  }

  Future<void> _showNextImportPrompt() async {
    if (_showingImportPrompt || _importQueue.isEmpty || !mounted) return;
    _showingImportPrompt = true;
    final candidate = _importQueue.removeAt(0);
    _currentImportSource = candidate.source;
    final accepted = await showShadDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ImportCandidateDialog(
        candidate: candidate,
        onIgnore: () => Navigator.of(dialogContext).pop(false),
        onImport: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (accepted == true && mounted) {
      await _queueSource(candidate.source);
    }
    _currentImportSource = null;
    _showingImportPrompt = false;
    _showNextImportPrompt();
  }

  Future<void> _queueSource(String source) {
    for (final queued in _sourceQueue) {
      if (queued.source == source) return queued.completion.future;
    }
    final queued = _QueuedSource(source);
    _sourceQueue.add(queued);
    unawaited(_prepareNextSource());
    return queued.completion.future;
  }

  Future<void> _prepareNextSource() async {
    if (_preparingSource || !mounted) return;
    _preparingSource = true;
    while (_sourceQueue.isNotEmpty && mounted) {
      final queued = _sourceQueue.removeAt(0);
      await _prepareSource(queued.source);
      queued.completion.complete();
    }
    _preparingSource = false;
  }

  Future<void> _openSourceDialog() async {
    final sourceController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    await showShadDialog<void>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: Text(l10n.addTorrent),
        description: Text(l10n.addTorrentDescription),
        actions: <Widget>[
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ShadButton(
            backgroundColor: _accent,
            foregroundColor: const Color(0xff111113),
            onPressed: () {
              final value = sourceController.text;
              Navigator.of(dialogContext).pop();
              _queueSource(value);
            },
            child: Text(l10n.continueAction),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ShadInput(
              controller: sourceController,
              placeholder: const Text('magnet:?xt=urn:btih:...'),
            ),
            const SizedBox(height: 10),
            ShadButton.outline(
              onPressed: () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const <String>['torrent'],
                );
                final path = result?.files.single.path;
                if (path != null) {
                  sourceController.text = path;
                }
              },
              leading: const Icon(LucideIcons.fileUp),
              child: Text(l10n.chooseTorrentFile),
            ),
          ],
        ),
      ),
    );
    sourceController.dispose();
  }

  Future<void> _prepareSource(String source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final prepared = await widget.controller.prepare(source);
      if (!mounted) return;
      await showShadDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => FileSelectionDialog(
          controller: widget.controller,
          prepared: prepared,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await showShadDialog<void>(
        context: context,
        variant: ShadDialogVariant.alert,
        builder: (dialogContext) => ShadDialog.alert(
          title: Text(l10n.prepareTorrentFailed),
          description: Text(_localizedError(l10n, error)),
          actions: <Widget>[
            ShadButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return ColoredBox(
          color: const Color(0xff09090b),
          child: Column(
            children: <Widget>[
              _WindowBar(settingsOpen: _settingsOpen),
              Expanded(
                child: Row(
                  children: <Widget>[
                    _Sidebar(
                      settingsOpen: _settingsOpen,
                      collapsed: widget.controller.settings.sidebarCollapsed,
                      onDownloads: () => setState(() => _settingsOpen = false),
                      onSettings: () => setState(() => _settingsOpen = true),
                      onToggleCollapsed: () => unawaited(
                        widget.controller.setSidebarCollapsed(
                          !widget.controller.settings.sidebarCollapsed,
                        ),
                      ),
                      activeCount: widget.controller.downloads
                          .where((item) => !item.isPaused && !item.isFinished)
                          .length,
                    ),
                    Expanded(
                      child: _settingsOpen
                          ? SettingsView(controller: widget.controller)
                          : DownloadsView(
                              controller: widget.controller,
                              onAdd: _openSourceDialog,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QueuedSource {
  _QueuedSource(this.source);

  final String source;
  final Completer<void> completion = Completer<void>();
}

class ImportCandidateDialog extends StatelessWidget {
  const ImportCandidateDialog({
    super.key,
    required this.candidate,
    required this.onIgnore,
    required this.onImport,
  });

  final ImportCandidate candidate;
  final VoidCallback onIgnore;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMagnet = candidate.type == ImportCandidateType.magnet;
    return ShadDialog(
      title: Text(isMagnet ? l10n.magnetLinkFound : l10n.torrentFileFound),
      description: Text(
        isMagnet ? l10n.magnetDetected : l10n.torrentFileDetected,
      ),
      constraints: const BoxConstraints(maxWidth: 510),
      actions: <Widget>[
        ShadButton.outline(onPressed: onIgnore, child: Text(l10n.ignore)),
        ShadButton(
          backgroundColor: _accent,
          foregroundColor: const Color(0xff111113),
          onPressed: onImport,
          leading: const Icon(LucideIcons.download, size: 16),
          child: Text(l10n.import),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff0f0f11),
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isMagnet ? LucideIcons.magnet : LucideIcons.file,
              size: 16,
              color: _muted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                candidate.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowBar extends StatelessWidget {
  const _WindowBar({required this.settingsOpen});

  final bool settingsOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 42,
      child: Row(
        children: <Widget>[
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    settingsOpen ? l10n.settings : l10n.downloads,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          _captionButton(LucideIcons.minus, windowManager.minimize),
          _captionButton(LucideIcons.square, windowManager.maximize),
          _captionButton(LucideIcons.x, windowManager.close, danger: true),
        ],
      ),
    );
  }

  Widget _captionButton(
    IconData icon,
    Future<void> Function() action, {
    bool danger = false,
  }) {
    return ShadIconButton.ghost(
      width: 38,
      height: 32,
      padding: EdgeInsets.zero,
      foregroundColor: danger ? const Color(0xfff87171) : _muted,
      onPressed: action,
      iconSize: 16,
      icon: Icon(icon),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.settingsOpen,
    required this.collapsed,
    required this.onDownloads,
    required this.onSettings,
    required this.onToggleCollapsed,
    required this.activeCount,
  });

  final bool settingsOpen;
  final bool collapsed;
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  final VoidCallback onToggleCollapsed;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: collapsed ? 64 : 210,
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(right: BorderSide(color: _border)),
      ),
      padding: EdgeInsets.all(collapsed ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (collapsed)
            Center(child: _BrandMark())
          else
            Row(
              children: <Widget>[
                _BrandMark(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.appTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _SidebarToggle(
                  collapsed: collapsed,
                  onPressed: onToggleCollapsed,
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (collapsed) ...<Widget>[
            _SidebarToggle(collapsed: collapsed, onPressed: onToggleCollapsed),
            const SizedBox(height: 12),
          ],
          _NavigationItem(
            label: l10n.downloads,
            icon: LucideIcons.list,
            selected: !settingsOpen,
            collapsed: collapsed,
            onPressed: onDownloads,
          ),
          _NavigationItem(
            label: l10n.settings,
            icon: LucideIcons.settings,
            selected: settingsOpen,
            collapsed: collapsed,
            onPressed: onSettings,
          ),
          const Spacer(),
          if (!collapsed) ...<Widget>[
            Text(
              l10n.engineConnected,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                width: 7,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (!collapsed) ...<Widget>[
                const SizedBox(width: 7),
                Text(
                  l10n.activeDownloads(activeCount),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        LucideIcons.download,
        size: 16,
        color: Color(0xff111113),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = collapsed
        ? ShadIconButton.ghost(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            foregroundColor: selected ? null : _muted,
            backgroundColor: selected ? const Color(0xff27272a) : null,
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
          )
        : ShadButton.ghost(
            onPressed: onPressed,
            backgroundColor: selected ? const Color(0xff27272a) : null,
            width: double.infinity,
            mainAxisAlignment: MainAxisAlignment.start,
            leading: Icon(icon, size: 16),
            child: Text(label),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        label: label,
        button: true,
        child: collapsed ? Center(child: button) : button,
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  const _SidebarToggle({required this.collapsed, required this.onPressed});

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
    button: true,
    child: ShadIconButton.ghost(
      width: 32,
      height: 32,
      padding: EdgeInsets.zero,
      foregroundColor: _muted,
      onPressed: onPressed,
      icon: Icon(
        collapsed ? LucideIcons.panelLeftOpen : LucideIcons.panelLeftClose,
        size: 16,
      ),
    ),
  );
}

class DownloadsView extends StatelessWidget {
  const DownloadsView({
    super.key,
    required this.controller,
    required this.onAdd,
  });

  final AppController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final downloads = controller.downloads;
    final active = downloads
        .where((item) => !item.isPaused && !item.isFinished)
        .length;
    final paused = downloads.where((item) => item.isPaused).length;
    final complete = downloads.where((item) => item.isFinished).length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.downloads,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    l10n.downloadsIntro,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
              ShadButton(
                backgroundColor: _accent,
                foregroundColor: const Color(0xff111113),
                leading: const Icon(LucideIcons.plus, size: 16),
                onPressed: onAdd,
                child: Text(l10n.addTorrent),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _Metric(label: l10n.downloading, value: '$active'),
              const SizedBox(width: 10),
              _Metric(label: l10n.paused, value: '$paused'),
              const SizedBox(width: 10),
              _Metric(label: l10n.completed, value: '$complete'),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _panel,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: downloads.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noDownloads,
                        style: const TextStyle(color: _muted),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: downloads.length + 1,
                      separatorBuilder: (_, _) => const DividerLine(),
                      itemBuilder: (context, index) {
                        if (index == 0) return const _DownloadHeader();
                        return _DownloadRow(
                          controller: controller,
                          torrent: downloads[index - 1],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DownloadHeader extends StatelessWidget {
  const _DownloadHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(l10n.tableName, style: const _TableHeaderStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.tableProgress, style: const _TableHeaderStyle()),
          ),
          Expanded(
            child: Text(l10n.tableSpeed, style: const _TableHeaderStyle()),
          ),
          SizedBox(
            width: 110,
            child: Text(l10n.tableStatus, style: const _TableHeaderStyle()),
          ),
          SizedBox(
            width: 126,
            child: Text(l10n.tableActions, style: const _TableHeaderStyle()),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderStyle extends TextStyle {
  const _TableHeaderStyle()
    : super(
        color: _muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: .7,
      );
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.controller, required this.torrent});

  final AppController controller;
  final TorrentInfo torrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _status(torrent, l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  torrent.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.downloadDirectory(torrent),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 130,
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: ColoredBox(
                      color: _border,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: torrent.progress.clamp(0, 1),
                        child: const ColoredBox(color: _accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(torrent.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              _formatRate(torrent.downloadRate),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              state,
              style: TextStyle(
                color: state == l10n.statusDownloading ? _accent : _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 126,
            child: Row(
              children: <Widget>[
                ShadIconButton.ghost(
                  width: 30,
                  height: 30,
                  onPressed: torrent.isPaused
                      ? () async => controller.resume(torrent.id)
                      : () async => controller.pause(torrent.id),
                  iconSize: 15,
                  icon: Icon(
                    torrent.isPaused ? LucideIcons.play : LucideIcons.pause,
                  ),
                ),
                ShadIconButton.ghost(
                  width: 30,
                  height: 30,
                  foregroundColor: _muted,
                  onPressed: () => controller.openFolder(
                    controller.downloadDirectory(torrent),
                  ),
                  iconSize: 15,
                  icon: const Icon(LucideIcons.folderOpen),
                ),
                ShadIconButton.ghost(
                  width: 30,
                  height: 30,
                  foregroundColor: const Color(0xfff87171),
                  onPressed: () => _confirmRemoval(context),
                  iconSize: 15,
                  icon: const Icon(LucideIcons.trash2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoval(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showShadDialog<void>(
      context: context,
      variant: ShadDialogVariant.alert,
      builder: (dialogContext) => ShadDialog.alert(
        title: Text(l10n.removeDownload),
        description: Text(l10n.removeDownloadDescription(torrent.name)),
        actions: <Widget>[
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ShadButton.destructive(
            onPressed: () async {
              await controller.remove(torrent.id, deleteFiles: false);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.keepFiles),
          ),
          ShadButton.destructive(
            onPressed: () async {
              await controller.remove(torrent.id, deleteFiles: true);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.deleteFiles),
          ),
        ],
      ),
    );
  }

  String _status(TorrentInfo info, AppLocalizations l10n) {
    if (info.errorMsg.isNotEmpty) return l10n.statusError;
    if (info.isFinished) return l10n.statusCompleted;
    if (info.isPaused) return l10n.statusPaused;
    return l10n.statusDownloading;
  }

  String _formatRate(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '-';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }
}

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});
  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: _border));
}

class FileSelectionDialog extends StatefulWidget {
  const FileSelectionDialog({
    super.key,
    required this.controller,
    required this.prepared,
  });

  final AppController controller;
  final PreparedTorrent prepared;

  @override
  State<FileSelectionDialog> createState() => _FileSelectionDialogState();
}

class _FileSelectionDialogState extends State<FileSelectionDialog> {
  late final Set<int> _selected;
  late final TextEditingController _directory;
  late final TextEditingController _folderName;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.prepared.files.map((file) => file.index).toSet();
    _directory = TextEditingController(text: widget.prepared.directory);
    _folderName = TextEditingController(text: widget.prepared.name);
  }

  @override
  void dispose() {
    _directory.dispose();
    _folderName.dispose();
    super.dispose();
  }

  Future<void> _chooseDirectory() async {
    final selected = await FilePicker.getDirectoryPath(
      initialDirectory: _directory.text,
    );
    if (selected != null) _directory.text = selected;
  }

  Future<void> _start() async {
    if (_selected.isEmpty) return;
    setState(() => _starting = true);
    try {
      await widget.controller.start(
        widget.prepared,
        _selected,
        _directory.text,
        _folderName.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = _localizedError(AppLocalizations.of(context)!, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final files = widget.prepared.files;
    final total = files
        .where((file) => _selected.contains(file.index))
        .fold<int>(0, (total, file) => total + file.size);
    return ShadDialog(
      title: Text(l10n.selectFiles),
      description: Text(l10n.torrentFilesFound(files.length)),
      constraints: const BoxConstraints(maxWidth: 700),
      actions: <Widget>[
        ShadButton.outline(
          onPressed: _starting
              ? null
              : () {
                  widget.controller.cancelPreparation(widget.prepared);
                  Navigator.of(context).pop();
                },
          child: Text(l10n.cancel),
        ),
        ShadButton(
          backgroundColor: _accent,
          foregroundColor: const Color(0xff111113),
          enabled: _selected.isNotEmpty && !_starting,
          onPressed: _start,
          leading: const Icon(LucideIcons.download, size: 16),
          child: Text(_starting ? l10n.starting : l10n.startDownload),
        ),
      ],
      child: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ShadCheckbox(
                  value: _selected.length == files.length,
                  onChanged: (value) => setState(() {
                    _selected
                      ..clear()
                      ..addAll(
                        value ? files.map((file) => file.index) : <int>[],
                      );
                  }),
                  label: Text(
                    l10n.selectedFiles(_selected.length, files.length),
                  ),
                ),
                Text(
                  _formatSize(total),
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, _) => const DividerLine(),
                itemBuilder: (context, index) {
                  final file = files[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: <Widget>[
                        ShadCheckbox(
                          value: _selected.contains(file.index),
                          onChanged: (value) => setState(() {
                            value
                                ? _selected.add(file.index)
                                : _selected.remove(file.index);
                          }),
                        ),
                        const SizedBox(width: 10),
                        const Icon(LucideIcons.file, size: 15, color: _muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatSize(file.size),
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.baseFolder,
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(child: ShadInput(controller: _directory)),
                const SizedBox(width: 8),
                ShadButton.outline(
                  onPressed: _chooseDirectory,
                  child: const Icon(LucideIcons.folderOpen, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.downloadFolder,
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 6),
            ShadInput(controller: _folderName),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xfff87171), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final TextEditingController _directory;
  late final TextEditingController _downloadLimit;
  late final TextEditingController _uploadLimit;
  late bool _restore;
  late bool _notify;
  late bool _soundOnImport;
  late bool _soundOnComplete;
  late bool _detectMagnetLinks;
  late bool _detectTorrentFiles;
  late bool _enableDht;
  late bool _fetchTrackers;
  late AppLanguage _language;
  String? _message;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _directory = TextEditingController(text: settings.downloadDirectory);
    _downloadLimit = TextEditingController(
      text: settings.downloadLimitMb?.toString() ?? '',
    );
    _uploadLimit = TextEditingController(
      text: settings.uploadLimitMb?.toString() ?? '',
    );
    _restore = settings.restoreOnLaunch;
    _notify = settings.notifyOnComplete;
    _soundOnImport = settings.soundOnImport;
    _soundOnComplete = settings.soundOnComplete;
    _detectMagnetLinks = settings.detectMagnetLinks;
    _detectTorrentFiles = settings.detectTorrentFiles;
    _enableDht = settings.enableDht;
    _fetchTrackers = settings.fetchTrackers;
    _language = settings.language;
  }

  @override
  void dispose() {
    _directory.dispose();
    _downloadLimit.dispose();
    _uploadLimit.dispose();
    super.dispose();
  }

  Future<void> _chooseDirectory() async {
    final selected = await FilePicker.getDirectoryPath(
      initialDirectory: _directory.text,
    );
    if (selected != null) setState(() => _directory.text = selected);
  }

  Future<void> _save() async {
    final download = double.tryParse(_downloadLimit.text.replaceAll(',', '.'));
    final upload = double.tryParse(_uploadLimit.text.replaceAll(',', '.'));
    if (download != null && download <= 0 || upload != null && upload <= 0) {
      setState(
        () => _message = AppLocalizations.of(context)!.limitsMustBePositive,
      );
      return;
    }
    final shouldRestart =
        _fetchTrackers != widget.controller.settings.fetchTrackers;
    if (shouldRestart && !await _confirmRestart()) return;
    try {
      await widget.controller.saveSettings(
        widget.controller.settings.copyWith(
          downloadDirectory: _directory.text,
          downloadLimitMb: download,
          uploadLimitMb: upload,
          clearDownloadLimit: _downloadLimit.text.trim().isEmpty,
          clearUploadLimit: _uploadLimit.text.trim().isEmpty,
          restoreOnLaunch: _restore,
          notifyOnComplete: _notify,
          soundOnImport: _soundOnImport,
          soundOnComplete: _soundOnComplete,
          detectMagnetLinks: _detectMagnetLinks,
          detectTorrentFiles: _detectTorrentFiles,
          enableDht: _enableDht,
          fetchTrackers: _fetchTrackers,
          language: _language,
        ),
      );
      if (shouldRestart) {
        await widget.controller.restartForTrackerSettings();
        return;
      }
      if (mounted) {
        setState(() => _message = AppLocalizations.of(context)!.settingsSaved);
      }
    } catch (error) {
      setState(
        () => _message = AppLocalizations.of(
          context,
        )!.restartFailed(_localizedError(AppLocalizations.of(context)!, error)),
      );
    }
  }

  Future<bool> _confirmRestart() async {
    final l10n = AppLocalizations.of(context)!;
    final restart = await showShadDialog<bool>(
      context: context,
      variant: ShadDialogVariant.alert,
      builder: (dialogContext) => ShadDialog.alert(
        title: Text(l10n.restartToApply),
        description: Text(l10n.restartDescription),
        actions: <Widget>[
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          ShadButton(
            backgroundColor: _accent,
            foregroundColor: const Color(0xff111113),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.restartNow),
          ),
        ],
      ),
    );
    return restart ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: ListView(
        children: <Widget>[
          Text(
            l10n.settings,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsIntro,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _SettingsPanel(
            title: l10n.downloadLocation,
            description: l10n.downloadLocationDescription,
            child: Row(
              children: <Widget>[
                Expanded(child: ShadInput(controller: _directory)),
                const SizedBox(width: 8),
                ShadButton.outline(
                  onPressed: _chooseDirectory,
                  child: Text(l10n.choose),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: l10n.speedLimits,
            description: l10n.speedLimitsDescription,
            child: Column(
              children: <Widget>[
                _LabeledInput(
                  label: l10n.maximumDownload,
                  controller: _downloadLimit,
                ),
                const SizedBox(height: 10),
                _LabeledInput(
                  label: l10n.maximumUpload,
                  controller: _uploadLimit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: l10n.peerDiscovery,
            description: l10n.peerDiscoveryDescription,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l10n.useDht),
                          SizedBox(height: 3),
                          Text(
                            l10n.useDhtDescription,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ShadSwitch(
                      value: _enableDht,
                      onChanged: (value) => setState(() => _enableDht = value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l10n.fetchPublicTrackers),
                          SizedBox(height: 3),
                          Text(
                            l10n.fetchPublicTrackersDescription,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ShadSwitch(
                      value: _fetchTrackers,
                      onChanged: (value) =>
                          setState(() => _fetchTrackers = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: l10n.behavior,
            description: l10n.behaviorDescription,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(l10n.restoreDownloads),
                    ShadSwitch(
                      value: _restore,
                      onChanged: (value) => setState(() => _restore = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: l10n.notifications,
            description: l10n.notificationsDescription,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(l10n.notifyOnComplete),
                    ShadSwitch(
                      value: _notify,
                      onChanged: (value) => setState(() => _notify = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(l10n.soundOnImport),
                    ShadSwitch(
                      value: _soundOnImport,
                      onChanged: (value) =>
                          setState(() => _soundOnImport = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(l10n.soundOnComplete),
                    ShadSwitch(
                      value: _soundOnComplete,
                      onChanged: (value) =>
                          setState(() => _soundOnComplete = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: l10n.automaticDetection,
            description: l10n.automaticDetectionDescription,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(l10n.detectMagnetLinks),
                    ShadSwitch(
                      value: _detectMagnetLinks,
                      onChanged: (value) =>
                          setState(() => _detectMagnetLinks = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(l10n.detectTorrentFiles),
                    ShadSwitch(
                      value: _detectTorrentFiles,
                      onChanged: (value) =>
                          setState(() => _detectTorrentFiles = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: l10n.language,
            description: l10n.languageDescription,
            child: ShadSelect<AppLanguage>(
              initialValue: _language,
              selectedOptionBuilder: (context, language) =>
                  Text(_languageLabel(l10n, language)),
              options: AppLanguage.values
                  .map(
                    (language) => ShadOption<AppLanguage>(
                      value: language,
                      child: Text(_languageLabel(l10n, language)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (language) {
                if (language != null) setState(() => _language = language);
              },
            ),
          ),
          if (_message != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: const TextStyle(color: _accent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton(
              backgroundColor: _accent,
              foregroundColor: const Color(0xff111113),
              onPressed: _save,
              child: Text(l10n.saveSettings),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.description,
    required this.child,
  });
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        SizedBox(
          width: 180,
          child: ShadInput(
            controller: controller,
            placeholder: Text(l10n.unlimited),
          ),
        ),
      ],
    );
  }
}

String _languageLabel(AppLocalizations l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.ptBr => l10n.portugueseBrazil,
      AppLanguage.en => l10n.english,
    };

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
}
