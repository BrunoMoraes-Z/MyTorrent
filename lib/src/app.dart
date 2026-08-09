import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'app_controller.dart';
import 'import_detection_service.dart';
import 'torrent_service.dart';

const _accent = Color(0xffd6ff4d);
const _surface = Color(0xff18181b);
const _panel = Color(0xff111113);
const _border = Color(0xff27272a);
const _muted = Color(0xffa1a1aa);

class TorrentDeskApp extends StatelessWidget {
  const TorrentDeskApp({
    super.key,
    required this.controller,
    this.initialSource,
  });

  final AppController controller;
  final String? initialSource;

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'My Torrent',
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      backgroundColor: const Color(0xff09090b),
      home: DashboardShell(
        controller: controller,
        initialSource: initialSource,
      ),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.controller,
    this.initialSource,
  });

  final AppController controller;
  final String? initialSource;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> with ProtocolListener {
  bool _settingsOpen = false;
  final List<ImportCandidate> _importQueue = <ImportCandidate>[];
  StreamSubscription<ImportCandidate>? _importSubscription;
  bool _showingImportPrompt = false;

  @override
  void initState() {
    super.initState();
    protocolHandler.addListener(this);
    _importSubscription = widget.controller.importCandidates.listen(
      _queueImportCandidate,
    );
    final source = widget.initialSource;
    if (source != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _prepareSource(source),
      );
    }
  }

  @override
  void dispose() {
    _importSubscription?.cancel();
    protocolHandler.removeListener(this);
    super.dispose();
  }

  @override
  void onProtocolUrlReceived(String url) => _prepareSource(url);

  void _queueImportCandidate(ImportCandidate candidate) {
    _importQueue.add(candidate);
    _showNextImportPrompt();
  }

  Future<void> _showNextImportPrompt() async {
    if (_showingImportPrompt || _importQueue.isEmpty || !mounted) return;
    _showingImportPrompt = true;
    final candidate = _importQueue.removeAt(0);
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
      await _prepareSource(candidate.source);
    }
    _showingImportPrompt = false;
    _showNextImportPrompt();
  }

  Future<void> _openSourceDialog() async {
    final sourceController = TextEditingController();
    await showShadDialog<void>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Adicionar torrent'),
        description: const Text(
          'Cole um magnet, URL .torrent ou escolha um arquivo local.',
        ),
        actions: <Widget>[
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ShadButton(
            backgroundColor: _accent,
            foregroundColor: const Color(0xff111113),
            onPressed: () {
              final value = sourceController.text;
              Navigator.of(dialogContext).pop();
              _prepareSource(value);
            },
            child: const Text('Continuar'),
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
              child: const Text('Escolher arquivo .torrent'),
            ),
          ],
        ),
      ),
    );
    sourceController.dispose();
  }

  Future<void> _prepareSource(String source) async {
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
          title: const Text('Não foi possível preparar o torrent'),
          description: Text(_errorMessage(error)),
          actions: <Widget>[
            ShadButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    if (error is TimeoutException) {
      return error.message?.toString() ?? 'Tempo limite excedido.';
    }
    return error.toString().replaceFirst('Exception: ', '');
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
                      onDownloads: () => setState(() => _settingsOpen = false),
                      onSettings: () => setState(() => _settingsOpen = true),
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
    final isMagnet = candidate.type == ImportCandidateType.magnet;
    return ShadDialog(
      title: Text(
        isMagnet ? 'Link magnet encontrado' : 'Arquivo .torrent encontrado',
      ),
      description: Text(
        isMagnet
            ? 'Detectado na área de transferência.'
            : 'Detectado na pasta Downloads do Windows.',
      ),
      constraints: const BoxConstraints(maxWidth: 510),
      actions: <Widget>[
        ShadButton.outline(onPressed: onIgnore, child: const Text('Ignorar')),
        ShadButton(
          backgroundColor: _accent,
          foregroundColor: const Color(0xff111113),
          onPressed: onImport,
          leading: const Icon(LucideIcons.download, size: 16),
          child: const Text('Importar'),
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
                    settingsOpen ? 'Configurações' : 'Downloads',
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
    required this.onDownloads,
    required this.onSettings,
    required this.activeCount,
  });

  final bool settingsOpen;
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(right: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            children: <Widget>[
              _BrandMark(),
              SizedBox(width: 10),
              Text('My Torrent', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          _NavigationItem(
            label: 'Downloads',
            icon: LucideIcons.list,
            selected: !settingsOpen,
            onPressed: onDownloads,
          ),
          _NavigationItem(
            label: 'Configurações',
            icon: LucideIcons.settings,
            selected: settingsOpen,
            onPressed: onSettings,
          ),
          const Spacer(),
          const Text(
            'Motor conectado',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
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
              const SizedBox(width: 7),
              Text(
                '$activeCount download(s) ativo(s)',
                style: const TextStyle(fontSize: 12),
              ),
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
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ShadButton.ghost(
        onPressed: onPressed,
        backgroundColor: selected ? const Color(0xff27272a) : null,
        width: double.infinity,
        mainAxisAlignment: MainAxisAlignment.start,
        leading: Icon(icon, size: 16),
        child: Text(label),
      ),
    );
  }
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Downloads',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Acompanhe e gerencie seus torrents.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
              ShadButton(
                backgroundColor: _accent,
                foregroundColor: const Color(0xff111113),
                leading: const Icon(LucideIcons.plus, size: 16),
                onPressed: onAdd,
                child: const Text('Adicionar torrent'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _Metric(label: 'Baixando', value: '$active'),
              const SizedBox(width: 10),
              _Metric(label: 'Pausados', value: '$paused'),
              const SizedBox(width: 10),
              _Metric(label: 'Concluídos', value: '$complete'),
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
                  ? const Center(
                      child: Text(
                        'Nenhum download ainda.',
                        style: TextStyle(color: _muted),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(flex: 4, child: Text('NOME', style: _TableHeaderStyle())),
          Expanded(
            flex: 2,
            child: Text('PROGRESSO', style: _TableHeaderStyle()),
          ),
          Expanded(child: Text('VELOCIDADE', style: _TableHeaderStyle())),
          SizedBox(
            width: 110,
            child: Text('STATUS', style: _TableHeaderStyle()),
          ),
          SizedBox(
            width: 126,
            child: Text('AÇÕES', style: _TableHeaderStyle()),
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
    final state = _status(torrent);
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
                  torrent.savePath,
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
                color: state == 'BAIXANDO' ? _accent : _muted,
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
                      ? () => controller.resume(torrent.id)
                      : () => controller.pause(torrent.id),
                  iconSize: 15,
                  icon: Icon(
                    torrent.isPaused ? LucideIcons.play : LucideIcons.pause,
                  ),
                ),
                ShadIconButton.ghost(
                  width: 30,
                  height: 30,
                  foregroundColor: _muted,
                  onPressed: () => controller.openFolder(torrent.savePath),
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
    await showShadDialog<void>(
      context: context,
      variant: ShadDialogVariant.alert,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Remover download?'),
        description: Text('"${torrent.name}" será removido da lista.'),
        actions: <Widget>[
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () {
              controller.remove(torrent.id, deleteFiles: false);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Manter arquivos'),
          ),
          ShadButton.destructive(
            onPressed: () {
              controller.remove(torrent.id, deleteFiles: true);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Apagar arquivos'),
          ),
        ],
      ),
    );
  }

  String _status(TorrentInfo info) {
    if (info.errorMsg.isNotEmpty) return 'ERRO';
    if (info.isFinished) return 'CONCLUÍDO';
    if (info.isPaused) return 'PAUSADO';
    return 'BAIXANDO';
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
          _error = error.toString().replaceFirst('FormatException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.prepared.files;
    final total = files
        .where((file) => _selected.contains(file.index))
        .fold<int>(0, (total, file) => total + file.size);
    return ShadDialog(
      title: const Text('Selecionar arquivos'),
      description: Text('${files.length} arquivo(s) encontrados no torrent.'),
      constraints: const BoxConstraints(maxWidth: 700),
      actions: <Widget>[
        ShadButton.outline(
          onPressed: _starting
              ? null
              : () {
                  widget.controller.cancelPreparation(widget.prepared);
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        ShadButton(
          backgroundColor: _accent,
          foregroundColor: const Color(0xff111113),
          enabled: _selected.isNotEmpty && !_starting,
          onPressed: _start,
          leading: const Icon(LucideIcons.download, size: 16),
          child: Text(_starting ? 'Iniciando...' : 'Iniciar download'),
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
                    '${_selected.length} de ${files.length} arquivos selecionados',
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
            const Text(
              'PASTA BASE',
              style: TextStyle(
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
            const SizedBox(height: 12),
            const Text(
              'NOME DA PASTA',
              style: TextStyle(
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
      setState(() => _message = 'Os limites devem ser maiores que zero.');
      return;
    }
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
        ),
      );
      if (mounted) setState(() => _message = 'Configurações salvas.');
    } on FileSystemException catch (error) {
      setState(() => _message = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: ListView(
        children: <Widget>[
          const Text(
            'Configurações',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Controle como seus torrents são baixados e armazenados.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _SettingsPanel(
            title: 'Local de download',
            description: 'Este diretório será usado para novos downloads.',
            child: Row(
              children: <Widget>[
                Expanded(child: ShadInput(controller: _directory)),
                const SizedBox(width: 8),
                ShadButton.outline(
                  onPressed: _chooseDirectory,
                  child: const Text('Escolher'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: 'Limites de velocidade',
            description:
                'Deixe em branco para não limitar a velocidade global.',
            child: Column(
              children: <Widget>[
                _LabeledInput(
                  label: 'Download máximo (MB/s)',
                  controller: _downloadLimit,
                ),
                const SizedBox(height: 10),
                _LabeledInput(
                  label: 'Upload máximo (MB/s)',
                  controller: _uploadLimit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: 'Comportamento',
            description:
                'As transferências continuam enquanto o app estiver na bandeja.',
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Restaurar downloads ao iniciar'),
                    ShadSwitch(
                      value: _restore,
                      onChanged: (value) => setState(() => _restore = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Notificar ao concluir download'),
                    ShadSwitch(
                      value: _notify,
                      onChanged: (value) => setState(() => _notify = value),
                    ),
                  ],
                ),
              ],
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
              child: const Text('Salvar configurações'),
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
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        SizedBox(
          width: 180,
          child: ShadInput(
            controller: controller,
            placeholder: const Text('Sem limite'),
          ),
        ),
      ],
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
}
