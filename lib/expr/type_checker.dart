/// Controllo statico dei tipi delle espressioni. Dart puro.
///
/// Regole:
/// - `+ - *`: tra numeri; intero se entrambi interi, altrimenti reale.
///   `+` tra due stringhe le concatena.
/// - `/`: tra numeri, risultato **sempre reale** (7 / 2 = 3.5).
///   Per la divisione intera: `int(a / b)`; per il resto: `a % b`.
/// - `%`: solo tra interi.
/// - `&`: concatena due valori di qualsiasi tipo, risultato stringa.
/// - `== !=`: tra valori dello stesso tipo (intero e reale sono confrontabili).
/// - `< <= > >=`: tra numeri o tra stringhe (ordine alfabetico).
/// - `and or not`: tra booleani.
library;

import '../i18n/tr.dart';
import '../model/expr.dart';
import 'errors.dart';
import 'functions.dart';
import 'types.dart';

/// Restituisce il tipo di [e] date le variabili dichiarate in [vars].
/// Lancia [ExprError] se l'espressione non è ben tipata.
///
/// Con [arduino] falso le funzioni di Arduino (`digitalRead` …) non sono ammesse.
VarType typeOf(Expr e, Map<String, VarType> vars, {bool arduino = false}) {
  final previous = _arduino;
  _arduino = arduino;
  try {
    return _typeOf(e, vars);
  } finally {
    _arduino = previous;
  }
}

/// Funzioni di Arduino ammesse nel controllo in corso (il controllo è sincrono).
bool _arduino = false;

VarType _typeOf(Expr e, Map<String, VarType> vars) => switch (e) {
  Literal(:final value) => value.type,
  VarRef(:final name, :final pos) => vars[name] ?? (throw _undeclared(name, pos)),
  Unary() => _unary(e, vars),
  Binary() => _binary(e, vars),
  Call() => _call(e, vars),
};

ExprError _undeclared(String name, int pos) {
  final lower = name.toLowerCase();
  final keywords = {'and', 'or', 'not', ...trueWords, ...falseWords};
  final msg = keywords.contains(lower) && lower != name
      ? tr.typeUndeclaredLowercase(name, lower)
      : tr.typeUndeclared(name);
  return ExprError(msg, pos, name.length);
}

VarType _unary(Unary e, Map<String, VarType> vars) {
  final t = _typeOf(e.operand, vars);
  switch (e.op) {
    case UnaryOp.neg:
      if (!t.isNumeric) {
        throw ExprError(tr.typeNegNumber(t), e.pos);
      }
      return t;
    case UnaryOp.not:
      if (t != VarType.boolean) {
        throw ExprError(tr.typeNotBoolean(t), e.pos, 3);
      }
      return VarType.boolean;
  }
}

VarType _binary(Binary e, Map<String, VarType> vars) {
  final l = _typeOf(e.left, vars);
  final r = _typeOf(e.right, vars);
  final sym = e.op.symbol;
  ExprError err(String msg) => ExprError(msg, e.pos, sym.length);

  VarType arithmetic() {
    if (!l.isNumeric || !r.isNumeric) {
      throw err(tr.typeArith(sym, l, r));
    }
    return l == VarType.integer && r == VarType.integer ? VarType.integer : VarType.real;
  }

  switch (e.op) {
    case BinaryOp.add:
      if (l == VarType.string && r == VarType.string) return VarType.string;
      if (l == VarType.string || r == VarType.string) {
        throw err(tr.typePlusText(l, r));
      }
      return arithmetic();
    case BinaryOp.sub:
    case BinaryOp.mul:
      return arithmetic();
    case BinaryOp.div:
      arithmetic();
      return VarType.real;
    case BinaryOp.mod:
      if (l != VarType.integer || r != VarType.integer) {
        throw err(tr.typeModInts(l, r));
      }
      return VarType.integer;
    case BinaryOp.concat:
      return VarType.string;
    case BinaryOp.eq:
    case BinaryOp.ne:
      if (l != r && !(l.isNumeric && r.isNumeric)) {
        throw err(tr.typeCannotCompare(l, r));
      }
      return VarType.boolean;
    case BinaryOp.lt:
    case BinaryOp.le:
    case BinaryOp.gt:
    case BinaryOp.ge:
      final ok = (l.isNumeric && r.isNumeric) || (l == VarType.string && r == VarType.string);
      if (!ok) {
        throw err(tr.typeCompareNumStr(sym, l, r));
      }
      return VarType.boolean;
    case BinaryOp.and:
    case BinaryOp.or:
      if (l != VarType.boolean || r != VarType.boolean) {
        throw err(tr.typeLogical(sym, l, r));
      }
      return VarType.boolean;
  }
}

VarType _call(Call e, Map<String, VarType> vars) {
  final fn = builtinFunctions[e.name]!; // il parser accetta solo funzioni note
  if (fn.arduinoOnly && !_arduino) {
    throw ExprError(tr.typeArduinoOnly(e.name), e.pos, e.name.length);
  }
  final res = fn.typeOf([for (final a in e.args) _typeOf(a, vars)]);
  return res.type ?? (throw ExprError(res.error!, e.pos, e.name.length));
}
