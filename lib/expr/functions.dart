/// Funzioni predefinite (lista chiusa). Dart puro.
library;

import '../i18n/tr.dart';
import 'types.dart';

/// Esito del controllo dei tipi degli argomenti: tipo del risultato oppure
/// messaggio d'errore.
typedef CallTyping = ({VarType? type, String? error});

final class BuiltinFunction {
  const BuiltinFunction(this.name, this._typing, {this.arity = 1, this.arduinoOnly = false});

  final String name;

  /// Firma mostrata all'utente, es. `sqrt(numero)`, nella lingua corrente.
  String get signature => tr.functionSignature(name);

  /// Descrizione breve nella lingua corrente.
  String get description => tr.functionDescription(name);

  /// Numero di argomenti.
  final int arity;

  /// Disponibile solo nei diagrammi Arduino.
  final bool arduinoOnly;

  final CallTyping Function(List<VarType> args) _typing;

  CallTyping typeOf(List<VarType> args) => _typing(args);
}

CallTyping _ok(VarType t) => (type: t, error: null);
CallTyping _err(String m) => (type: null, error: m);

CallTyping _numeric(String fn, VarType arg, VarType Function(VarType) result) =>
    arg.isNumeric ? _ok(result(arg)) : _err(tr.fnNeedsNumber(fn, arg));

CallTyping _pin(String fn, List<VarType> a) =>
    a.single == VarType.integer ? _ok(VarType.integer) : _err(tr.fnNeedsPin(fn, a.single));

final builtinFunctions = <String, BuiltinFunction>{
  for (final f in [
    BuiltinFunction('abs', (a) => _numeric('abs', a.single, (t) => t)),
    BuiltinFunction('sqrt', (a) => _numeric('sqrt', a.single, (_) => VarType.real)),
    BuiltinFunction('int', (a) => _numeric('int', a.single, (_) => VarType.integer)),
    BuiltinFunction('round', (a) => _numeric('round', a.single, (_) => VarType.integer)),
    BuiltinFunction(
      'len',
      (a) => a.single == VarType.string
          ? _ok(VarType.integer)
          : _err(tr.fnNeedsString('len', a.single)),
    ),
    BuiltinFunction(
      'random',
      (a) => a.single == VarType.integer
          ? _ok(VarType.integer)
          : _err(tr.fnNeedsInteger('random', a.single)),
    ),
    // ------------------------------------------------------------ Arduino
    BuiltinFunction('digitalRead', (a) => _pin('digitalRead', a), arduinoOnly: true),
    BuiltinFunction('analogRead', (a) => _pin('analogRead', a), arduinoOnly: true),
    BuiltinFunction('millis', (_) => _ok(VarType.integer), arity: 0, arduinoOnly: true),
  ])
    f.name: f,
};

/// Costanti predefinite di Arduino, viste dalle espressioni come interi.
const arduinoConstants = {'HIGH': 1, 'LOW': 0};
