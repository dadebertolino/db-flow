import 'package:db_flow/expr/errors.dart';
import 'package:db_flow/expr/parser.dart';
import 'package:db_flow/expr/type_checker.dart';
import 'package:db_flow/expr/types.dart';
import 'package:flutter_test/flutter_test.dart';

const vars = {
  'i': VarType.integer,
  'n': VarType.integer,
  'x': VarType.real,
  's': VarType.string,
  'b': VarType.boolean,
};

VarType t(String src) => typeOf(parseExpression(src), vars);

ExprError err(String src) {
  try {
    t(src);
  } on ExprError catch (e) {
    return e;
  }
  fail('nessun errore per: $src');
}

void main() {
  test('letterali e variabili', () {
    expect(t('1'), VarType.integer);
    expect(t('1.5'), VarType.real);
    expect(t('"a"'), VarType.string);
    expect(t('vero'), VarType.boolean);
    expect(t('x'), VarType.real);
  });

  test('aritmetica: intero solo se entrambi interi', () {
    expect(t('i + n'), VarType.integer);
    expect(t('i * 2 - 1'), VarType.integer);
    expect(t('i + x'), VarType.real);
    expect(t('-i'), VarType.integer);
    expect(t('-x'), VarType.real);
  });

  test('/ è sempre reale, % solo tra interi', () {
    expect(t('i / n'), VarType.real);
    expect(t('7 / 2'), VarType.real);
    expect(t('int(i / n)'), VarType.integer);
    expect(t('i % n'), VarType.integer);
    expect(err('x % 2').message, contains('tra interi'));
  });

  test('stringhe: + tra stringhe, & con qualsiasi tipo', () {
    expect(t('s + "!"'), VarType.string);
    expect(t('"n = " & n'), VarType.string);
    expect(t('b & x'), VarType.string);
    expect(err('s + 1').message, contains("usa '&'"));
  });

  test('confronti', () {
    expect(t('i < x'), VarType.boolean);
    expect(t('s == "a"'), VarType.boolean);
    expect(t('s < "m"'), VarType.boolean);
    expect(t('b == falso'), VarType.boolean);
    expect(t('i == 1.0'), VarType.boolean);
    expect(err('s == 1').message, contains('non si possono confrontare'));
    expect(err('b < vero').message, contains('tra numeri o tra stringhe'));
  });

  test('logici', () {
    expect(t('b and i > 0'), VarType.boolean);
    expect(t('not b or i == 0'), VarType.boolean);
    expect(err('i and b').message, contains('booleani'));
    final e = err('not i > 0');
    expect(e.message, contains('not (a > b)'));
    expect(e.column, 1);
  });

  test('funzioni', () {
    expect(t('abs(i)'), VarType.integer);
    expect(t('abs(x)'), VarType.real);
    expect(t('sqrt(i)'), VarType.real);
    expect(t('round(x)'), VarType.integer);
    expect(t('len(s)'), VarType.integer);
    expect(t('random(10)'), VarType.integer);
    expect(err('len(i)').message, contains('stringa'));
    expect(err('random(x)').message, contains('intero'));
    expect(err('sqrt(s)').message, contains('numero'));
  });

  test('variabili non dichiarate, con suggerimenti', () {
    final e = err('i + k');
    expect(e.message, "variabile 'k' non dichiarata");
    expect(e.column, 5);
    expect(err('b AND b').message, isNotEmpty); // AND è un nome: errore di sintassi
    expect(err('AND').message, contains("'and' in minuscolo"));
    expect(err('TRUE').message, contains("'true' in minuscolo"));
  });

  test('vero/falso accettati in tutte le lingue', () {
    for (final w in [
      'vero',
      'true',
      'vrai',
      'wahr',
      'verdadero',
      'falso',
      'false',
      'faux',
      'falsch',
    ]) {
      expect(t(w), VarType.boolean, reason: w);
    }
  });

  test('isAssignable: unica conversione implicita intero → reale', () {
    expect(isAssignable(VarType.real, VarType.integer), isTrue);
    expect(isAssignable(VarType.integer, VarType.real), isFalse);
    expect(isAssignable(VarType.string, VarType.integer), isFalse);
  });

  test('visualizzazione dei valori', () {
    expect(const RealV(3).display, '3.0');
    expect(const RealV(3.5).display, '3.5');
    expect(const BoolV(true).display, 'vero');
    expect(const IntV(-2).display, '-2');
  });
}
