import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/tr.dart';
import '../io/incoming.dart';
import '../io/settings.dart';
import '../io/share.dart';
import '../io/storage.dart';
import '../model/program.dart';
import '../model/serialization.dart';
import 'about_page.dart';
import 'editor_page.dart';

/// Esempi inclusi nell'app (cartella `assets/examples/`).
const exampleFiles = [
  'massimo',
  'media',
  'fattoriale',
  'primo',
  'mcd',
  'tabelline',
  'blink',
  'pulsante',
  'dimmer',
];

/// Esercizi inclusi nell'app (cartella `assets/exercises/`), dal più semplice.
const exerciseFiles = [
  'somma',
  'area',
  'pari',
  'massimo3',
  'conto_rovescia',
  'somma_n',
  'multipli',
  'conta_positivi',
  'media_n',
  'potenza',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage, this.settings, this.incoming});

  final FlowStorage storage;

  /// Preferenze dell'app (scelta del tema); senza, il menu del tema non c'è.
  final AppSettings? settings;

  /// File `.flow` aperti dall'esterno (Mail, File, Finder…).
  final IncomingFiles? incoming;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<StoredFlow>? _flows;
  List<Program> _examples = const [];
  List<Program> _exercises = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadExamples();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.incoming?.listen(_receive));
  }

  @override
  void dispose() {
    widget.incoming?.dispose();
    super.dispose();
  }

  /// File ricevuto dall'esterno: si torna alla home e lo si apre come copia.
  void _receive(String text) {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    _importText(text);
  }

  Future<void> _refresh() async {
    final flows = await widget.storage.list();
    if (mounted) setState(() => _flows = flows);
  }

  /// Lingua degli esempi caricati.
  AppLanguage? _examplesLanguage;

  /// Carica esempi ed esercizi nella lingua corrente (se mancano, quelli italiani).
  Future<void> _loadExamples() async {
    final lang = _examplesLanguage = tr.language;
    Future<List<Program>> load(String base, List<String> names) async {
      final dir = lang == AppLanguage.it ? base : '$base/${lang.name}';
      final list = <Program>[];
      for (final name in names) {
        String json;
        try {
          json = await rootBundle.loadString('$dir/$name.flow');
        } on Object {
          json = await rootBundle.loadString('$base/$name.flow');
        }
        list.add(decodeProgram(json));
      }
      return list;
    }

    final examples = await load('assets/examples', exampleFiles);
    final exercises = await load('assets/exercises', exerciseFiles);
    if (mounted && _examplesLanguage == lang) {
      setState(() {
        _examples = examples;
        _exercises = exercises;
      });
    }
  }

  Future<void> _open(StoredFlow f) async {
    try {
      final program = await widget.storage.load(f.file);
      await _openEditor(f, program);
    } on FlowFormatException catch (e) {
      _snack(tr.openFailed(e.message));
    }
  }

  Future<void> _openEditor(StoredFlow f, Program program) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorPage(file: f.file, program: program, storage: widget.storage),
      ),
    );
    await _refresh();
  }

  /// Crea una copia modificabile dell'esempio e la apre.
  Future<void> _openExample(Program example) async {
    final file = await widget.storage.create(example);
    await _openEditor(StoredFlow(file, example.name, DateTime.now()), example);
  }

  Future<void> _create() async {
    final result = await showDialog<(String, ProgramKind)>(
      context: context,
      builder: (_) => const _NewDiagramDialog(),
    );
    if (result == null || !mounted) return;
    final (name, kind) = result;
    final program = Program(name: name.trim().isEmpty ? tr.untitled : name.trim(), kind: kind);
    final file = await widget.storage.create(program);
    await _openEditor(StoredFlow(file, program.name, DateTime.now()), program);
  }

  Future<void> _delete(StoredFlow f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.deleteTitle),
        content: Text(tr.deleteBody(f.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr.delete)),
        ],
      ),
    );
    if (ok ?? false) {
      await widget.storage.delete(f.file);
      await _refresh();
    }
  }

  /// Apre un file `.flow` ricevuto (Mail, AirDrop, File…) e ne salva una copia.
  Future<void> _import() async {
    try {
      final picked = await FilePicker.pickFile();
      if (picked == null) return;
      await _importText(utf8.decode(await picked.readAsBytes()));
    } on FormatException {
      _snack(tr.importNotFlow);
    } on Object catch (e) {
      _snack(tr.importFailed('$e'));
    }
  }

  /// Salva una copia del diagramma [text] tra i propri e lo apre.
  Future<void> _importText(String text) async {
    try {
      final program = decodeProgram(text);
      final file = await widget.storage.create(program);
      await _refresh();
      if (!mounted) return;
      await _openEditor(StoredFlow(file, program.name, DateTime.now()), program);
    } on FlowFormatException catch (e) {
      _snack(tr.importFailed(e.message));
    } on FormatException {
      _snack(tr.importNotFlow);
    } on Object catch (e) {
      _snack(tr.importFailed('$e'));
    }
  }

  Future<void> _share(StoredFlow f, Rect? origin) async {
    try {
      final bytes = await f.file.readAsBytes();
      await shareBytes(
        bytes,
        fileName: '${safeFileName(f.name)}.flow',
        mimeType: 'application/x-dbflow',
        origin: origin,
      );
    } on Object catch (e) {
      _snack(tr.shareFailed('$e'));
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_examplesLanguage != null && _examplesLanguage != tr.language) _loadExamples();
    final flows = _flows;
    final header = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.primary);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DB Flow'),
        actions: [
          if (widget.settings case final settings?) _ThemeMenu(settings: settings),
          IconButton(
            tooltip: tr.info,
            icon: const Icon(Icons.info_outline),
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
          ),
          IconButton(
            tooltip: tr.openFlowFile,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: _import,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(tr.newDiagram),
      ),
      body: flows == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(tr.myDiagrams, style: header),
                ),
                if (flows.isEmpty)
                  ListTile(title: Text(tr.noDiagrams), subtitle: Text(tr.noDiagramsHint)),
                for (final f in flows)
                  ListTile(
                    leading: Icon(
                      f.damaged
                          ? Icons.broken_image_outlined
                          : f.isExercise
                          ? Icons.assignment_outlined
                          : Icons.account_tree_outlined,
                    ),
                    title: Text(f.name),
                    subtitle: Text(f.damaged ? tr.damagedFile : tr.modified(_date(f.modified))),
                    onTap: f.damaged ? null : () => _open(f),
                    trailing: Builder(
                      builder: (btn) => PopupMenuButton<String>(
                        tooltip: tr.more,
                        onSelected: (v) => v == 'share' ? _share(f, shareOrigin(btn)) : _delete(f),
                        itemBuilder: (_) => [
                          if (!f.damaged)
                            PopupMenuItem(
                              value: 'share',
                              child: ListTile(
                                leading: Icon(isDesktop ? Icons.save_alt : Icons.ios_share),
                                title: Text(isDesktop ? tr.saveAs : tr.share),
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text(tr.delete),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 32),
                for (final kind in ProgramKind.values) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      kind == ProgramKind.arduino ? tr.examplesArduino : tr.examples,
                      style: header,
                    ),
                  ),
                  for (final e in _examples.where((e) => e.kind == kind))
                    ListTile(
                      leading: Icon(
                        kind == ProgramKind.arduino
                            ? Icons.settings_input_component
                            : Icons.lightbulb_outline,
                      ),
                      title: Text(e.name),
                      subtitle: Text(tr.opensCopy),
                      onTap: () => _openExample(e),
                    ),
                  if (kind == ProgramKind.algorithm) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(tr.exercises, style: header),
                    ),
                    for (final e in _exercises)
                      ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: Text(e.name),
                        subtitle: Text(tr.opensCopy),
                        onTap: () => _openExample(e),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
    );
  }
}

class _NewDiagramDialog extends StatefulWidget {
  const _NewDiagramDialog();

  @override
  State<_NewDiagramDialog> createState() => _NewDiagramDialogState();
}

class _NewDiagramDialogState extends State<_NewDiagramDialog> {
  final _name = TextEditingController();
  ProgramKind _kind = ProgramKind.algorithm;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _ok() => Navigator.pop(context, (_name.text, _kind));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr.newDiagram),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ProgramKind>(
            segments: [
              ButtonSegment(
                value: ProgramKind.algorithm,
                label: Text(tr.kindAlgorithm),
                icon: Icon(Icons.account_tree_outlined),
              ),
              ButtonSegment(
                value: ProgramKind.arduino,
                label: Text(tr.kindArduino),
                icon: Icon(Icons.settings_input_component),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() => _kind = v.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: tr.name,
              hintText: _kind == ProgramKind.arduino ? tr.hintNameArduino : tr.hintNameAlgorithm,
            ),
            onSubmitted: (_) => _ok(),
          ),
          if (_kind == ProgramKind.arduino)
            Padding(padding: EdgeInsets.only(top: 12), child: Text(tr.newArduinoHint)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr.cancel)),
        FilledButton(onPressed: _ok, child: Text(tr.create)),
      ],
    );
  }
}

/// Scelta del tema: come il dispositivo, chiaro o scuro.
class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final current = settings.themeMode;
    return PopupMenuButton<ThemeMode>(
      tooltip: tr.theme,
      icon: Icon(switch (current) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      }),
      onSelected: settings.setThemeMode,
      itemBuilder: (_) => [
        for (final (mode, label) in [
          (ThemeMode.system, tr.themeSystem),
          (ThemeMode.light, tr.themeLight),
          (ThemeMode.dark, tr.themeDark),
        ])
          CheckedPopupMenuItem(value: mode, checked: mode == current, child: Text(label)),
      ],
    );
  }
}
