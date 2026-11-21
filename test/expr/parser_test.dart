import 'package:db_flow/expr/errors.dart';
import 'package:db_flow/expr/lexer.dart';
import 'package:db_flow/expr/parser.dart';
import 'package:db_flow/expr/types.dart';
import 'package:db_flow/model/expr.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forma completamente parentesizzata, per verificare precedenze e associatività.
String show(Expr e) => switch (e) {
  Literal(:final value) => value is StrV ? '"${value.display}"' : value.display,
  VarRef(:final name) => name,
  Unary(:final op, :final operand) => '(${op.symbol} ${show(operand)})',
  Binary(:final op, :final left, :final right) => '(${show(left)} ${op.symbol} ${show(right)})',
  Call(:final name, :final args) => '$name(${args.map(show).join(', ')})',
};

String p(String src) => show(parseExpression(src));

ExprError err(String src) {
  try {
    parseExpression(src);
  } on ExprError catch (e) {
    return e;
  }
  fail('nessun errore per: $src');
}

void main() {
  group('letterali', () {
    test('numeri, stringhe, booleani', () {
      expect(p('12'), '12');
      expect(p('3.14'), '3.14');
      expect(p('vero'), 'vero');
      expect(p('falso'), 'falso');
      expect((parseExpression('"ciao mondo"') as Literal).value.display, 'ciao mondo');
      expect((parseExpression('""') as Literal).value.display, '');
    });
  });

  group('precedenza', () {
    test('* prima di +', () {
      expect(p('1 + 2 * 3'), '(1 + (2 * 3))');
      expect(p('1 * 2 + 3'), '((1 * 2) + 3)');
    });
    test('associatività a sinistra', () {
      expect(p('a - b - c'), '((a - b) - c)');
      expect(p('a / b * c'), '((a / b) * c)');
    });
    test('& allo stesso livello di +', () {
      expect(p('"x" & a + 1'), '(("x" & a) + 1)');
    });
    test('confronti sotto aritmetica, and sotto confronti, or sotto and', () {
      expect(p('a + 1 > b * 2'), '((a + 1) > (b * 2))');
      expect(p('a > 1 and b < 2 or c'), '(((a > 1) and (b < 2)) or c)');
      expect(p('a or b and c'), '(a or (b and c))');
    });
    test('not e meno unario hanno la precedenza più alta', () {
      expect(p('not a and b'), '((not a) and b)');
      expect(p('-a * b'), '((- a) * b)');
      expect(p('- - a'), '(- (- a))');
      expect(p('+a'), 'a');
    });
    test('parentesi', () {
      expect(p('(1 + 2) * 3'), '((1 + 2) * 3)');
      expect(p('not (a > b)'), '(not (a > b))');
    });
    test('forme alternative && || !', () {
      expect(p('a && b || !c'), '((a and b) or (not c))');
    });
    test('funzioni', () {
      expect(p('sqrt(x * x + 1)'), 'sqrt(((x * x) + 1))');
      expect(p('abs(-3) + len("ab")'), '(abs((- 3)) + len("ab"))');
    });
  });

  group('errori di sintassi', () {
    void expectError(String src, String fragment, int column) {
      final e = err(src);
      expect(e.message, contains(fragment), reason: src);
      expect(e.column, column, reason: src);
    }

    test('espressione vuota o incompleta', () {
      expectError('', 'vuota', 1);
      expectError('   ', 'vuota', 1);
      expectError('a +', 'incompleta', 4);
      expectError('* 2', "prima di '*'", 1);
    });
    test('parentesi', () {
      expectError('(a + b', "')'", 1);
      expectError('a + b)', "senza la corrispondente '('", 6);
      expectError('()', "prima di ')'", 2);
    });
    test('operatore mancante', () {
      expectError('a b', 'manca un operatore', 3);
      expectError('2 (3)', 'manca un operatore', 3);
    });
    test('= singolo e <>', () {
      expectError('a = b', "'=='", 3);
      expectError('a <> b', "'!='", 3);
    });
    test('confronti concatenati', () {
      expectError('a < b < c', 'concatenati', 7);
    });
    test('virgola decimale', () {
      expectError('3,14', 'punto', 2);
    });
    test('stringhe', () {
      expectError('"ciao', 'non chiusa', 1);
      expectError("'ciao'", 'virgolette doppie', 1);
    });
    test('numeri', () {
      expectError('3.', 'decimale', 2);
      expectError('2a', 'cifra', 1);
      expectError('99999999999999999999999', 'troppo grande', 1);
    });
    test('caratteri non ammessi', () {
      expectError('età + 1', "'à'", 3);
      expectError('a # b', "'#'", 3);
      expectError('a | b', 'or', 3);
    });
    test('funzioni', () {
      expectError('foo(1)', 'sconosciuta', 1);
      expectError('sqrt(1, 2)', 'argomento', 1);
      expectError('sqrt()', 'argomento', 1);
      expectError('sqrt(1', "')'", 5);
    });
  });

  group('nomi di variabile', () {
    test('validi', () {
      for (final n in ['a', 'somma', 'x1', '_tmp', 'numero_primo', 'Max']) {
        expect(checkIdentifier(n), isNull, reason: n);
      }
    });
    test('non validi', () {
      expect(checkIdentifier(''), contains('vuoto'));
      expect(checkIdentifier('1a'), contains('cifra'));
      expect(checkIdentifier('mio numero'), contains('spazi'));
      expect(checkIdentifier('età'), contains('accento'));
      expect(checkIdentifier('sqrt'), contains('funzione'));
      expect(checkIdentifier('vero'), contains('riservata'));
      expect(checkIdentifier('while'), contains('riservata'));
      expect(checkIdentifier('printf'), contains('riservata'));
    });
  });

  group('ExprSource', () {
    test('conserva il testo e calcola albero o errore', () {
      final ok = ExprSource('a + 1');
      expect(ok.isValid, isTrue);
      expect(ok.expr, isA<Binary>());
      final bad = ExprSource('a +');
      expect(bad.isValid, isFalse);
      expect(bad.expr, isNull);
      expect(bad.text, 'a +');
    });
  });
}
