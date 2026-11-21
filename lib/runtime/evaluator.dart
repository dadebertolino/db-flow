/// Valutazione delle espressioni. Dart puro.
///
/// Semantica (coerente con il controllo dei tipi):
/// - `/` dà sempre un reale; divisione per zero → errore.
/// - `%` è il resto con il segno del dividendo, come in C: -7 % 3 = -1.
/// - `int(x)` tronca verso lo zero; `round(x)` arrotonda e 0.5 va lontano da zero.
/// - `&` unisce le rappresentazioni testuali (i reali interi appaiono come `3.0`).
library;

import 'dart:math' as math;

import '../expr/types.dart';
import '../i18n/tr.dart';
import '../model/expr.dart';
import 'environment.dart';
import 'runtime_errors.dart';

/// Scheda vista dalle espressioni: `digitalRead`, `analogRead`, `millis`.
abstract interface class Hardware {
  int digitalRead(int pin);
  int analogRead(int pin);
  int millis();
}

/// Valuta [e]. [hw]: scheda simulata (solo per i diagrammi Arduino).
Value evaluate(Expr e, Environment env, math.Random rng, [Hardware? hw]) => switch (e) {
  Literal(:final value) => value,
  VarRef(:final name) => env.read(name),
  Unary() => _unary(e, env, rng, hw),
  Binary() => _binary(e, env, rng, hw),
  Call() => _call(e, env, rng, hw),
};

Never _typeError(String what) => throw RuntimeError(tr.runTypeInvalid(what));

double _num(Value v) => switch (v) {
  IntV(:final value) => value.toDouble(),
  RealV(:final value) => value,
  _ => _typeError(tr.runNeedNumber),
};

bool _bool(Value v) => v is BoolV ? v.value : _typeError(tr.runNeedBoolean);

Value _unary(Unary e, Environment env, math.Random rng, Hardware? hw) {
  final v = evaluate(e.operand, env, rng, hw);
  return switch ((e.op, v)) {
    (UnaryOp.neg, IntV(:final value)) => IntV(-value),
    (UnaryOp.neg, RealV(:final value)) => RealV(-value),
    (UnaryOp.not, BoolV(:final value)) => BoolV(!value),
    _ => _typeError(tr.runOpNotApplicable(e.op.symbol, v.type)),
  };
}

Value _binary(Binary e, Environment env, math.Random rng, Hardware? hw) {
  // and / or valutano il secondo operando solo se serve (cortocircuito).
  if (e.op == BinaryOp.and) {
    return BoolV(_bool(evaluate(e.left, env, rng, hw)) && _bool(evaluate(e.right, env, rng, hw)));
  }
  if (e.op == BinaryOp.or) {
    return BoolV(_bool(evaluate(e.left, env, rng, hw)) || _bool(evaluate(e.right, env, rng, hw)));
  }
  final l = evaluate(e.left, env, rng, hw);
  final r = evaluate(e.right, env, rng, hw);

  Value arith(int Function(int, int) onInt, double Function(double, double) onReal) =>
      l is IntV && r is IntV ? IntV(onInt(l.value, r.value)) : RealV(onReal(_num(l), _num(r)));

  int compare() {
    if (l is StrV && r is StrV) return l.value.compareTo(r.value);
    return _num(l).compareTo(_num(r));
  }

  bool equals() => switch ((l, r)) {
    (final StrV a, final StrV b) => a.value == b.value,
    (final BoolV a, final BoolV b) => a.value == b.value,
    _ => _num(l) == _num(r),
  };

  switch (e.op) {
    case BinaryOp.add:
      if (l is StrV && r is StrV) return StrV(l.value + r.value);
      return arith((a, b) => a + b, (a, b) => a + b);
    case BinaryOp.sub:
      return arith((a, b) => a - b, (a, b) => a - b);
    case BinaryOp.mul:
      return arith((a, b) => a * b, (a, b) => a * b);
    case BinaryOp.div:
      final d = _num(r);
      if (d == 0) throw RuntimeError(tr.runDivZero);
      return RealV(_num(l) / d);
    case BinaryOp.mod:
      if (l is! IntV || r is! IntV) _typeError(tr.runModInts);
      if (r.value == 0) throw RuntimeError(tr.runModZero);
      return IntV(l.value.remainder(r.value));
    case BinaryOp.concat:
      return StrV(l.display + r.display);
    case BinaryOp.eq:
      return BoolV(equals());
    case BinaryOp.ne:
      return BoolV(!equals());
    case BinaryOp.lt:
      return BoolV(compare() < 0);
    case BinaryOp.le:
      return BoolV(compare() <= 0);
    case BinaryOp.gt:
      return BoolV(compare() > 0);
    case BinaryOp.ge:
      return BoolV(compare() >= 0);
    case BinaryOp.and || BinaryOp.or:
      throw StateError('gestito sopra');
  }
}

Value _call(Call e, Environment env, math.Random rng, Hardware? hw) {
  if (e.name == 'millis' && e.args.isEmpty && hw != null) return IntV(hw.millis());
  if (e.args.length != 1) {
    throw RuntimeError(tr.runNotSimulated(e.name));
  }
  final v = evaluate(e.args.single, env, rng, hw);
  switch (e.name) {
    case 'abs':
      return v is IntV ? IntV(v.value.abs()) : RealV(_num(v).abs());
    case 'sqrt':
      final x = _num(v);
      if (x < 0) throw RuntimeError(tr.runSqrtNegative(v.display));
      return RealV(math.sqrt(x));
    case 'int':
      final x = _num(v);
      if (!x.isFinite) throw RuntimeError(tr.runNotFinite('int'));
      return IntV(x.truncate());
    case 'round':
      final x = _num(v);
      if (!x.isFinite) throw RuntimeError(tr.runNotFinite('round'));
      return IntV(x.round());
    case 'len':
      return v is StrV ? IntV(v.value.characters) : _typeError(tr.runLenString);
    case 'random':
      if (v is! IntV) _typeError(tr.runRandomInt);
      if (v.value <= 0) {
        throw RuntimeError(tr.runRandomPositive(v.value));
      }
      return IntV(rng.nextInt(v.value));
    case 'digitalRead' || 'analogRead':
      if (hw == null) throw RuntimeError(tr.runNotSimulated(e.name));
      if (v is! IntV) _typeError(tr.runNeedNumber);
      return IntV(e.name == 'digitalRead' ? hw.digitalRead(v.value) : hw.analogRead(v.value));
    default:
      throw RuntimeError("funzione '${e.name}' sconosciuta");
  }
}

extension on String {
  /// Numero di caratteri come li vede l'utente (anche lettere accentate e emoji).
  int get characters => runes.length;
}
