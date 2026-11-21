/// Operazioni di modifica: ognuna riceve un [Program] e ne restituisce uno nuovo.
/// Dart puro (nessun import di Flutter), testabile senza UI.
library;

import '../i18n/tr.dart';
import '../model/expr.dart';
import '../model/ids.dart';
import '../model/program.dart';
import '../model/slot.dart';
import '../model/stmt.dart';

typedef _ListEdit = List<Stmt> Function(List<Stmt> list, String? parentId, Branch branch);

List<Stmt> _rewriteList(List<Stmt> list, String? parentId, Branch branch, _ListEdit f) =>
    f([for (final s in list) _rewriteStmt(s, f)], parentId, branch);

Stmt _rewriteStmt(Stmt s, _ListEdit f) => switch (s) {
  If() => If(
    id: s.id,
    cond: s.cond,
    then: _rewriteList(s.then, s.id, Branch.then, f),
    otherwise: _rewriteList(s.otherwise, s.id, Branch.otherwise, f),
  ),
  While() => While(id: s.id, cond: s.cond, body: _rewriteList(s.body, s.id, Branch.body, f)),
  DoWhile() => DoWhile(id: s.id, cond: s.cond, body: _rewriteList(s.body, s.id, Branch.body, f)),
  For() => For(
    id: s.id,
    variable: s.variable,
    from: s.from,
    to: s.to,
    step: s.step,
    body: _rewriteList(s.body, s.id, Branch.body, f),
  ),
  Declare() ||
  Assign() ||
  Input() ||
  Output() ||
  Comment() ||
  DigitalWrite() ||
  AnalogWrite() ||
  DigitalRead() ||
  AnalogRead() ||
  Delay() => s,
};

/// Applica [f] a tutte le liste: corpo (`parentId == null`), `setup`
/// ([setupListId]) e i rami di ogni blocco contenitore.
Program _rewrite(Program p, _ListEdit f) => p.copyWith(
  body: _rewriteList(p.body, null, Branch.body, f),
  setup: p.isArduino ? _rewriteList(p.setup, setupListId, Branch.body, f) : null,
);

/// Inserisce [stmt] nella posizione [slot].
Program insertAt(Program p, Slot slot, Stmt stmt) => _rewrite(p, (list, parent, branch) {
  if (parent != slot.parentId || branch != slot.branch) return list;
  final i = slot.index.clamp(0, list.length);
  return [...list.sublist(0, i), stmt, ...list.sublist(i)];
});

/// Elimina il blocco [id] (con tutto il suo contenuto).
Program removeBlock(Program p, String id) => _rewrite(
  p,
  (list, _, _) => [
    for (final s in list)
      if (s.id != id) s,
  ],
);

/// Sostituisce il blocco [id] con [replacement]. Se [replacement] è un
/// contenitore, i suoi rami sono quelli che porta con sé.
Program replaceBlock(Program p, String id, Stmt replacement) =>
    _rewrite(p, (list, _, _) => [for (final s in list) s.id == id ? replacement : s]);

/// Inserisce subito dopo il blocco [id] una sua copia (con id nuovi).
Program duplicateBlock(Program p, String id) => _rewrite(p, (list, _, _) {
  final i = list.indexWhere((s) => s.id == id);
  if (i < 0) return list;
  return [...list.sublist(0, i + 1), cloneWithNewIds(list[i]), ...list.sublist(i + 1)];
});

/// Sposta il blocco [id] di [delta] posizioni nella sua lista (−1 su, +1 giù).
Program moveBlock(Program p, String id, int delta) => _rewrite(p, (list, _, _) {
  final i = list.indexWhere((s) => s.id == id);
  final j = i + delta;
  if (i < 0 || j < 0 || j >= list.length) return list;
  final copy = [...list];
  copy[i] = list[j];
  copy[j] = list[i];
  return copy;
});

/// Posizione del blocco [id]: lista che lo contiene e indice. `null` se assente.
({Slot slot, int length})? locate(Program p, String id) {
  ({Slot slot, int length})? found;
  _rewrite(p, (list, parent, branch) {
    final i = list.indexWhere((s) => s.id == id);
    if (i >= 0) found = (slot: Slot(parent, branch, i), length: list.length);
    return list;
  });
  return found;
}

/// Blocco con id [id], o `null`.
Stmt? findBlock(Program p, String id) {
  for (final s in p.allStmts) {
    if (s.id == id) return s;
  }
  return null;
}

/// Nomi delle variabili dichiarate nel programma, in ordine di apparizione.
List<String> declaredVariables(Program p) => [
  for (final s in p.allStmts)
    if (s case Declare(:final name) when name.isNotEmpty) name,
];

/// Copia profonda con id nuovi in tutto il sottoalbero.
Stmt cloneWithNewIds(Stmt s) {
  List<Stmt> all(List<Stmt> l) => [for (final c in l) cloneWithNewIds(c)];
  final id = newId();
  return switch (s) {
    Declare() => Declare(id: id, name: s.name, type: s.type),
    Assign() => Assign(id: id, target: s.target, value: s.value),
    Input() => Input(id: id, variable: s.variable),
    Output() => Output(id: id, value: s.value),
    If() => If(id: id, cond: s.cond, then: all(s.then), otherwise: all(s.otherwise)),
    While() => While(id: id, cond: s.cond, body: all(s.body)),
    DoWhile() => DoWhile(id: id, cond: s.cond, body: all(s.body)),
    For() => For(
      id: id,
      variable: s.variable,
      from: s.from,
      to: s.to,
      step: s.step,
      body: all(s.body),
    ),
    Comment() => Comment(id: id, text: s.text),
    DigitalWrite() => DigitalWrite(id: id, pin: s.pin, value: s.value),
    AnalogWrite() => AnalogWrite(id: id, pin: s.pin, value: s.value),
    Delay() => Delay(id: id, ms: s.ms),
    DigitalRead() => DigitalRead(id: id, variable: s.variable, pin: s.pin),
    AnalogRead() => AnalogRead(id: id, variable: s.variable, pin: s.pin),
  };
}

/// Tipi di blocco inseribili, con un blocco "vuoto" di partenza.
enum BlockKind {
  declare,
  assign,
  input,
  output,
  ifElse,
  whileLoop,
  doWhile,
  forLoop,
  comment,
  digitalRead,
  analogRead,
  digitalWrite,
  analogWrite,
  delay;

  /// Nome nella lingua corrente.
  String get label => switch (this) {
    declare => tr.blockDeclare,
    assign => tr.blockAssign,
    input => tr.blockInput,
    output => tr.blockOutput,
    ifElse => tr.blockIf,
    whileLoop => tr.blockWhile,
    doWhile => tr.blockDoWhile,
    forLoop => tr.blockFor,
    comment => tr.blockComment,
    digitalRead => tr.blockDigitalRead,
    analogRead => tr.blockAnalogRead,
    digitalWrite => tr.blockDigitalWrite,
    analogWrite => tr.blockAnalogWrite,
    delay => tr.blockDelay,
  };

  /// Disponibile solo nei diagrammi Arduino.
  bool get arduinoOnly => index >= digitalRead.index;

  /// Tipi di blocco disponibili per un programma di tipo [kind].
  static List<BlockKind> available(ProgramKind kind) => [
    for (final k in values)
      if (!k.arduinoOnly || kind == ProgramKind.arduino) k,
  ];

  Stmt create() => switch (this) {
    declare => Declare(name: '', type: VarType.integer),
    assign => Assign(target: '', value: ExprSource('')),
    input => Input(variable: ''),
    output => Output(value: ExprSource('')),
    ifElse => If(cond: ExprSource('')),
    whileLoop => While(cond: ExprSource('')),
    doWhile => DoWhile(cond: ExprSource('')),
    forLoop => For(variable: '', from: ExprSource('1'), to: ExprSource('')),
    comment => Comment(text: ''),
    digitalWrite => DigitalWrite(pin: ExprSource(''), value: ExprSource('HIGH')),
    analogWrite => AnalogWrite(pin: ExprSource(''), value: ExprSource('128')),
    delay => Delay(ms: ExprSource('500')),
    digitalRead => DigitalRead(variable: '', pin: ExprSource('')),
    analogRead => AnalogRead(variable: '', pin: ExprSource('')),
  };
}
