import 'package:flutter/material.dart';

import '../arduino/board.dart';
import '../arduino/pin_assign.dart';
import '../arduino/pin_suggestions.dart';
import '../codegen/generator.dart';
import '../editor/editor_state.dart';
import '../expr/lexer.dart';
import '../i18n/tr.dart';
import '../layout/layout_engine.dart';
import '../model/stmt.dart';
import '../model/validator.dart';
import '../render/board_painter.dart';
import '../render/theme.dart';

/// Helper "Pin e scheda": configura scheda, seriale e pin; genera `setup()`.
class ArduinoSetupPage extends StatefulWidget {
  const ArduinoSetupPage({super.key, required this.state});

  final EditorState state;

  @override
  State<ArduinoSetupPage> createState() => _ArduinoSetupPageState();
}

class _ArduinoSetupPageState extends State<ArduinoSetupPage> {
  EditorState get st => widget.state;
  ArduinoConfig get cfg => st.program.arduino!;

  @override
  void initState() {
    super.initState();
    st.addListener(_changed);
  }

  @override
  void dispose() {
    st.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  void _setPins(List<PinConfig> pins) => st.setArduino(cfg.copyWith(pins: pins));

  /// Codice di `setup()` generato, per l'anteprima.
  String get _setupPreview {
    final code = generateCode(st.program, CodeLanguage.arduino);
    final start = code.indexOf('void setup() {');
    final end = code.indexOf('\n}\n', start);
    final pins = [for (final p in cfg.pins) 'const int ${p.name} = ${p.pin};'];
    return [...pins, if (pins.isNotEmpty) '', code.substring(start, end + 2)].join('\n');
  }

  /// Tocco su un pin del disegno: modifica quello configurato o ne crea uno nuovo.
  void _tapPin(String pin) {
    final existing = cfg.pins.where((p) => cfg.board.samePin(p.pin, pin)).firstOrNull;
    _editPin(existing: existing, presetPin: existing == null ? pin : null);
  }

  Future<void> _editPin({PinConfig? existing, PinSuggestion? suggestion, String? presetPin}) async {
    final pwmNames = pwmPinNames(st.program);
    final result = await showDialog<PinConfig>(
      context: context,
      builder: (_) => _PinDialog(
        config: cfg,
        pwmNames: pwmNames,
        needsPwm:
            (suggestion?.pwm ?? false) || (existing != null && pwmNames.contains(existing.name)),
        existing: existing,
        suggestion: suggestion,
        presetPin: presetPin,
        reservedNames: {
          for (final s in st.program.allStmts)
            if (s case Declare(:final name)) name,
        },
      ),
    );
    if (result == null) return;
    final plan = planPin(cfg, existing, result, pwmNames: pwmNames);
    if (!plan.ok) return; // il dialog impedisce già le scelte impossibili
    _setPins(plan.pins);
    if (plan.displaced case final d? when mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr.pinMoved(d.name, plan.displacedTo!)),
            action: SnackBarAction(label: tr.undo, onPressed: st.undo),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = cfg.board;
    final issues = validate(st.program).where((i) => i.blockId == arduinoConfigId).toList();
    final suggestions = suggestPins(st.program);
    final theme = Theme.of(context);
    final dc = DiagramColors.of(context);
    Widget section(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(t, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.pinsAndBoard),
        actions: [
          IconButton(
            tooltip: tr.undo,
            icon: const Icon(Icons.undo),
            onPressed: st.canUndo ? st.undo : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPin(),
        icon: const Icon(Icons.add),
        label: Text(tr.addPin),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          section(tr.board),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: cfg.boardId,
                    decoration: InputDecoration(labelText: tr.board),
                    items: [
                      for (final b in boards.values)
                        DropdownMenuItem(value: b.id, child: Text(b.name)),
                    ],
                    onChanged: (v) => st.setArduino(cfg.copyWith(boardId: v)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: cfg.baud,
                    decoration: InputDecoration(labelText: tr.serialBaud),
                    items: [
                      for (final b in baudRates) DropdownMenuItem(value: b, child: Text('$b')),
                    ],
                    onChanged: (v) => st.setArduino(cfg.copyWith(baud: v)),
                  ),
                ),
              ],
            ),
          ),
          if (issues.isNotEmpty) ...[
            section(tr.toFix),
            for (final i in issues)
              ListTile(
                dense: true,
                leading: Icon(Icons.error_outline, color: dc.error),
                title: Text(i.message, style: TextStyle(color: dc.error)),
              ),
          ],
          if (suggestions.isNotEmpty) ...[
            section(tr.usedNotConfigured),
            for (final sg in suggestions)
              ListTile(
                leading: Icon(Icons.lightbulb_outline, color: dc.warning),
                title: Text(tr.suggestionTitle(sg.name, sg.component.label, sg.pin)),
                subtitle: Text(tr.usedIn(sg.reason), style: monoStyle.copyWith(fontSize: 12)),
                trailing: FilledButton.tonal(
                  onPressed: () => _editPin(suggestion: sg),
                  child: Text(tr.add),
                ),
              ),
          ],
          if (board.drawing != null) ...[
            section(tr.wiring),
            // Su schermi larghi (Mac, iPad) il disegno non occupa tutta la finestra.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BoardView(config: cfg, onPinTap: _tapPin),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.fromLTRB(16, 6, 16, 0), child: Text(tr.tapPinHint)),
          ],
          section(tr.configuredPins),
          if (cfg.pins.isEmpty) ListTile(title: Text(tr.noPins), subtitle: Text(tr.noPinsHint)),
          for (final p in cfg.pins)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: dc
                    .shape(p.mode == PinMode.output ? Shape.hardware : Shape.io)
                    .fill,
                child: Text(
                  p.pin,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dc.text),
                ),
              ),
              title: Row(
                children: [
                  Icon(componentIcon(p.component), size: 18, color: pinModeColor(p.mode)),
                  const SizedBox(width: 6),
                  Text(p.name, style: monoStyle.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Text(
                '${p.component == Component.other ? '' : '${p.component.label} · '}'
                '${p.mode.label}${board.pwmPins.contains(p.pin) ? ' · ${tr.pwmTag}' : ''}'
                '${p.pin == board.ledBuiltin ? ' · ${tr.onBoardLed}' : ''}',
              ),
              onTap: () => _editPin(existing: p),
              trailing: IconButton(
                tooltip: tr.removePin(p.name),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _setPins([...cfg.pins]..remove(p)),
              ),
            ),
          section(tr.generatedSetup),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                _setupPreview,
                style: monoStyle.copyWith(color: const Color(0xFFEDEDED)),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(tr.setupNote)),
        ],
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.config,
    required this.reservedNames,
    this.pwmNames = const {},
    this.needsPwm = false,
    this.existing,
    this.suggestion,
    this.presetPin,
  });

  final ArduinoConfig config;
  final PinConfig? existing;
  final PinSuggestion? suggestion;

  /// Pin già scelto (toccato sul disegno della scheda).
  final String? presetPin;

  /// Nomi di variabili già dichiarate.
  final Set<String> reservedNames;

  /// Pin usati con `analogWrite` nel diagramma.
  final Set<String> pwmNames;

  /// Questo pin è usato con `analogWrite`: va su un pin PWM.
  final bool needsPwm;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late final _name = TextEditingController(
    text: widget.existing?.name ?? widget.suggestion?.name ?? '',
  )..addListener(() => setState(() {}));
  late String? _pin = widget.existing?.pin ?? widget.suggestion?.pin ?? widget.presetPin;

  late Component _component =
      widget.existing?.component ??
      widget.suggestion?.component ??
      (widget.presetPin != null && widget.config.board.isAnalog(widget.presetPin!)
          ? Component.potentiometer
          : Component.led);
  late PinMode _mode = widget.existing?.mode ?? widget.suggestion?.mode ?? _component.defaultMode;

  Board get board => widget.config.board;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _nameError {
    final n = _name.text.trim();
    if (n.isEmpty) return null;
    final e = checkIdentifier(n);
    if (e != null) return e;
    final others = widget.config.pins.where((p) => !identical(p, widget.existing));
    if (others.any((p) => p.name == n)) return tr.pinNameExists;
    if (widget.reservedNames.contains(n)) return tr.variableNameExists;
    return null;
  }

  /// Modi possibili per il componente sul pin scelto.
  List<PinMode> get _modes => [
    for (final m in _component.modes)
      if (_pin == null || board.modesFor(_pin!).contains(m)) m,
  ];

  void _chooseComponent(Component c) => setState(() {
    _component = c;
    if (!c.modes.contains(_mode)) _mode = c.defaultMode;
    if (_pin != null && !c.fits(board, _pin!, _mode)) {
      final m = c.modes.where((m) => board.modesFor(_pin!).contains(m)).firstOrNull;
      if (m != null) {
        _mode = m;
      } else {
        _pin = null;
      }
    }
  });

  void _choosePin(String pin) => setState(() {
    _pin = pin;
    if (!board.modesFor(pin).contains(_mode)) {
      _mode = _modes.firstOrNull ?? _mode;
    }
  });

  PinConfig? get _result => _pin == null
      ? null
      : PinConfig(name: _name.text.trim(), pin: _pin!, mode: _mode, component: _component);

  /// Cosa succede agli altri pin con la scelta attuale.
  PinPlan? get _plan => _result == null
      ? null
      : planPin(widget.config, widget.existing, _result!, pwmNames: widget.pwmNames);

  /// Il pin va bene per il componente e, se serve, ha il PWM.
  bool _suits(String pin) =>
      _component.modes.any((m) => board.modesFor(pin).contains(m)) &&
      (!widget.needsPwm || board.pwmPins.contains(pin));

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _nameError == null &&
      _pin != null &&
      _component.fits(board, _pin!, _mode) &&
      (!widget.needsPwm || board.pwmPins.contains(_pin)) &&
      (_plan?.ok ?? false);

  static IconData iconFor(Component c) => componentIcon(c);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = DiagramColors.of(context);
    final plan = _plan;
    String? notice;
    var noticeIsError = false;
    if (plan?.displaced case final d?) {
      switch (plan!.error) {
        case PinPlanError.cannotSwap:
          notice = tr.pinCannotSwap(d.name, widget.existing!.pin);
          noticeIsError = true;
        case PinPlanError.cannotMove:
          notice = tr.pinCannotMove(d.name);
          noticeIsError = true;
        case null:
          notice = plan.swapped
              ? tr.pinSwapNotice(d.name, plan.displacedTo!)
              : tr.pinMoveNotice(d.name, plan.displacedTo!);
      }
    }
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(t, style: theme.textTheme.labelLarge),
    );

    return AlertDialog(
      title: Text(widget.existing == null ? tr.newPin : tr.editPin),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.existing == null && widget.suggestion == null,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: tr.name,
                hintText: tr.hintPinName,
                errorText: _nameError,
                errorMaxLines: 2,
              ),
            ),
            label(tr.whatToConnect),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final c in Component.values)
                  ChoiceChip(
                    avatar: Icon(iconFor(c), size: 18),
                    label: Text(c.label),
                    selected: _component == c,
                    onSelected: (_) => _chooseComponent(c),
                  ),
              ],
            ),
            if (_modes.length > 1) ...[
              label(tr.mode),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final m in _modes)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _mode == m,
                      onSelected: (_) => setState(() => _mode = m),
                    ),
                ],
              ),
            ],
            if (_mode == PinMode.inputPullup)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(tr.pullupNote, style: theme.textTheme.bodySmall),
              ),
            label(tr.digitalPinsTitle),
            if (widget.needsPwm)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tr.pwmNeeded, style: theme.textTheme.bodySmall),
              ),
            _grid(board.digitalPins),
            label(tr.analogPinsTitle),
            _grid(board.analogPins),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      noticeIsError ? Icons.error_outline : Icons.swap_horiz,
                      size: 20,
                      color: noticeIsError ? dc.error : dc.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notice,
                        style: TextStyle(color: noticeIsError ? dc.error : dc.warning),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr.cancel)),
        FilledButton(
          onPressed: _valid ? () => Navigator.pop(context, _result) : null,
          child: Text(widget.existing == null ? tr.add : tr.save),
        ),
      ],
    );
  }

  /// Pin come tasti: liberi, occupati (con il nome di chi li usa), non adatti.
  Widget _grid(List<String> pins) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final pin in pins)
          Builder(
            builder: (context) {
              final occupant = widget.config.pins
                  .where((p) => board.samePin(p.pin, pin) && !identical(p, widget.existing))
                  .firstOrNull;
              final fits = _suits(pin);
              final selected = pin == _pin;
              final pwm = board.pwmPins.contains(pin);
              final sub =
                  occupant?.name ??
                  (board.serialPins.contains(pin)
                      ? tr.serialTag
                      : pin == board.ledBuiltin
                      ? 'LED'
                      : pwm
                      ? 'PWM'
                      : '');
              final color = occupant == null ? scheme.outline : pinModeColor(occupant.mode);
              return Semantics(
                button: true,
                selected: selected,
                enabled: fits,
                label: occupant == null ? 'pin $pin' : 'pin $pin, ${occupant.name}',
                child: Material(
                  color: selected
                      ? scheme.primary
                      : (occupant != null ? color.withValues(alpha: 0.12) : null),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected ? scheme.primary : (fits ? color : scheme.outlineVariant),
                      width: selected || occupant != null ? 1.6 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: fits ? () => _choosePin(pin) : null,
                    child: SizedBox(
                      width: 56,
                      height: 46,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pwm ? '~$pin' : pin,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? scheme.onPrimary
                                  : (fits ? null : scheme.outlineVariant),
                            ),
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? scheme.onPrimary
                                    : (occupant != null ? color : scheme.onSurfaceVariant),
                                fontWeight: occupant != null ? FontWeight.w600 : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
