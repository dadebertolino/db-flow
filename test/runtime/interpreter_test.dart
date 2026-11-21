import 'dart:io';
import 'dart:math';

import 'package:db_flow/expr/types.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/runtime/environment.dart';
import 'package:db_flow/runtime/interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

Program example(String name) =>
    decodeProgram(File('assets/examples/$name.flow').readAsStringSync());

ExprSource e(String s) => ExprSource(s);

/// Esegue un corpo con variabili intere a, b, c già dichiarate.
({List<String> output, String? error}) run(List<Stmt> body, [List<String> inputs = const []]) =>
    runToEnd(
      Program(name: 't', body: body),
      inputs,
      random: Random(1),
    );

List<Stmt> ints(List<String> names) => [
  for (final n in names) Declare(name: n, type: VarType.integer),
];

void main() {
  group('esempi', () {
    test('massimo', () {
      expect(runToEnd(example('massimo'), ['3', '7']).output, ['Il massimo è 7']);
      expect(runToEnd(example('massimo'), ['9', '-2']).output, ['Il massimo è 9']);
    });
    test('media (con do-while che ripete la richiesta)', () {
      final r = runToEnd(example('media'), ['0', '-1', '3', '1', '2', '4.5']);
      expect(r.error, isNull);
      expect(r.output, ['Media: 2.5']);
    });
    test('fattoriale', () {
      expect(runToEnd(example('fattoriale'), ['5']).output, ['5! = 120']);
      expect(runToEnd(example('fattoriale'), ['0']).output, ['0! = 1']);
    });
    test('numero primo', () {
      expect(runToEnd(example('primo'), ['7']).output, ['7 è primo']);
      expect(runToEnd(example('primo'), ['9']).output, ['9 non è primo']);
      expect(runToEnd(example('primo'), ['1']).output, ['1 non è primo']);
      expect(runToEnd(example('primo'), ['97']).output, ['97 è primo']);
    });
    test('MCD', () {
      expect(runToEnd(example('mcd'), ['48', '18']).output, ['MCD = 6']);
    });
    test('tabelline', () {
      final out = runToEnd(example('tabelline'), []).output;
      expect(out, hasLength(100));
      expect(out.first, '1 x 1 = 1');
      expect(out.last, '10 x 10 = 100');
    });
  });

  group('passo-passo', () {
    test('eventi in ordine, evidenziazione e input che sospende', () {
      final it = Interpreter(example('massimo'));
      final ids = <String?>[];
      RunEvent ev;
      do {
        ev = it.next();
        ids.add(ev.blockId);
        if (ev is InputRequest) {
          expect(() => it.next(), throwsStateError);
          it.provideInput(IntV(ev.variable == 'a' ? 1 : 2));
        }
      } while (ev is! Finished);
      expect(ids, ['m1', 'm2', 'm3', 'm4', 'm5', 'm6', 'm8', 'm9', null]);
      expect(it.env['massimo']!.value, const IntV(2));
      expect(it.isDone, isTrue);
    });

    test('le condizioni riportano il loro esito', () {
      final it = Interpreter(
        Program(
          name: 't',
          body: [If(id: 'c', cond: e('1 < 2'))],
        ),
      );
      final ev = it.next() as StepEvent;
      expect(ev.condition, isTrue);
    });
  });

  group('semantica', () {
    test('aritmetica e tipi', () {
      expect(run([Output(value: e('7 / 2'))]).output, ['3.5']);
      expect(run([Output(value: e('6 / 2'))]).output, ['3.0']);
      expect(run([Output(value: e('int(7 / 2)'))]).output, ['3']);
      expect(run([Output(value: e('-7 % 3'))]).output, ['-1']);
      expect(run([Output(value: e('2 + 3 * 4'))]).output, ['14']);
      expect(run([Output(value: e('1 + 0.5'))]).output, ['1.5']);
      expect(run([Output(value: e('round(2.5)'))]).output, ['3']);
      expect(run([Output(value: e('round(-2.5)'))]).output, ['-3']);
      expect(run([Output(value: e('int(-3.9)'))]).output, ['-3']);
      expect(run([Output(value: e('abs(-4)'))]).output, ['4']);
      expect(run([Output(value: e('sqrt(16)'))]).output, ['4.0']);
      expect(run([Output(value: e('len("città")'))]).output, ['5']);
      expect(run([Output(value: e('"ab" + "cd"'))]).output, ['abcd']);
      expect(run([Output(value: e('"x" & 1 & vero & 2.0'))]).output, ['x1vero2.0']);
      expect(run([Output(value: e('"b" > "a" and not (1 == 2)'))]).output, ['vero']);
    });

    test('intero assegnato a reale diventa reale', () {
      final r = run([
        Declare(name: 'x', type: VarType.real),
        Assign(target: 'x', value: e('3')),
        Output(value: e('x')),
      ]);
      expect(r.output, ['3.0']);
    });

    test('cortocircuito di and/or', () {
      expect(run([Output(value: e('falso and 1 / 0 > 0'))]).output, ['falso']);
      expect(run([Output(value: e('vero or 1 / 0 > 0'))]).output, ['vero']);
    });

    test('ciclo for con passo negativo e valore finale del contatore', () {
      final r = run([
        ...ints(['i']),
        For(
          variable: 'i',
          from: e('3'),
          to: e('1'),
          step: e('-1'),
          body: [Output(value: e('i'))],
        ),
        Output(value: e('"dopo: " & i')),
      ]);
      expect(r.output, ['3', '2', '1', 'dopo: 0']);
    });

    test('for che non esegue mai il corpo', () {
      final r = run([
        ...ints(['i']),
        For(
          variable: 'i',
          from: e('5'),
          to: e('1'),
          body: [Output(value: e('i'))],
        ),
      ]);
      expect(r.output, isEmpty);
      expect(r.error, isNull);
    });

    test('random con seme fisso è riproducibile e nell\'intervallo', () {
      final body = [
        ...ints(['i']),
        For(
          variable: 'i',
          from: e('1'),
          to: e('50'),
          body: [Output(value: e('random(6)'))],
        ),
      ];
      final a = run(body).output;
      expect(a, run(body).output);
      expect(a.map(int.parse).every((n) => n >= 0 && n < 6), isTrue);
    });
  });

  group('errori di esecuzione', () {
    test('divisione per zero, con il blocco', () {
      final it = Interpreter(
        Program(
          name: 't',
          body: [
            ...ints(['a']),
            Assign(id: 'x', target: 'a', value: e('int(1 / 0)')),
          ],
        ),
      );
      it.next();
      final ev = it.next() as Failed;
      expect(ev.blockId, 'x');
      expect(ev.message, contains('divisione per zero'));
      expect(it.next(), same(ev));
    });

    test('resto per zero', () {
      expect(run([Output(value: e('5 % 0'))]).error, contains('zero'));
    });

    test('variabile senza valore', () {
      expect(
        run([
          ...ints(['a']),
          Output(value: e('a + 1')),
        ]).error,
        contains("'a' non ha ancora un valore"),
      );
    });

    test('ciclo infinito', () {
      final r = runToEnd(
        Program(
          name: 't',
          body: [While(cond: e('vero'))],
        ),
        [],
        maxSteps: 500,
      );
      expect(r.error, contains('ciclo infinito'));
    });

    test('radice di un negativo e random(0)', () {
      expect(run([Output(value: e('sqrt(-1)'))]).error, contains('negativo'));
      expect(run([Output(value: e('random(0)'))]).error, contains('maggiore di 0'));
    });

    test('passo zero calcolato', () {
      final r = run([
        ...ints(['i', 'p']),
        Assign(target: 'p', value: e('0')),
        For(variable: 'i', from: e('1'), to: e('3'), step: e('p')),
      ]);
      expect(r.error, contains('passo'));
    });
  });

  group('lettura dell\'input', () {
    test('conversioni', () {
      expect(parseInput(' 42 ', VarType.integer).value, const IntV(42));
      expect(parseInput('3,5', VarType.real).value, const RealV(3.5));
      expect(parseInput('7', VarType.real).value, const RealV(7));
      expect(parseInput(' ciao ', VarType.string).value, const StrV(' ciao '));
      expect(parseInput('Vero', VarType.boolean).value, const BoolV(true));
      expect(parseInput('no', VarType.boolean).value, const BoolV(false));
    });
    test('errori', () {
      expect(parseInput('3.5', VarType.integer).error, contains('intero'));
      expect(parseInput('abc', VarType.real).error, contains('numero'));
      expect(parseInput('forse', VarType.boolean).error, contains('vero oppure falso'));
    });
  });
}
