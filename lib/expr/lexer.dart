/// Analizzatore lessicale delle espressioni. Dart puro.
library;

import '../i18n/tr.dart';
import 'errors.dart';
import 'functions.dart';

enum TokenType {
  intLit,
  realLit,
  strLit,
  ident,
  kwTrue,
  kwFalse,
  and,
  or,
  not,
  plus,
  minus,
  star,
  slash,
  percent,
  amp,
  eq,
  ne,
  lt,
  le,
  gt,
  ge,
  lparen,
  rparen,
  comma,
  eof,
}

final class Token {
  const Token(this.type, this.text, this.pos);

  final TokenType type;

  /// Testo del token; per le stringhe è il contenuto senza virgolette.
  final String text;
  final int pos;

  /// Lunghezza nel sorgente (per evidenziare l'errore).
  int get length => type == TokenType.strLit ? text.length + 2 : text.length;

  @override
  String toString() => '$type($text)@$pos';
}

final _keywords = {
  'and': TokenType.and,
  'or': TokenType.or,
  'not': TokenType.not,
  for (final w in trueWords) w: TokenType.kwTrue,
  for (final w in falseWords) w: TokenType.kwFalse,
};

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;
bool _isAsciiLetter(int c) => (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c == 0x5F;
bool _isIdentPart(int c) => _isAsciiLetter(c) || _isDigit(c);
bool _isSpace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

/// Lettere non ASCII (es. accentate): non ammesse nei nomi perché il codice
/// generato in C e Python deve restare valido.
bool _isOtherLetter(String ch) => ch.toLowerCase() != ch.toUpperCase();

List<Token> tokenize(String src) {
  final tokens = <Token>[];
  var i = 0;
  final n = src.length;

  int peek(int k) => i + k < n ? src.codeUnitAt(i + k) : -1;

  while (i < n) {
    final c = src.codeUnitAt(i);
    final start = i;

    if (_isSpace(c)) {
      i++;
      continue;
    }

    if (_isDigit(c)) {
      while (_isDigit(peek(0))) {
        i++;
      }
      var isReal = false;
      if (peek(0) == 0x2E /* . */ ) {
        if (!_isDigit(peek(1))) {
          throw ExprError(tr.lexIncompleteNumber, i);
        }
        isReal = true;
        i++;
        while (_isDigit(peek(0))) {
          i++;
        }
      }
      if (_isIdentPart(peek(0))) {
        throw ExprError(tr.lexNameStartsWithDigit, start, i - start + 1);
      }
      final text = src.substring(start, i);
      if (!isReal && int.tryParse(text) == null) {
        throw ExprError(tr.lexNumberTooLarge, start, text.length);
      }
      tokens.add(Token(isReal ? TokenType.realLit : TokenType.intLit, text, start));
      continue;
    }

    if (_isAsciiLetter(c)) {
      while (_isIdentPart(peek(0))) {
        i++;
      }
      if (i < n && _isOtherLetter(src[i])) {
        throw ExprError(tr.lexAccentedLetter(src[i]), i);
      }
      final text = src.substring(start, i);
      tokens.add(Token(_keywords[text] ?? TokenType.ident, text, start));
      continue;
    }

    if (c == 0x22 /* " */ ) {
      i++;
      while (i < n && src.codeUnitAt(i) != 0x22) {
        i++;
      }
      if (i >= n) {
        throw ExprError(tr.lexUnclosedString, start, n - start);
      }
      tokens.add(Token(TokenType.strLit, src.substring(start + 1, i), start));
      i++;
      continue;
    }

    Token op(TokenType t, int len) {
      i += len;
      return Token(t, src.substring(start, i), start);
    }

    final next = peek(1);
    switch (src[i]) {
      case '+':
        tokens.add(op(TokenType.plus, 1));
      case '-':
        tokens.add(op(TokenType.minus, 1));
      case '*':
        tokens.add(op(TokenType.star, 1));
      case '/':
        tokens.add(op(TokenType.slash, 1));
      case '%':
        tokens.add(op(TokenType.percent, 1));
      case '(':
        tokens.add(op(TokenType.lparen, 1));
      case ')':
        tokens.add(op(TokenType.rparen, 1));
      case ',':
        tokens.add(op(TokenType.comma, 1));
      case '&':
        tokens.add(next == 0x26 ? op(TokenType.and, 2) : op(TokenType.amp, 1));
      case '|':
        if (next != 0x7C) {
          throw ExprError(tr.lexUseOr, start);
        }
        tokens.add(op(TokenType.or, 2));
      case '!':
        tokens.add(next == 0x3D ? op(TokenType.ne, 2) : op(TokenType.not, 1));
      case '=':
        if (next != 0x3D) {
          throw ExprError(tr.lexUseDoubleEquals, start);
        }
        tokens.add(op(TokenType.eq, 2));
      case '<':
        if (next == 0x3E) {
          throw ExprError(tr.lexUseNotEquals, start, 2);
        }
        tokens.add(next == 0x3D ? op(TokenType.le, 2) : op(TokenType.lt, 1));
      case '>':
        tokens.add(next == 0x3D ? op(TokenType.ge, 2) : op(TokenType.gt, 1));
      case "'":
        throw ExprError(tr.lexUseDoubleQuotes, start);
      default:
        final isSurrogatePair = (c & 0xFC00) == 0xD800 && i + 1 < n;
        final ch = src.substring(i, i + (isSurrogatePair ? 2 : 1));
        if (_isOtherLetter(ch)) {
          throw ExprError(tr.lexAccentedLetter(ch), start);
        }
        throw ExprError(tr.lexInvalidChar(ch), start);
    }
  }
  tokens.add(Token(TokenType.eof, '', n));
  return tokens;
}

/// Parole che non possono essere usate come nomi di variabile: parole chiave
/// del linguaggio, funzioni predefinite e parole riservate di Python e C (il
/// codice generato deve compilare).
const reservedWords = {
  // linguaggio DB Flow
  'and', 'or', 'not', 'vero', 'falso',
  // Python
  'False', 'None', 'True', 'as', 'assert', 'async', 'await', 'break', 'class',
  'continue', 'def', 'del', 'elif', 'else', 'except', 'finally', 'for', 'from',
  'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'pass', 'raise',
  'return', 'try', 'while', 'with', 'yield', 'print', 'input', 'float', 'str',
  'bool', 'range', 'math', 'random',
  // C
  'auto', 'case', 'char', 'const', 'default', 'do', 'double', 'enum', 'extern',
  'goto', 'inline', 'long', 'register', 'restrict', 'short', 'signed', 'sizeof',
  'static', 'struct', 'switch', 'typedef', 'union', 'unsigned', 'void',
  'volatile', 'main', 'printf', 'scanf', 'true', 'false', 'NULL',
  // C++ e Arduino (lo sketch generato deve compilare)
  'new', 'delete', 'this', 'public', 'private', 'protected', 'namespace',
  'template', 'operator', 'virtual', 'friend', 'using', 'nullptr', 'throw', 'catch',
  'setup', 'loop', 'pinMode', 'digitalWrite', 'digitalRead', 'analogWrite', 'analogRead',
  'delay', 'millis', 'micros', 'Serial', 'String', 'HIGH', 'LOW', 'INPUT', 'OUTPUT',
  'INPUT_PULLUP', 'LED_BUILTIN', 'A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'byte', 'word',
  'boolean', 'tone', 'noTone', 'map', 'constrain', 'min', 'max',
};

final _identRe = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// Controlla un nome di variabile. Restituisce il messaggio d'errore o `null`.
String? checkIdentifier(String name) {
  if (name.isEmpty) return tr.idEmpty;
  if (_isDigit(name.codeUnitAt(0))) {
    return tr.lexNameStartsWithDigit;
  }
  if (name.contains(' ')) {
    return tr.idHasSpaces;
  }
  if (!_identRe.hasMatch(name)) {
    return tr.idInvalidChars;
  }
  if (builtinFunctions.containsKey(name)) {
    return tr.idIsFunction(name);
  }
  if (reservedWords.contains(name) || trueWords.contains(name) || falseWords.contains(name)) {
    return tr.idReserved(name);
  }
  return null;
}
