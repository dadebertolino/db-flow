import 'package:flutter/material.dart';

import '../arduino/board.dart';
import '../expr/errors.dart';
import '../expr/lexer.dart';
import '../expr/type_checker.dart';
import '../i18n/tr.dart';
import '../model/expr.dart';
import '../model/stmt.dart';
import '../model/validator.dart' show arduinoConstantTypes;

/// Apre il dialog di modifica di [stmt]. Restituisce il blocco aggiornato
/// (stesso id, stessi rami) oppure `null` se l'utente annulla.
Future<Stmt?> showBlockEditor(
  BuildContext context, {
  required Stmt stmt,
  required Map<String, VarType> variables,
  ArduinoConfig? arduino,
  bool isNew = false,
}) => showDialog<Stmt>(
  context: context,
  builder: (_) => _BlockEditor(stmt: stmt, variables: variables, arduino: arduino, isNew: isNew),
);

String blockTitle(Stmt s) => switch (s) {
  Declare() => tr.blockDeclare,
  Assign() => tr.blockAssign,
  Input() => tr.blockInput,
  Output() => tr.blockOutput,
  If() => tr.blockIf,
  While() => tr.blockWhile,
  DoWhile() => tr.blockDoWhile,
  For() => tr.blockFor,
  Comment() => tr.blockComment,
  DigitalWrite() => tr.blockDigitalWrite,
  AnalogWrite() => tr.blockAnalogWrite,
  Delay() => tr.blockDelay,
  DigitalRead() => tr.blockDigitalRead,
  AnalogRead() => tr.blockAnalogRead,
};

class _BlockEditor extends StatefulWidget {
  const _BlockEditor({
    required this.stmt,
    required this.variables,
    required this.arduino,
    required this.isNew,
  });

  final Stmt stmt;

  /// Variabili dichiarate (senza le costanti di Arduino).
  final Map<String, VarType> variables;

  /// Configurazione dei pin, per i diagrammi Arduino.
  final ArduinoConfig? arduino;
  final bool isNew;

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  /// Campi di testo, per nome (name, value, cond, from, to, step, text).
  final _text = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};

  /// Campi "variabile" (target, var).
  String? _variable;
  VarType _type = VarType.integer;

  /// Pin scelto (blocchi digitalWrite / analogWrite).
  String? _pin;

  /// Campo espressione attivo, destinatario della barra dei simboli.
  String? _activeExpr;

  Stmt get s => widget.stmt;

  /// Variabili e costanti visibili nelle espressioni.
  late final Map<String, VarType> _scope = {
    if (widget.arduino case final a?) ...arduinoConstantTypes(a),
    ...widget.variables,
  };

  @override
  void initState() {
    super.initState();
    void field(String key, String value, {bool expr = false}) {
      _text[key] = TextEditingController(text: value)..addListener(() => setState(() {}));
      final f = _focus[key] = FocusNode();
      if (expr) {
        f.addListener(() {
          if (f.hasFocus) setState(() => _activeExpr = key);
        });
      }
    }

    switch (s) {
      case Declare(:final name, :final type):
        field('name', name);
        _type = type;
      case Assign(:final target, :final value):
        _variable = target;
        field('value', value.text, expr: true);
      case Input(:final variable):
        _variable = variable;
      case Output(:final value):
        field('value', value.text, expr: true);
      case If(:final cond) || While(:final cond) || DoWhile(:final cond):
        field('cond', cond.text, expr: true);
      case For(:final variable, :final from, :final to, :final step):
        _variable = variable;
        field('from', from.text, expr: true);
        field('to', to.text, expr: true);
        field('step', step.text, expr: true);
      case Comment(:final text):
        field('text', text);
      case DigitalWrite(:final pin, :final value) || AnalogWrite(:final pin, :final value):
        _pin = pin.text.trim().isEmpty ? null : pin.text.trim();
        field('value', value.text, expr: true);
      case Delay(:final ms):
        field('ms', ms.text, expr: true);
      case DigitalRead(:final variable, :final pin) || AnalogRead(:final variable, :final pin):
        _variable = variable;
        _pin = pin.text.trim().isEmpty ? null : pin.text.trim();
    }
    if (_pin == null && _usesPin) _pin = _pinChoices.firstOrNull?.name;
    if ((_variable == null || _variable == '') && (s is DigitalRead || s is AnalogRead)) {
      _variable = widget.variables.entries
          .where((e) => e.value == VarType.integer)
          .firstOrNull
          ?.key;
    }
    if (_variable == '') _variable = null;
    if (_variable == null && s is Input && widget.variables.isNotEmpty) {
      _variable = widget.variables.keys.first;
    }
    _activeExpr = _text.keys.where((k) => k != 'name' && k != 'text').firstOrNull;
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _t(String key) => _text[key]!.text.trim();
  ExprSource _e(String key) => ExprSource(_t(key));

  bool get _canSave => switch (s) {
    Declare() => _t('name').isNotEmpty,
    Assign() => _variable != null && _t('value').isNotEmpty,
    Input() => _variable != null,
    Output() => _t('value').isNotEmpty,
    If() || While() || DoWhile() => _t('cond').isNotEmpty,
    For() => _variable != null && _t('from').isNotEmpty && _t('to').isNotEmpty,
    Comment() => _t('text').isNotEmpty,
    DigitalWrite() || AnalogWrite() => _pin != null && _t('value').isNotEmpty,
    DigitalRead() || AnalogRead() => _pin != null && _variable != null,
    Delay() => _t('ms').isNotEmpty,
  };

  Stmt _build() => switch (s) {
    Declare(:final id) => Declare(id: id, name: _t('name'), type: _type),
    Assign(:final id) => Assign(id: id, target: _variable!, value: _e('value')),
    Input(:final id) => Input(id: id, variable: _variable!),
    Output(:final id) => Output(id: id, value: _e('value')),
    If(:final id, :final then, :final otherwise) => If(
      id: id,
      cond: _e('cond'),
      then: then,
      otherwise: otherwise,
    ),
    While(:final id, :final body) => While(id: id, cond: _e('cond'), body: body),
    DoWhile(:final id, :final body) => DoWhile(id: id, cond: _e('cond'), body: body),
    For(:final id, :final body) => For(
      id: id,
      variable: _variable!,
      from: _e('from'),
      to: _e('to'),
      step: _t('step').isEmpty ? null : _e('step'),
      body: body,
    ),
    Comment(:final id) => Comment(id: id, text: _t('text')),
    DigitalWrite(:final id) => DigitalWrite(id: id, pin: ExprSource(_pin!), value: _e('value')),
    AnalogWrite(:final id) => AnalogWrite(id: id, pin: ExprSource(_pin!), value: _e('value')),
    Delay(:final id) => Delay(id: id, ms: _e('ms')),
    DigitalRead(:final id) => DigitalRead(id: id, variable: _variable!, pin: ExprSource(_pin!)),
    AnalogRead(:final id) => AnalogRead(id: id, variable: _variable!, pin: ExprSource(_pin!)),
  };

  bool get _usesPin => s is DigitalWrite || s is AnalogWrite || s is DigitalRead || s is AnalogRead;

  /// Pin proponibili: le uscite (per analogWrite prima quelle PWM), gli
  /// ingressi per digitalRead, gli ingressi analogici per analogRead.
  List<PinConfig> get _pinChoices {
    final a = widget.arduino;
    if (a == null) return const [];
    if (s is DigitalRead) return a.pins.where((p) => p.mode.isInput).toList();
    if (s is AnalogRead) return a.pins.where((p) => p.mode == PinMode.analogInput).toList();
    final outputs = a.pins.where((p) => p.mode == PinMode.output).toList();
    if (s is AnalogWrite) {
      outputs.sort(
        (x, y) =>
            (a.board.pwmPins.contains(x.pin) ? 0 : 1) - (a.board.pwmPins.contains(y.pin) ? 0 : 1),
      );
    }
    return outputs;
  }

  /// Errore di sintassi o di tipo nell'espressione, mentre si scrive.
  String? _exprError(String key) {
    final text = _text[key]!.text;
    if (text.trim().isEmpty) return null;
    String show(ExprError e) => tr.column(e.column, e.message);
    final src = ExprSource(text);
    if (src.error case final e?) return show(e);
    try {
      typeOf(src.expr!, _scope, arduino: widget.arduino != null);
      return null;
    } on ExprError catch (e) {
      return show(e);
    }
  }

  void _insertSymbol(String sym) {
    final key = _activeExpr;
    if (key == null) return;
    final c = _text[key]!;
    final sel = c.selection.isValid ? c.selection : TextSelection.collapsed(offset: c.text.length);
    final before = c.text.substring(0, sel.start);
    final after = c.text.substring(sel.end);
    // Coppie ("" e "f()"): cursore in mezzo. Altri simboli: separati da spazi.
    final isPair = sym == '""' || (sym.endsWith('()') && sym != 'millis()');
    final pad = before.isNotEmpty && !before.endsWith(' ') && !before.endsWith('(');
    final ins = '${pad ? ' ' : ''}$sym${isPair ? '' : ' '}';
    final caret = before.length + ins.length - (isPair ? 1 : 0);
    c.value = TextEditingValue(
      text: before + ins + after,
      selection: TextSelection.collapsed(offset: caret),
    );
    _focus[key]!.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[];
    void gap() => fields.add(const SizedBox(height: 14));

    switch (s) {
      case Declare():
        fields.add(_nameField());
        gap();
        fields.add(_typeSelector());
      case Assign():
        fields.add(_variablePicker(tr.fieldVarToModify));
        gap();
        fields.add(_exprField('value', tr.fieldNewValue, tr.hintNewValue));
      case Input():
        fields.add(_variablePicker(tr.fieldVarToRead));
      case Output():
        fields.add(_exprField('value', tr.fieldWhatToWrite, tr.hintWrite));
      case If() || While() || DoWhile():
        fields.add(_exprField('cond', tr.fieldCondition, tr.hintCondition));
      case For():
        fields.add(_variablePicker(tr.fieldCounter, onlyInt: true));
        gap();
        fields.add(_exprField('from', tr.fieldFrom, tr.hintFrom));
        gap();
        fields.add(_exprField('to', tr.fieldTo, tr.hintTo));
        gap();
        fields.add(_exprField('step', tr.fieldStep, '1'));
      case Comment():
        fields.add(
          TextField(
            controller: _text['text'],
            autofocus: true,
            decoration: InputDecoration(labelText: tr.fieldCommentText),
          ),
        );
      case DigitalWrite():
        fields.add(_pinPicker());
        gap();
        fields.add(_exprField('value', tr.fieldValue, tr.hintHighLow));
      case AnalogWrite():
        fields.add(_pinPicker(pwm: true));
        gap();
        fields.add(_exprField('value', tr.fieldPwmValue, tr.hintPwm));
      case Delay():
        fields.add(_exprField('ms', tr.fieldDelayMs, tr.hintDelay));
      case DigitalRead() || AnalogRead():
        fields.add(_pinPicker());
        gap();
        fields.add(_variablePicker(tr.fieldReadTarget, onlyInt: true));
        gap();
        fields.add(
          Text(
            s is DigitalRead ? tr.readsDigital : tr.readsAnalog,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
    }

    if (_activeExpr != null) {
      gap();
      fields.add(_symbolBar());
    }

    return AlertDialog(
      title: Text(blockTitle(s)),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: fields),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr.cancel)),
        FilledButton(
          onPressed: _canSave ? () => Navigator.pop(context, _build()) : null,
          child: Text(widget.isNew ? tr.insert : tr.save),
        ),
      ],
    );
  }

  Widget _nameField() {
    final name = _t('name');
    String? error = name.isEmpty ? null : checkIdentifier(name);
    final original = s is Declare ? (s as Declare).name : '';
    if (error == null && name != original && widget.variables.containsKey(name)) {
      error = tr.varExists(name);
    }
    return TextField(
      controller: _text['name'],
      focusNode: _focus['name'],
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      decoration: InputDecoration(
        labelText: tr.fieldVarName,
        hintText: tr.hintVarName,
        errorText: error,
        errorMaxLines: 3,
      ),
    );
  }

  Widget _typeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr.fieldType, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final t in VarType.values)
            ChoiceChip(
              label: Text(t.label),
              selected: _type == t,
              onSelected: (_) => setState(() => _type = t),
            ),
        ],
      ),
    ],
  );

  Widget _variablePicker(String label, {bool onlyInt = false}) {
    final names = [
      for (final e in widget.variables.entries)
        if (!onlyInt || e.value == VarType.integer) e.key,
    ];
    if (_variable != null && !names.contains(_variable)) names.insert(0, _variable!);
    if (names.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          onlyInt ? tr.noIntegerVariables : tr.noVariables,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _variable,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final n in names)
          DropdownMenuItem(
            value: n,
            child: Text(
              widget.variables[n] == null
                  ? tr.notDeclared(n)
                  : '$n  ·  ${widget.variables[n]!.label}',
            ),
          ),
      ],
      onChanged: (v) => setState(() => _variable = v),
    );
  }

  Widget _pinPicker({bool pwm = false}) {
    final a = widget.arduino!;
    final choices = _pinChoices;
    final names = [for (final p in choices) p.name];
    if (_pin != null && !names.contains(_pin)) names.insert(0, _pin!);
    if (names.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(labelText: tr.pin),
        child: Text(
          '${switch (s) {
            DigitalRead() => tr.noInputPins,
            AnalogRead() => tr.noAnalogPins,
            _ => tr.noOutputPins,
          }}${tr.addFromPins}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    String describe(String n) {
      final p = a.pinNamed(n);
      if (p == null) return n;
      final noPwm = pwm && !a.board.pwmPins.contains(p.pin) ? tr.noPwmTag : '';
      return '$n  ·  pin ${p.pin}$noPwm';
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _pin,
      decoration: InputDecoration(
        labelText: tr.pin,
        helperText: pwm ? tr.pwmOn(a.board.name, _pwmList(a.board)) : null,
      ),
      items: [for (final n in names) DropdownMenuItem(value: n, child: Text(describe(n)))],
      onChanged: (v) => setState(() => _pin = v),
    );
  }

  static String _pwmList(Board b) =>
      (b.pwmPins.toList()..sort((x, y) => int.parse(x).compareTo(int.parse(y)))).join(', ');

  Widget _exprField(String key, String label, String hint) => TextField(
    controller: _text[key],
    focusNode: _focus[key],
    autofocus: _activeExpr == key,
    autocorrect: false,
    enableSuggestions: false,
    smartQuotesType: SmartQuotesType.disabled,
    smartDashesType: SmartDashesType.disabled,
    textCapitalization: TextCapitalization.none,
    style: const TextStyle(fontFamily: 'monospace', fontFamilyFallback: ['Menlo', 'Courier']),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: _exprError(key),
      errorMaxLines: 4,
    ),
  );

  Widget _symbolBar() {
    const symbols = [
      '<', '>', '==', '!=', '<=', '>=', //
      '+', '-', '*', '/', '%', '&', '()', '""', //
      'and', 'or', 'not',
    ];
    Widget chip(String label, {bool variable = false}) => ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontFamilyFallback: ['Menlo']),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: variable ? Theme.of(context).colorScheme.secondaryContainer : null,
      onPressed: () => _insertSymbol(label),
    );
    final arduino = widget.arduino;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final v in widget.variables.keys) chip(v, variable: true),
        if (arduino != null) ...[
          for (final p in arduino.pins) chip(p.name, variable: true),
          for (final sym in const ['HIGH', 'LOW', 'digitalRead()', 'analogRead()', 'millis()'])
            chip(sym),
        ],
        for (final sym in symbols) chip(sym),
      ],
    );
  }
}
