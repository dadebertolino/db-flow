/// Parser a discesa ricorsiva: testo → [Expr]. Dart puro.
///
/// Grammatica (dalla precedenza più bassa alla più alta):
/// ```
/// or      := and ( ('or' | '||') and )*
/// and     := cmp ( ('and' | '&&') cmp )*
/// cmp     := add ( ('=='|'!='|'<'|'<='|'>'|'>=') add )?     // non concatenabili
/// add     := mul ( ('+' | '-' | '&') mul )*
/// mul     := unary ( ('*' | '/' | '%') unary )*
/// unary   := ('not' | '!' | '-' | '+') unary | primary
/// primary := INT | REAL | STRING | 'vero' | 'falso'
///          | IDENT | IDENT '(' or ')' | '(' or ')'
/// ```
library;

import '../i18n/tr.dart';
import '../model/expr.dart';
import 'errors.dart';
import 'functions.dart';
import 'lexer.dart';
import 'types.dart';

/// Analizza [source]. Lancia [ExprError] con messaggio in italiano.
Expr parseExpression(String source) => _Parser(tokenize(source))._parse();

const _comparisons = {
  TokenType.eq: BinaryOp.eq,
  TokenType.ne: BinaryOp.ne,
  TokenType.lt: BinaryOp.lt,
  TokenType.le: BinaryOp.le,
  TokenType.gt: BinaryOp.gt,
  TokenType.ge: BinaryOp.ge,
};

const _additive = {
  TokenType.plus: BinaryOp.add,
  TokenType.minus: BinaryOp.sub,
  TokenType.amp: BinaryOp.concat,
};

const _multiplicative = {
  TokenType.star: BinaryOp.mul,
  TokenType.slash: BinaryOp.div,
  TokenType.percent: BinaryOp.mod,
};

final class _Parser {
  _Parser(this._tokens);

  final List<Token> _tokens;
  int _i = 0;

  Token get _cur => _tokens[_i];
  Token _advance() => _tokens[_i++];

  Expr _parse() {
    if (_cur.type == TokenType.eof) {
      throw ExprError(tr.parseEmpty, 0);
    }
    final e = _or();
    if (_cur.type != TokenType.eof) throw _unexpectedAfterExpression(_cur);
    return e;
  }

  Expr _or() {
    var left = _and();
    while (_cur.type == TokenType.or) {
      final op = _advance();
      left = Binary(BinaryOp.or, left, _and(), op.pos);
    }
    return left;
  }

  Expr _and() {
    var left = _cmp();
    while (_cur.type == TokenType.and) {
      final op = _advance();
      left = Binary(BinaryOp.and, left, _cmp(), op.pos);
    }
    return left;
  }

  Expr _cmp() {
    final left = _add();
    final op = _comparisons[_cur.type];
    if (op == null) return left;
    final opTok = _advance();
    final right = _add();
    if (_comparisons.containsKey(_cur.type)) {
      throw ExprError(tr.parseChainedComparison, _cur.pos, _cur.length);
    }
    return Binary(op, left, right, opTok.pos);
  }

  Expr _add() {
    var left = _mul();
    while (true) {
      final op = _additive[_cur.type];
      if (op == null) return left;
      final opTok = _advance();
      left = Binary(op, left, _mul(), opTok.pos);
    }
  }

  Expr _mul() {
    var left = _unary();
    while (true) {
      final op = _multiplicative[_cur.type];
      if (op == null) return left;
      final opTok = _advance();
      left = Binary(op, left, _unary(), opTok.pos);
    }
  }

  Expr _unary() {
    switch (_cur.type) {
      case TokenType.not:
        final t = _advance();
        return Unary(UnaryOp.not, _unary(), t.pos);
      case TokenType.minus:
        final t = _advance();
        return Unary(UnaryOp.neg, _unary(), t.pos);
      case TokenType.plus:
        _advance();
        return _unary();
      default:
        return _primary();
    }
  }

  Expr _primary() {
    final t = _cur;
    switch (t.type) {
      case TokenType.intLit:
        _advance();
        return Literal(IntV(int.parse(t.text)), t.pos);
      case TokenType.realLit:
        _advance();
        return Literal(RealV(double.parse(t.text)), t.pos);
      case TokenType.strLit:
        _advance();
        return Literal(StrV(t.text), t.pos);
      case TokenType.kwTrue:
        _advance();
        return Literal(const BoolV(true), t.pos);
      case TokenType.kwFalse:
        _advance();
        return Literal(const BoolV(false), t.pos);
      case TokenType.ident:
        _advance();
        if (_cur.type == TokenType.lparen) return _call(t);
        return VarRef(t.text, t.pos);
      case TokenType.lparen:
        _advance();
        final e = _or();
        if (_cur.type != TokenType.rparen) {
          throw ExprError(tr.parseMissingCloseParen, t.pos);
        }
        _advance();
        return e;
      case TokenType.eof:
        throw ExprError(tr.parseIncomplete, t.pos);
      case TokenType.rparen:
        throw ExprError(tr.parseMissingValueBeforeClose, t.pos);
      case TokenType.comma:
        throw ExprError(tr.parseUnexpectedComma, t.pos);
      default:
        throw ExprError(tr.parseMissingValueBefore(t.text), t.pos, t.length);
    }
  }

  Expr _call(Token name) {
    final fn = builtinFunctions[name.text];
    if (fn == null) {
      throw ExprError(tr.parseUnknownFunction(name.text), name.pos, name.length);
    }
    final open = _advance(); // '('
    final args = <Expr>[];
    if (_cur.type != TokenType.rparen) {
      args.add(_or());
      while (_cur.type == TokenType.comma) {
        _advance();
        args.add(_or());
      }
    }
    if (_cur.type != TokenType.rparen) {
      throw ExprError(tr.parseMissingCloseParen, open.pos);
    }
    _advance();
    if (args.length != fn.arity) {
      throw ExprError(tr.parseArity(fn.name, fn.arity, args.length), name.pos, name.length);
    }
    return Call(name.text, args, name.pos);
  }

  ExprError _unexpectedAfterExpression(Token t) => switch (t.type) {
    TokenType.rparen => ExprError(tr.parseUnmatchedClose, t.pos),
    TokenType.comma => ExprError(tr.parseUnexpectedComma, t.pos),
    TokenType.intLit ||
    TokenType.realLit ||
    TokenType.strLit ||
    TokenType.ident ||
    TokenType.kwTrue ||
    TokenType.kwFalse ||
    TokenType.lparen ||
    TokenType.not => ExprError(tr.parseMissingOperatorBefore(t.text), t.pos, t.length),
    _ => ExprError(tr.parseUnexpected(t.text), t.pos, t.length),
  };
}
