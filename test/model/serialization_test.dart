import 'dart:convert';
import 'dart:io';

import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:flutter_test/flutter_test.dart';

final fixtures = Directory('assets/examples')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.flow'));

void main() {
  test('ci sono le fixture', () => expect(fixtures.length, greaterThanOrEqualTo(6)));

  for (final f in fixtures) {
    test('round-trip JSON: ${f.uri.pathSegments.last}', () {
      final original = jsonDecode(f.readAsStringSync());
      final program = decodeProgram(f.readAsStringSync());
      final reencoded = jsonDecode(encodeProgram(program));
      expect(reencoded, original);
    });
  }

  test('struttura del programma "massimo"', () {
    final p = decodeProgram(File('assets/examples/massimo.flow').readAsStringSync());
    expect(p.name, 'Massimo tra due numeri');
    expect(p.body, hasLength(7));
    final cond = p.body[5] as If;
    expect(cond.cond.text, 'a > b');
    expect(cond.cond.expr, isA<Binary>());
    expect((cond.then.single as Assign).target, 'massimo');
    expect(walk(p.body).map((s) => s.id), containsAllInOrder(['m6', 'm7', 'm8', 'm9']));
  });

  test('programma costruito in codice → JSON → programma', () {
    final p = Program(
      name: 'Prova',
      body: [
        Declare(name: 'k', type: VarType.integer),
        For(
          variable: 'k',
          from: ExprSource('10'),
          to: ExprSource('1'),
          step: ExprSource('-1'),
          body: [Output(value: ExprSource('k'))],
        ),
        Comment(text: 'fine'),
      ],
    );
    final back = decodeProgram(encodeProgram(p));
    expect(jsonEncode(programToJson(back)), jsonEncode(programToJson(p)));
    expect((back.body[1] as For).step.text, '-1');
  });

  test('le espressioni non valide si conservano così come sono', () {
    final p = Program(
      name: 'x',
      body: [Output(value: ExprSource('a +'))],
    );
    final back = decodeProgram(encodeProgram(p));
    final out = back.body.single as Output;
    expect(out.value.text, 'a +');
    expect(out.value.isValid, isFalse);
  });

  test('il passo del for, se manca, vale 1', () {
    final p = programFromJson({
      'format': 'db-flow',
      'version': 1,
      'name': 'x',
      'body': [
        {'id': 'a', 't': 'for', 'var': 'i', 'from': '1', 'to': '3', 'body': <Object?>[]},
      ],
    });
    expect((p.body.single as For).step.text, '1');
  });

  test('id mancanti o duplicati vengono rigenerati', () {
    final p = programFromJson({
      'format': 'db-flow',
      'version': 1,
      'name': 'x',
      'body': [
        {'id': 'dup', 't': 'comment', 'text': '1'},
        {'id': 'dup', 't': 'comment', 'text': '2'},
        {'t': 'comment', 'text': '3'},
      ],
    });
    final ids = p.body.map((s) => s.id).toList();
    expect(ids.first, 'dup');
    expect(ids.toSet(), hasLength(3));
  });

  test('il programma è immutabile', () {
    final p = decodeProgram(File('assets/examples/mcd.flow').readAsStringSync());
    expect(() => p.body.add(Comment(text: 'x')), throwsUnsupportedError);
    expect(() => (p.body[5] as While).body.removeLast(), throwsUnsupportedError);
  });

  group('file non validi', () {
    void expectInvalid(String source, String fragment) {
      expect(
        () => decodeProgram(source),
        throwsA(isA<FlowFormatException>().having((e) => e.message, 'message', contains(fragment))),
      );
    }

    test('JSON danneggiato o di altro formato', () {
      expectInvalid('{non json', 'danneggiato');
      expectInvalid('[1, 2]', 'non è un diagramma');
      expectInvalid('{"format": "altro", "version": 1}', 'non è un diagramma');
    });
    test('versione', () {
      expectInvalid('{"format": "db-flow"}', 'versione');
      expectInvalid('{"format": "db-flow", "version": 99}', 'più recente');
    });
    test('blocchi', () {
      expectInvalid('{"format": "db-flow", "version": 1, "body": [{"t": "goto"}]}', 'sconosciuto');
      expectInvalid(
        '{"format": "db-flow", "version": 1, "body": [{"t": "declare", "name": "a", "type": "char"}]}',
        "tipo sconosciuto: 'char'",
      );
      expectInvalid(
        '{"format": "db-flow", "version": 1, "body": [{"t": "assign", "target": "a"}]}',
        "'value'",
      );
    });
  });
}
