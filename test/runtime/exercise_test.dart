import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/model/exercise.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/runtime/exercise_check.dart';
import 'package:flutter_test/flutter_test.dart';

Program massimo() => decodeProgram(File('assets/examples/massimo.flow').readAsStringSync());

void main() {
  setUp(() => setLanguage(AppLanguage.it));

  group('confronto tollerante', () {
    test('maiuscole, spazi e righe vuote non contano', () {
      expect(outputsMatch(['Il massimo è 7'], ['  il   MASSIMO è 7 ', '']), isTrue);
      expect(outputsMatch(['a', '', 'b'], ['a', 'b']), isTrue);
    });
    test('i numeri valgono per il valore', () {
      expect(outputsMatch(['5'], ['5.0']), isTrue);
      expect(outputsMatch(['media: 2,5'], ['Media: 2.5']), isTrue);
      expect(outputsMatch(['0.3'], ['0.30000000000000004']), isTrue);
      expect(outputsMatch(['5'], ['6']), isFalse);
      expect(outputsMatch(['1, 2, 3'], ['1 2 3']), isTrue);
    });
    test('punteggiatura di fine frase ignorata, altri simboli no', () {
      expect(outputsMatch(['Fatto.'], ['fatto']), isTrue);
      expect(outputsMatch(['x = 3'], ['x 3']), isFalse);
    });
    test('vero/falso in qualsiasi lingua', () {
      expect(outputsMatch(['vero'], ['true']), isTrue);
      expect(outputsMatch(['falso'], ['vero']), isFalse);
    });
    test('le righe devono corrispondere', () {
      expect(outputsMatch(['a', 'b'], ['a b']), isFalse);
      expect(outputsMatch(['a'], ['a', 'b']), isFalse);
      expect(outputsMatch(['a\nb'], ['a', 'b']), isTrue);
    });
  });

  group('verifica dei casi', () {
    test('caso superato e caso sbagliato', () {
      final p = massimo();
      expect(
        checkCase(p, TestCase(inputs: ['3', '9'], expected: ['Il massimo è 9'])).passed,
        isTrue,
      );
      final wrong = checkCase(p, TestCase(inputs: ['3', '9'], expected: ['9']));
      expect(wrong.outcome, CaseOutcome.wrongOutput);
      expect(wrong.output, ['Il massimo è 9']);
    });
    test('input mancanti, in più o non validi', () {
      final p = massimo();
      expect(checkCase(p, TestCase(inputs: ['3'])).outcome, CaseOutcome.missingInput);
      expect(checkCase(p, TestCase(inputs: ['3', '4', '5'])).outcome, CaseOutcome.unusedInput);
      final bad = checkCase(p, TestCase(inputs: ['3', 'ciao']));
      expect(bad.outcome, CaseOutcome.badInput);
      expect(bad.error, isNotNull);
    });
    test('errore di esecuzione e ciclo infinito', () {
      final div = Program(
        name: 'd',
        body: [Output(id: 'o', value: ExprSource('1 / 0'))],
      );
      expect(checkCase(div, TestCase()).outcome, CaseOutcome.error);
      final loop = Program(
        name: 'l',
        body: [While(id: 'w', cond: ExprSource('vero'), body: const [])],
      );
      final r = checkCase(loop, TestCase());
      expect(r.outcome, CaseOutcome.error);
      expect(r.error, contains('10000'));
    });
    test("checkExercise usa i casi dell'esercizio", () {
      final p = massimo().withExercise(
        Exercise(
          text: 'Massimo',
          cases: [
            TestCase(inputs: ['1', '2'], expected: ['Il massimo è 2']),
            TestCase(inputs: ['5', '2'], expected: ['Il massimo è 2'], hidden: true),
          ],
        ),
      );
      expect(checkExercise(p).map((r) => r.passed), [true, false]);
    });
  });

  group('file .flow', () {
    test("round-trip dell'esercizio", () {
      final e = Exercise(
        text: 'Leggi due numeri e scrivi il maggiore.',
        locked: true,
        cases: [
          TestCase(inputs: ['3', '9'], expected: ['9']),
          TestCase(inputs: ['-1', '-4'], expected: ['-1'], hidden: true),
        ],
      );
      final p = massimo().withExercise(e);
      final back = decodeProgram(encodeProgram(p));
      expect(back.exercise, e);
      expect(back.body.length, p.body.length);
      expect(back.copyWith(name: 'x').exercise, e, reason: 'copyWith conserva l\'esercizio');
      expect(back.withExercise(null).exercise, isNull);
    });
    test('senza esercizio il campo non si scrive', () {
      expect(encodeProgram(massimo()), isNot(contains('exercise')));
    });
    test('parti malformate scartate', () {
      final json = encodeProgram(massimo()).replaceFirst(
        '"body"',
        '"exercise": {"text": 3, "cases": [1, {"in": [4, "x"], "out": "no"}]}, "body"',
      );
      final e = decodeProgram(json).exercise!;
      expect(e.text, '');
      expect(e.cases.single.inputs, ['4', 'x']);
      expect(e.cases.single.expected, isEmpty);
    });
  });
}
