/// AST delle espressioni. Dart puro.
library;

import '../expr/errors.dart';
import '../expr/parser.dart';
import '../expr/types.dart';

enum UnaryOp {
  neg('-'),
  not('not');

  const UnaryOp(this.symbol);
  final String symbol;
}

enum BinaryOp {
  add('+'),
  sub('-'),
  mul('*'),
  div('/'),
  mod('%'),
  concat('&'),
  eq('=='),
  ne('!='),
  lt('<'),
  le('<='),
  gt('>'),
  ge('>='),
  and('and'),
  or('or');

  const BinaryOp(this.symbol);
  final String symbol;

  bool get isComparison => index >= eq.index && index <= ge.index;
  bool get isLogical => this == and || this == or;
}

/// Nodo di espressione. [pos] è l'offset nel testo sorgente (per gli errori).
sealed class Expr {
  const Expr(this.pos);
  final int pos;
}

final class Literal extends Expr {
  const Literal(this.value, super.pos);
  final Value value;
}

final class VarRef extends Expr {
  const VarRef(this.name, super.pos);
  final String name;
}

final class Unary extends Expr {
  const Unary(this.op, this.operand, super.pos);
  final UnaryOp op;
  final Expr operand;
}

final class Binary extends Expr {
  const Binary(this.op, this.left, this.right, super.pos);
  final BinaryOp op;
  final Expr left;
  final Expr right;
}

final class Call extends Expr {
  Call(this.name, List<Expr> args, int pos) : args = List.unmodifiable(args), super(pos);
  final String name;
  final List<Expr> args;
}

/// Espressione come la scrive l'utente: il testo è la fonte di verità (è ciò che
/// si salva nel file), l'albero è derivato e calcolato una sola volta.
///
/// Un'espressione non valida resta nel diagramma: il blocco viene evidenziato
/// in rosso e l'utente può correggerla.
final class ExprSource {
  ExprSource(this.text);

  final String text;

  late final ({Expr? expr, ExprError? error}) _parsed = _parse();

  ({Expr? expr, ExprError? error}) _parse() {
    try {
      return (expr: parseExpression(text), error: null);
    } on ExprError catch (e) {
      return (expr: null, error: e);
    }
  }

  /// Albero sintattico, `null` se il testo non è valido.
  Expr? get expr => _parsed.expr;

  /// Errore di sintassi, `null` se il testo è valido.
  ExprError? get error => _parsed.error;

  bool get isValid => error == null;

  @override
  bool operator ==(Object other) => other is ExprSource && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}

/// Valore intero costante di un'espressione semplice (`3`, `-1`), altrimenti `null`.
int? constInt(Expr? e) => switch (e) {
  Literal(value: IntV(:final value)) => value,
  Unary(op: UnaryOp.neg, :final operand) => switch (constInt(operand)) {
    final v? => -v,
    null => null,
  },
  _ => null,
};
