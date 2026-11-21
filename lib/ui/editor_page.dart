import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../arduino/board.dart';
import '../codegen/generator.dart';
import '../editor/block_dialogs.dart';
import '../editor/commands.dart';
import '../editor/editor_state.dart';
import '../i18n/tr.dart';
import '../io/export_pdf.dart';
import '../io/export_png.dart';
import '../io/export_svg.dart';
import '../io/share.dart';
import '../io/storage.dart';
import '../layout/layout_engine.dart';
import '../layout/metrics.dart' show MeasureText;
import '../model/exercise.dart';
import '../model/program.dart';
import '../model/serialization.dart';
import '../model/slot.dart';
import '../model/stmt.dart';
import '../model/validator.dart';
import '../render/block_widget.dart';
import '../render/flow_canvas.dart';
import '../render/theme.dart';
import '../runtime/exercise_check.dart';
import 'arduino_setup_page.dart';
import 'code_page.dart';
import 'exercise_page.dart';
import 'run_controller.dart';
import 'run_panel.dart';

/// Larghezza oltre la quale il pannello di esecuzione sta di lato (iPad).
const wideLayoutWidth = 760.0;

enum _MenuAction { fit, code, pins, exercise, shareExercise, sketch, shareFlow, png, svg, pdf }

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.file, required this.program, required this.storage});

  final File file;
  final Program program;
  final FlowStorage storage;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final EditorState _state = EditorState(widget.program)..addListener(_onChanged);
  final _transform = TransformationController();
  final _canvasKey = GlobalKey();
  final _menuKey = GlobalKey();
  final MeasureText _measure = flutterMeasure();

  Program? _layoutFor;
  AppLanguage? _layoutLanguage;
  late DiagramLayout _layout;

  Program? _saved;
  Timer? _saveTimer;

  /// Esecuzione in corso (modalità "Esegui"); `null` in modifica.
  RunController? _run;
  String? _followed;

  /// Ultima verifica dell'esercizio e il diagramma su cui è stata fatta.
  (Program, List<CaseResult>)? _lastCheck;

  Program get _program => _state.program;

  DiagramLayout get layout {
    if (!identical(_layoutFor, _program) || _layoutLanguage != tr.language) {
      _layoutLanguage = tr.language;
      _layout = layoutProgram(_program, measure: _measure);
      _layoutFor = _program;
    }
    return _layout;
  }

  @override
  void initState() {
    super.initState();
    _saved = widget.program;
  }

  void _onChanged() {
    setState(() {});
    if (!identical(_saved, _program)) {
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), _save);
    }
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    final p = _program;
    if (identical(_saved, p)) return;
    _saved = p;
    try {
      await widget.storage.save(widget.file, p);
    } on Object catch (e) {
      if (mounted) _snack(tr.saveFailed('$e'));
    }
  }

  @override
  void dispose() {
    _save();
    _run?.dispose();
    _state.removeListener(_onChanged);
    _state.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _snack(String msg, {SnackBarAction? action}) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), action: action));

  Map<String, VarType> get _variables => {
    for (final s in _program.allStmts)
      if (s case Declare(:final name, :final type) when name.isNotEmpty) name: type,
  };

  bool _isBlock(String id) => id != startId && id != endId && id != loopId;

  // ------------------------------------------------------------ modifica

  Future<void> _insert(Slot slot) async {
    final kind = await _pickKind();
    if (kind == null || !mounted) return;
    final edited = await showBlockEditor(
      context,
      stmt: kind.create(),
      variables: _variables,
      arduino: _program.arduino,
      isNew: true,
    );
    if (edited != null) _state.insert(slot, edited);
  }

  Future<void> _edit(String id) async {
    final stmt = findBlock(_program, id);
    if (stmt == null) return;
    _state.select(id);
    final edited = await showBlockEditor(
      context,
      stmt: stmt,
      variables: _variables,
      arduino: _program.arduino,
    );
    if (edited != null) _state.replace(id, edited);
  }

  void _delete(String id) {
    final stmt = findBlock(_program, id);
    _state.delete(id);
    final container = stmt is If || stmt is While || stmt is DoWhile || stmt is For;
    _snack(
      container ? tr.blockDeletedWithContent : tr.blockDeleted,
      action: SnackBarAction(label: tr.undo, onPressed: _state.undo),
    );
  }

  /// Scorciatoie da tastiera (computer e iPad con tastiera): ⌘/Ctrl per
  /// annullare, ripetere e duplicare; Canc per eliminare, Invio per
  /// modificare, Esc per deselezionare.
  Map<ShortcutActivator, VoidCallback> _shortcuts(bool running) {
    if (running) return const {};
    final sel = _state.selectedId;
    void when(bool ok, VoidCallback f) => ok ? f() : null;
    final map = <ShortcutActivator, VoidCallback>{};
    for (final mod in [(meta: true, control: false), (meta: false, control: true)]) {
      SingleActivator key(LogicalKeyboardKey k, {bool shift = false}) =>
          SingleActivator(k, meta: mod.meta, control: mod.control, shift: shift);
      map[key(LogicalKeyboardKey.keyZ)] = () => when(_state.canUndo, _state.undo);
      map[key(LogicalKeyboardKey.keyZ, shift: true)] = () => when(_state.canRedo, _state.redo);
      map[key(LogicalKeyboardKey.keyY)] = () => when(_state.canRedo, _state.redo);
      map[key(LogicalKeyboardKey.keyD)] = () => when(sel != null, () => _state.duplicate(sel!));
    }
    if (sel != null && _isBlock(sel)) {
      map[const SingleActivator(LogicalKeyboardKey.delete)] = () => _delete(sel);
      map[const SingleActivator(LogicalKeyboardKey.backspace)] = () => _delete(sel);
      map[const SingleActivator(LogicalKeyboardKey.enter)] = () => _edit(sel);
      map[const SingleActivator(LogicalKeyboardKey.escape)] = () => _state.select(null);
    }
    return map;
  }

  Future<void> _rename() async {
    if (_run != null) return;
    final c = TextEditingController(text: _program.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.diagramName),
        content: TextField(
          controller: c,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr.ok)),
        ],
      ),
    );
    c.dispose();
    if (name != null && name.trim().isNotEmpty && name.trim() != _program.name) {
      _state.rename(name.trim());
    }
  }

  // ------------------------------------------------------------ esecuzione

  void _toggleRun() {
    if (_run != null) {
      _run!
        ..removeListener(_onRunChanged)
        ..dispose();
      setState(() => _run = null);
      return;
    }
    final count = _state.issues.values.fold<int>(0, (n, l) => n + l.length);
    if (count > 0) {
      _snack(tr.fixBeforeRun(count));
      return;
    }
    _state.select(null);
    setState(() => _run = RunController(_program)..addListener(_onRunChanged));
  }

  void _onRunChanged() {
    setState(() {});
    final id = _run?.activeId;
    if (id != null && id != _followed) {
      _followed = id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible(id));
    }
  }

  /// Sposta la vista se il blocco [id] è fuori dallo schermo.
  void _ensureVisible(String id) {
    final box = layout.boxById(id);
    final size = _canvasKey.currentContext?.size;
    if (box == null || size == null) return;
    final m = _transform.value;
    final scale = m.getMaxScaleOnAxis();
    final tx = m.getTranslation().x, ty = m.getTranslation().y;
    final left = box.x * scale + tx, right = box.right * scale + tx;
    final top = box.y * scale + ty, bottom = box.bottom * scale + ty;
    const margin = 40.0;
    var dx = 0.0, dy = 0.0;
    if (top < margin || bottom > size.height - margin) {
      dy = size.height / 2 - (top + bottom) / 2;
    }
    if (left < margin || right > size.width - margin) {
      dx = size.width / 2 - (left + right) / 2;
    }
    if (dx == 0 && dy == 0) return;
    _transform.value = Matrix4.translationValues(tx + dx, ty + dy, 0)
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1));
  }

  // ------------------------------------------------------------ menu

  Future<void> _menu(_MenuAction a) async {
    final origin = shareOrigin(_menuKey.currentContext ?? context);
    final name = safeFileName(_program.name);
    try {
      switch (a) {
        case _MenuAction.fit:
          final size = _canvasKey.currentContext?.size;
          if (size != null) _transform.value = fitTransform(size, layout);
        case _MenuAction.pins:
          await _openPins();
        case _MenuAction.code:
          await Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => CodePage(program: _program)));
        case _MenuAction.exercise:
          await _openExercise();
        case _MenuAction.shareExercise:
          final e = _program.exercise!;
          final task = Program(name: _program.name, exercise: e.copyWith(locked: true));
          await shareBytes(
            utf8.encode(encodeProgram(task)),
            fileName: '$name.flow',
            mimeType: 'application/x-dbflow',
            origin: origin,
          );
        case _MenuAction.sketch:
          final path = await saveArduinoSketch(
            generateCode(_program, CodeLanguage.arduino),
            _program.name,
            origin: origin,
          );
          if (path != null && mounted) _snack(tr.sketchSaved(path));
        case _MenuAction.shareFlow:
          await _save();
          await shareBytes(
            utf8.encode(encodeProgram(_program)),
            fileName: '$name.flow',
            mimeType: 'application/x-dbflow',
            origin: origin,
          );
        case _MenuAction.png:
          await shareBytes(
            await diagramPng(layout),
            fileName: '$name.png',
            mimeType: 'image/png',
            origin: origin,
          );
        case _MenuAction.svg:
          await shareBytes(
            utf8.encode(diagramSvg(layout, title: _program.name)),
            fileName: '$name.svg',
            mimeType: 'image/svg+xml',
            origin: origin,
          );
        case _MenuAction.pdf:
          final png = await diagramPng(layout);
          final lang = _program.isArduino ? CodeLanguage.arduino : CodeLanguage.pseudo;
          final pdf = await diagramPdf(
            title: _program.name,
            png: png,
            code: generateCode(_program, lang),
            codeTitle: lang == CodeLanguage.arduino ? tr.arduinoSketch : tr.codeLanguagePseudo,
            wiringPng: _program.arduino == null ? null : await boardPng(_program.arduino!),
            wiringLines: [
              for (final p in _program.arduino?.pins ?? const <PinConfig>[])
                tr.wiringLine(p.name, p.pin, p.mode.label),
            ],
          );
          await shareBytes(pdf, fileName: '$name.pdf', mimeType: 'application/pdf', origin: origin);
      }
    } on Object catch (e) {
      if (mounted) _snack(tr.operationFailed('$e'));
    }
  }

  Future<void> _openExercise() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExercisePage(
        program: _program,
        exercise: _program.exercise ?? Exercise(),
        onDone: _state.setExercise,
        onRemove: () => _state.setExercise(null),
      ),
    ),
  );

  Future<void> _verify() async {
    final e = _program.exercise;
    if (e == null) return;
    if (_state.issues.isNotEmpty) return _snack(tr.verifyFixFirst);
    if (e.cases.isEmpty) return _snack(tr.noCases);
    final results = checkExercise(_program);
    setState(() => _lastCheck = (_program, results));
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ExerciseResultsPage(results: results)));
  }

  Future<void> _openPins() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => ArduinoSetupPage(state: _state)));

  Future<BlockKind?> _pickKind() => showModalBottomSheet<BlockKind>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(tr.insertBlock, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            for (final k in BlockKind.available(_program.kind))
              ListTile(
                leading: _ShapeIcon(_kindShape(k)),
                title: Text(k.label),
                onTap: () => Navigator.pop(ctx, k),
              ),
          ],
        ),
      ),
    ),
  );

  static Shape _kindShape(BlockKind k) => switch (k) {
    BlockKind.declare => Shape.declare,
    BlockKind.assign => Shape.process,
    BlockKind.input || BlockKind.output => Shape.io,
    BlockKind.ifElse || BlockKind.whileLoop || BlockKind.doWhile => Shape.decision,
    BlockKind.forLoop => Shape.loop,
    BlockKind.comment => Shape.comment,
    BlockKind.digitalWrite ||
    BlockKind.analogWrite ||
    BlockKind.digitalRead ||
    BlockKind.analogRead => Shape.pinIo,
    BlockKind.delay => Shape.hardware,
  };

  // ------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final running = _run != null;
    final issues = _state.issues;
    final configIssues = issues[arduinoConfigId]?.length ?? 0;
    final totalIssues = issues.values.fold<int>(0, (n, l) => n + l.length) - configIssues;
    final arduino = _program.isArduino;
    final wide = MediaQuery.sizeOf(context).width >= wideLayoutWidth;
    final narrowBar = MediaQuery.sizeOf(context).width < 500;

    final dc = DiagramColors.of(context);
    final canvas = Container(
      key: _canvasKey,
      color: dc.background,
      child: FlowCanvas(
        layout: layout,
        controller: _transform,
        selectedId: running ? null : _state.selectedId,
        activeId: _run?.activeId,
        errorIds: running
            ? {if (_run!.status == RunStatus.failed && _run!.activeId != null) _run!.activeId!}
            : issues.keys.toSet(),
        showInserts: !running,
        onTapBlock: running ? null : (id) => _state.select(_isBlock(id) ? id : null),
        onDoubleTapBlock: running ? null : (id) => _isBlock(id) ? _edit(id) : null,
        onLongPressBlock: running
            ? null
            : (id) {
                if (_isBlock(id)) _state.select(id);
              },
        onInsert: running ? null : _insert,
        onTapEmpty: running ? null : () => _state.select(null),
      ),
    );

    Widget body;
    if (running) {
      final panel = RunPanel(run: _run!, compact: !wide);
      body = wide
          ? Row(
              children: [
                Expanded(child: canvas),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: math.min(380, MediaQuery.sizeOf(context).width * 0.4),
                  child: panel,
                ),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 5, child: canvas),
                const Divider(height: 1),
                Expanded(flex: 6, child: panel),
              ],
            );
    } else {
      body = Column(
        children: [
          if (configIssues > 0)
            Material(
              color: dc.error.withValues(alpha: 0.08),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.settings_input_component, color: dc.error),
                title: Text(tr.pinIssues(configIssues)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openPins,
              ),
            ),
          if (totalIssues > 0)
            Material(
              color: dc.error.withValues(alpha: 0.08),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.error_outline, color: dc.error),
                title: Text(tr.blockIssues(totalIssues)),
              ),
            ),
          if (_program.exercise case final e?)
            ExerciseBanner(
              exercise: e,
              onOpen: _openExercise,
              onVerify: _verify,
              lastResult: switch (_lastCheck) {
                (final p, final r) when identical(p, _program) => (
                  r.where((c) => c.passed).length,
                  r.length,
                ),
                _ => null,
              },
            ),
          Expanded(child: canvas),
          if (_state.selected case final sel?) _selectionBar(sel, issues[sel.id] ?? const []),
        ],
      );
    }

    final scaffold = Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _rename,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(_program.name, overflow: TextOverflow.ellipsis)),
              if (!running) ...[const SizedBox(width: 6), const Icon(Icons.edit, size: 16)],
            ],
          ),
        ),
        actions: [
          if (!running) ...[
            IconButton(
              tooltip: tr.undo,
              icon: const Icon(Icons.undo),
              onPressed: _state.canUndo ? _state.undo : null,
            ),
            IconButton(
              tooltip: tr.redo,
              icon: const Icon(Icons.redo),
              onPressed: _state.canRedo ? _state.redo : null,
            ),
          ],
          // Arduino: pin e scheda accanto a «Esegui» (la simulazione)
          if (arduino && !running)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: narrowBar
                  ? IconButton.filledTonal(
                      tooltip: tr.pinsAndBoard,
                      onPressed: _openPins,
                      icon: const Icon(Icons.settings_input_component),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: _openPins,
                      icon: const Icon(Icons.settings_input_component),
                      label: Text(tr.pin),
                    ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: switch ((running, narrowBar)) {
              (true, true) => IconButton.filledTonal(
                tooltip: tr.backToEdit,
                onPressed: _toggleRun,
                icon: const Icon(Icons.edit),
              ),
              (true, false) => FilledButton.tonalIcon(
                onPressed: _toggleRun,
                icon: const Icon(Icons.edit),
                label: Text(tr.edit),
              ),
              // Colore esplicito: il tema delle icone dell'AppBar coprirebbe
              // quello del pulsante pieno (icona scura sul fondo blu).
              (false, true) => IconButton.filled(
                tooltip: tr.run,
                onPressed: _toggleRun,
                icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.onPrimary),
              ),
              (false, false) => FilledButton.icon(
                onPressed: _toggleRun,
                icon: const Icon(Icons.play_arrow),
                label: Text(tr.run),
              ),
            },
          ),
          PopupMenuButton<_MenuAction>(
            key: _menuKey,
            tooltip: tr.more,
            onSelected: _menu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.fit,
                child: ListTile(leading: Icon(Icons.fit_screen), title: Text(tr.centerDiagram)),
              ),
              PopupMenuItem(
                value: _MenuAction.code,
                child: ListTile(leading: Icon(Icons.code), title: Text(tr.code)),
              ),
              if (arduino)
                PopupMenuItem(
                  value: _MenuAction.pins,
                  child: ListTile(
                    leading: Icon(Icons.settings_input_component),
                    title: Text(tr.pinsAndBoard),
                  ),
                ),
              if (!arduino)
                PopupMenuItem(
                  value: _MenuAction.exercise,
                  child: ListTile(
                    leading: Icon(Icons.assignment_outlined),
                    title: Text(switch (_program.exercise) {
                      null => tr.exerciseCreate,
                      Exercise(locked: true) => tr.exerciseText,
                      _ => tr.exerciseEdit,
                    }),
                  ),
                ),
              PopupMenuDivider(),
              if (arduino)
                PopupMenuItem(
                  value: _MenuAction.sketch,
                  child: ListTile(
                    leading: Icon(Icons.memory),
                    title: Text(tr.arduinoSketchFile),
                    subtitle: Text(tr.arduinoSketchHelp),
                  ),
                ),
              if (_program.exercise case Exercise(locked: false))
                PopupMenuItem(
                  value: _MenuAction.shareExercise,
                  child: ListTile(
                    leading: Icon(Icons.assignment_ind_outlined),
                    title: Text(isDesktop ? tr.saveExercise : tr.shareExercise),
                    subtitle: Text(tr.shareExerciseHelp),
                  ),
                ),
              PopupMenuItem(
                value: _MenuAction.shareFlow,
                child: ListTile(
                  leading: Icon(isDesktop ? Icons.save_alt : Icons.ios_share),
                  title: Text(isDesktop ? tr.saveFlowFile : tr.shareFlowFile),
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.png,
                child: ListTile(leading: Icon(Icons.image_outlined), title: Text(tr.exportPng)),
              ),
              PopupMenuItem(
                value: _MenuAction.svg,
                child: ListTile(leading: Icon(Icons.polyline_outlined), title: Text(tr.exportSvg)),
              ),
              PopupMenuItem(
                value: _MenuAction.pdf,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text(tr.exportPdf),
                ),
              ),
            ],
          ),
        ],
      ),
      body: body,
    );
    return CallbackShortcuts(
      bindings: _shortcuts(running),
      child: Focus(autofocus: true, child: scaffold),
    );
  }

  Widget _selectionBar(Stmt sel, List<Issue> blockIssues) {
    final pos = locate(_program, sel.id);
    final canUp = pos != null && pos.slot.index > 0;
    final canDown = pos != null && pos.slot.index < pos.length - 1;
    final scheme = Theme.of(context).colorScheme;
    final error = DiagramColors.of(context).error;
    return Material(
      elevation: 8,
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final i in blockIssues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 18, color: error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(i.message, style: TextStyle(color: error)),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      blockTitle(sel),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: tr.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(sel.id),
                  ),
                  IconButton(
                    tooltip: tr.duplicate,
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () => _state.duplicate(sel.id),
                  ),
                  IconButton(
                    tooltip: tr.moveUp,
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: canUp ? () => _state.move(sel.id, -1) : null,
                  ),
                  IconButton(
                    tooltip: tr.moveDown,
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: canDown ? () => _state.move(sel.id, 1) : null,
                  ),
                  IconButton(
                    tooltip: tr.delete,
                    icon: Icon(Icons.delete_outline, color: error),
                    onPressed: () => _delete(sel.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeIcon extends StatelessWidget {
  const _ShapeIcon(this.shape);
  final Shape shape;

  @override
  Widget build(BuildContext context) {
    final colors = DiagramColors.of(context).shape(shape);
    final h = shape == Shape.decision ? 26.0 : 20.0;
    return SizedBox(
      width: 40,
      height: 28,
      child: Center(
        child: CustomPaint(
          size: Size(40, h),
          painter: _MiniShapePainter(shape, colors.fill, colors.stroke),
        ),
      ),
    );
  }
}

class _MiniShapePainter extends CustomPainter {
  _MiniShapePainter(this.shape, this.fill, this.stroke);
  final Shape shape;
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shapePath(shape, size, skew: 6, hexInset: 7);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_MiniShapePainter old) =>
      old.shape != shape || old.fill != fill || old.stroke != stroke;
}
