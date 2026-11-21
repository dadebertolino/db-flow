/// File `.flow` (JSON) ↔ [Program]. Dart puro.
///
/// Le espressioni si salvano come testo sorgente e si riparsano in apertura.
library;

import 'dart:convert';

import '../arduino/board.dart';
import '../i18n/tr.dart';
import 'exercise.dart';
import 'expr.dart';
import 'ids.dart';
import 'program.dart';
import 'stmt.dart';

const formatTag = 'db-flow';

/// File `.flow` non leggibile. Il messaggio è in italiano, per l'utente.
final class FlowFormatException implements Exception {
  const FlowFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------- scrittura

String encodeProgram(Program p) => const JsonEncoder.withIndent('  ').convert(programToJson(p));

Map<String, Object?> programToJson(Program p) => {
  'format': formatTag,
  'version': Program.formatVersion,
  'name': p.name,
  'kind': p.kind.name,
  if (p.arduino case final a?) 'arduino': arduinoToJson(a),
  if (p.isArduino) 'setup': _listToJson(p.setup),
  'body': _listToJson(p.body),
  if (p.exercise case final e?) 'exercise': exerciseToJson(e),
};

Map<String, Object?> exerciseToJson(Exercise e) => {
  'text': e.text,
  if (e.locked) 'locked': true,
  'cases': [
    for (final c in e.cases) {'in': c.inputs, 'out': c.expected, if (c.hidden) 'hidden': true},
  ],
};

/// Esercizio dal JSON; le parti malformate si scartano senza errori.
Exercise? exerciseFromJson(Object? json) {
  if (json is! Map<String, Object?>) return null;
  List<String> strings(Object? l) => [
    if (l is List<Object?>)
      for (final x in l)
        if (x is String) x else if (x is num || x is bool) '$x',
  ];
  final cases = json['cases'];
  final text = json['text'];
  return Exercise(
    text: text is String ? text : '',
    locked: json['locked'] == true,
    cases: [
      if (cases is List<Object?>)
        for (final c in cases)
          if (c is Map<String, Object?>)
            TestCase(
              inputs: strings(c['in']),
              expected: strings(c['out']),
              hidden: c['hidden'] == true,
            ),
    ],
  );
}

Map<String, Object?> arduinoToJson(ArduinoConfig a) => {
  'board': a.boardId,
  'baud': a.baud,
  'pins': [
    for (final pin in a.pins)
      {
        'name': pin.name,
        'pin': pin.pin,
        'mode': pin.mode.name,
        if (pin.component != Component.other) 'component': pin.component.name,
      },
  ],
};

List<Map<String, Object?>> _listToJson(List<Stmt> stmts) => [for (final s in stmts) stmtToJson(s)];

Map<String, Object?> stmtToJson(Stmt s) => {
  'id': s.id,
  ...switch (s) {
    Declare(:final name, :final type) => {'t': 'declare', 'name': name, 'type': type.name},
    Assign(:final target, :final value) => {'t': 'assign', 'target': target, 'value': value.text},
    Input(:final variable) => {'t': 'input', 'var': variable},
    Output(:final value) => {'t': 'output', 'value': value.text},
    If(:final cond, :final then, :final otherwise) => {
      't': 'if',
      'cond': cond.text,
      'then': _listToJson(then),
      'else': _listToJson(otherwise),
    },
    While(:final cond, :final body) => {'t': 'while', 'cond': cond.text, 'body': _listToJson(body)},
    DoWhile(:final body, :final cond) => {
      't': 'dowhile',
      'body': _listToJson(body),
      'cond': cond.text,
    },
    For(:final variable, :final from, :final to, :final step, :final body) => {
      't': 'for',
      'var': variable,
      'from': from.text,
      'to': to.text,
      'step': step.text,
      'body': _listToJson(body),
    },
    Comment(:final text) => {'t': 'comment', 'text': text},
    DigitalWrite(:final pin, :final value) => {
      't': 'digitalWrite',
      'pin': pin.text,
      'value': value.text,
    },
    AnalogWrite(:final pin, :final value) => {
      't': 'analogWrite',
      'pin': pin.text,
      'value': value.text,
    },
    Delay(:final ms) => {'t': 'delay', 'ms': ms.text},
    DigitalRead(:final variable, :final pin) => {
      't': 'digitalRead',
      'var': variable,
      'pin': pin.text,
    },
    AnalogRead(:final variable, :final pin) => {
      't': 'analogRead',
      'var': variable,
      'pin': pin.text,
    },
  },
};

// ---------------------------------------------------------------- lettura

Program decodeProgram(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException {
    throw FlowFormatException(tr.fileDamaged);
  }
  if (json is! Map<String, Object?>) {
    throw FlowFormatException(tr.fileNotFlow);
  }
  return programFromJson(json);
}

Program programFromJson(Map<String, Object?> json) {
  if (json['format'] != formatTag) {
    throw FlowFormatException(tr.fileNotFlow);
  }
  final migrated = _migrate(json);
  final reader = _Reader();
  final kindName = migrated['kind'];
  final kind = ProgramKind.fromName(kindName is String ? kindName : null);
  return Program(
    name: reader.string(migrated, 'name', fallback: tr.untitled),
    kind: kind,
    setup: kind == ProgramKind.arduino ? reader.list(migrated, 'setup') : const [],
    body: reader.list(migrated, 'body'),
    arduino: kind == ProgramKind.arduino ? _arduinoFromJson(migrated['arduino']) : null,
    exercise: exerciseFromJson(migrated['exercise']),
  );
}

ArduinoConfig _arduinoFromJson(Object? json) {
  if (json is! Map<String, Object?>) return ArduinoConfig();
  final pins = <PinConfig>[];
  final list = json['pins'];
  if (list is List<Object?>) {
    for (final p in list) {
      if (p is! Map<String, Object?>) continue;
      final name = p['name'], pin = p['pin'], mode = PinMode.fromName('${p['mode']}');
      if (name is String && pin is String && mode != null) {
        pins.add(
          PinConfig(
            name: name,
            pin: pin,
            mode: mode,
            component: Component.fromName('${p['component']}'),
          ),
        );
      }
    }
  }
  final board = json['board'];
  final baud = json['baud'];
  return ArduinoConfig(
    boardId: board is String && boards.containsKey(board) ? board : 'uno',
    baud: baud is int && baud > 0 ? baud : 9600,
    pins: pins,
  );
}

/// Porta il JSON alla versione corrente del formato. Ogni nuova versione
/// aggiunge qui il proprio passo (v1 → v2, v2 → v3, ...).
Map<String, Object?> _migrate(Map<String, Object?> json) {
  final version = json['version'];
  if (version is! int || version < 1) {
    throw FlowFormatException(tr.fileBadVersion);
  }
  if (version > Program.formatVersion) {
    throw FlowFormatException(tr.fileTooNew);
  }
  var m = json;
  if (version < 2) m = {...m, 'version': 2, 'kind': 'algorithm'}; // v1 → v2: solo algoritmi
  return m;
}

final class _Reader {
  /// Id già incontrati: id mancanti o duplicati vengono rigenerati.
  final _seen = <String>{};

  String string(Map<String, Object?> m, String key, {String? fallback}) {
    final v = m[key];
    if (v is String) return v;
    if (fallback != null && v == null) return fallback;
    throw FlowFormatException(tr.fileFieldMissing(key));
  }

  ExprSource expr(Map<String, Object?> m, String key) => ExprSource(string(m, key));

  List<Stmt> list(Map<String, Object?> m, String key) {
    final v = m[key] ?? const <Object?>[];
    if (v is! List<Object?>) {
      throw FlowFormatException(tr.fileFieldInvalid(key));
    }
    return [for (final item in v) stmt(item)];
  }

  String _id(Map<String, Object?> m) {
    final v = m['id'];
    final id = v is String && v.isNotEmpty && !_seen.contains(v) ? v : _freshId();
    _seen.add(id);
    return id;
  }

  String _freshId() {
    var id = newId();
    while (_seen.contains(id)) {
      id = newId();
    }
    return id;
  }

  Stmt stmt(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FlowFormatException(tr.fileBadBlock);
    }
    final id = _id(json);
    final t = json['t'];
    return switch (t) {
      'declare' => Declare(id: id, name: string(json, 'name'), type: _type(json)),
      'assign' => Assign(id: id, target: string(json, 'target'), value: expr(json, 'value')),
      'input' => Input(id: id, variable: string(json, 'var')),
      'output' => Output(id: id, value: expr(json, 'value')),
      'if' => If(
        id: id,
        cond: expr(json, 'cond'),
        then: list(json, 'then'),
        otherwise: list(json, 'else'),
      ),
      'while' => While(id: id, cond: expr(json, 'cond'), body: list(json, 'body')),
      'dowhile' => DoWhile(id: id, body: list(json, 'body'), cond: expr(json, 'cond')),
      'for' => For(
        id: id,
        variable: string(json, 'var'),
        from: expr(json, 'from'),
        to: expr(json, 'to'),
        step: ExprSource(string(json, 'step', fallback: '1')),
        body: list(json, 'body'),
      ),
      'comment' => Comment(
        id: id,
        text: string(json, 'text', fallback: ''),
      ),
      'digitalWrite' => DigitalWrite(id: id, pin: expr(json, 'pin'), value: expr(json, 'value')),
      'analogWrite' => AnalogWrite(id: id, pin: expr(json, 'pin'), value: expr(json, 'value')),
      'delay' => Delay(id: id, ms: expr(json, 'ms')),
      'digitalRead' => DigitalRead(id: id, variable: string(json, 'var'), pin: expr(json, 'pin')),
      'analogRead' => AnalogRead(id: id, variable: string(json, 'var'), pin: expr(json, 'pin')),
      _ => throw FlowFormatException(tr.fileUnknownBlock('$t')),
    };
  }

  VarType _type(Map<String, Object?> m) {
    final name = string(m, 'type');
    return VarType.fromName(name) ?? (throw FlowFormatException(tr.fileUnknownType(name)));
  }
}
