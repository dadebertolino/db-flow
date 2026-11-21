import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/model/validator.dart';
import 'package:db_flow/runtime/exercise_check.dart';
import 'package:db_flow/ui/home_page.dart' show exerciseFiles;
import 'package:flutter_test/flutter_test.dart';

ExprSource x(String s) => ExprSource(s);
Declare dint(String n) => Declare(name: n, type: VarType.integer);
Declare dreal(String n) => Declare(name: n, type: VarType.real);
Declare dbool(String n) => Declare(name: n, type: VarType.boolean);

/// Soluzioni di riferimento: dimostrano che ogni esercizio si può risolvere
/// con i blocchi dell'app e che i casi di prova sono coerenti.
final solutions = <String, List<Stmt>>{
  'somma': [
    dint('a'),
    dint('b'),
    Input(variable: 'a'),
    Input(variable: 'b'),
    Output(value: x('a + b')),
  ],
  'area': [
    dreal('b'),
    dreal('h'),
    Input(variable: 'b'),
    Input(variable: 'h'),
    Output(value: x('b * h')),
  ],
  'pari': [
    dint('n'),
    dbool('p'),
    Input(variable: 'n'),
    Assign(target: 'p', value: x('n % 2 == 0')),
    Output(value: x('p')),
  ],
  'massimo3': [
    dint('a'),
    dint('b'),
    dint('c'),
    dint('m'),
    Input(variable: 'a'),
    Input(variable: 'b'),
    Input(variable: 'c'),
    Assign(target: 'm', value: x('a')),
    If(
      cond: x('b > m'),
      then: [Assign(target: 'm', value: x('b'))],
    ),
    If(
      cond: x('c > m'),
      then: [Assign(target: 'm', value: x('c'))],
    ),
    Output(value: x('m')),
  ],
  'conto_rovescia': [
    dint('n'),
    dint('i'),
    Input(variable: 'n'),
    For(
      variable: 'i',
      from: x('n'),
      to: x('1'),
      step: x('-1'),
      body: [Output(value: x('i'))],
    ),
  ],
  'somma_n': [
    dint('n'),
    dint('i'),
    dint('s'),
    Input(variable: 'n'),
    Assign(target: 's', value: x('0')),
    For(
      variable: 'i',
      from: x('1'),
      to: x('n'),
      body: [Assign(target: 's', value: x('s + i'))],
    ),
    Output(value: x('s')),
  ],
  'multipli': [
    dint('n'),
    dint('i'),
    Input(variable: 'n'),
    For(
      variable: 'i',
      from: x('1'),
      to: x('10'),
      body: [Output(value: x('n * i'))],
    ),
  ],
  'conta_positivi': [
    dint('v'),
    dint('c'),
    Assign(target: 'c', value: x('0')),
    Input(variable: 'v'),
    While(
      cond: x('v != 0'),
      body: [
        If(
          cond: x('v > 0'),
          then: [Assign(target: 'c', value: x('c + 1'))],
        ),
        Input(variable: 'v'),
      ],
    ),
    Output(value: x('c')),
  ],
  'media_n': [
    dint('n'),
    dint('i'),
    dreal('v'),
    dreal('s'),
    Input(variable: 'n'),
    Assign(target: 's', value: x('0')),
    For(
      variable: 'i',
      from: x('1'),
      to: x('n'),
      body: [
        Input(variable: 'v'),
        Assign(target: 's', value: x('s + v')),
      ],
    ),
    Output(value: x('s / n')),
  ],
  'potenza': [
    dint('b'),
    dint('e'),
    dint('r'),
    dint('i'),
    Input(variable: 'b'),
    Input(variable: 'e'),
    Assign(target: 'r', value: x('1')),
    For(
      variable: 'i',
      from: x('1'),
      to: x('e'),
      body: [Assign(target: 'r', value: x('r * b'))],
    ),
    Output(value: x('r')),
  ],
};

Program load(AppLanguage lang, String name) {
  final dir = lang == AppLanguage.it ? 'assets/exercises' : 'assets/exercises/${lang.name}';
  return decodeProgram(File('$dir/$name.flow').readAsStringSync());
}

void main() {
  tearDown(() => setLanguage(AppLanguage.it));

  test("l'elenco degli esercizi corrisponde ai file", () {
    final files = Directory('assets/exercises')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last.replaceAll('.flow', ''))
        .toSet();
    expect(files, exerciseFiles.toSet());
    expect(solutions.keys.toSet(), exerciseFiles.toSet());
  });

  for (final lang in AppLanguage.values) {
    group('esercizi inclusi (${lang.name})', () {
      for (final name in exerciseFiles) {
        test(name, () {
          setLanguage(lang);
          final p = load(lang, name);
          final e = p.exercise!;
          expect(p.kind, ProgramKind.algorithm);
          expect(p.body, isEmpty, reason: 'nessuna soluzione nel file');
          expect(e.locked, isTrue);
          expect(e.text, isNotEmpty);
          expect(e.visibleCases.length, greaterThanOrEqualTo(1));
          expect(e.cases.where((c) => c.hidden), isNotEmpty);

          // Stessi casi in tutte le lingue.
          if (lang != AppLanguage.it) {
            final it = load(AppLanguage.it, name);
            expect(p.name, isNot(it.name), reason: 'nome tradotto');
            expect(e.text, isNot(it.exercise!.text), reason: 'consegna tradotta');
            expect(e.cases.length, it.exercise!.cases.length);
            for (var i = 0; i < e.cases.length; i++) {
              expect(e.cases[i].inputs, it.exercise!.cases[i].inputs);
              expect(e.cases[i].hidden, it.exercise!.cases[i].hidden);
              expect(outputsMatch(e.cases[i].expected, it.exercise!.cases[i].expected), isTrue);
            }
          }

          final solved = p.copyWith(body: solutions[name]);
          expect(validate(solved), isEmpty);
          for (final r in checkExercise(solved)) {
            expect(r.outcome, CaseOutcome.passed, reason: '${r.testCase.inputs} → ${r.output}');
          }
          // Il diagramma vuoto non supera i casi.
          expect(checkExercise(p).every((r) => r.passed), isFalse);
        });
      }
    });
  }
}
