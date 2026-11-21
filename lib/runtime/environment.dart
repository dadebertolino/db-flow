/// Variabili durante l'esecuzione. Dart puro.
library;

import '../expr/types.dart';
import '../i18n/tr.dart';
import 'runtime_errors.dart';

final class Variable {
  Variable(this.name, this.type);
  final String name;
  final VarType type;

  /// `null` finché la variabile non riceve un valore.
  Value? value;
}

final class Environment {
  final _vars = <String, Variable>{};

  /// Costanti (Arduino: `HIGH`, `LOW`, `A0`…, nomi dei pin). Non compaiono
  /// tra le variabili.
  final constants = <String, Value>{};

  /// Variabili in ordine di dichiarazione.
  Iterable<Variable> get all => _vars.values;

  Variable? operator [](String name) => _vars[name];

  /// Dichiara [name]. Se il blocco viene rieseguito (es. dentro un ciclo) la
  /// variabile torna senza valore, come una nuova dichiarazione.
  void declare(String name, VarType type) => _vars[name] = Variable(name, type);

  Value read(String name) {
    if (constants[name] case final c?) return c;
    final v = _vars[name];
    if (v == null) throw RuntimeError(tr.runUndeclared(name));
    return v.value ?? (throw RuntimeError(tr.runNoValue(name)));
  }

  /// Assegna [value] a [name], convertendo intero → reale se serve.
  void write(String name, Value value) {
    final v = _vars[name];
    if (v == null) throw RuntimeError(tr.runUndeclared(name));
    v.value = switch ((v.type, value)) {
      (VarType.real, IntV(value: final i)) => RealV(i.toDouble()),
      _ when value.type == v.type => value,
      _ => throw RuntimeError(tr.runAssignType(value.type, name, v.type)),
    };
  }
}

/// Interpreta il testo scritto dall'utente come valore di tipo [type].
({Value? value, String? error}) parseInput(String text, VarType type) {
  final t = text.trim();
  ({Value? value, String? error}) ok(Value v) => (value: v, error: null);
  ({Value? value, String? error}) err(String m) => (value: null, error: m);
  switch (type) {
    case VarType.integer:
      final i = int.tryParse(t);
      return i == null ? err(tr.inputNeedInteger) : ok(IntV(i));
    case VarType.real:
      final d = double.tryParse(t.replaceAll(',', '.'));
      return d == null || !d.isFinite ? err(tr.inputNeedNumber) : ok(RealV(d));
    case VarType.string:
      return ok(StrV(text));
    case VarType.boolean:
      final answer = t.toLowerCase();
      if (trueAnswers.contains(answer)) return ok(const BoolV(true));
      if (falseAnswers.contains(answer)) return ok(const BoolV(false));
      return err(tr.inputNeedBoolean);
  }
}
