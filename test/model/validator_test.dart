import 'dart:io';

import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/model/validator.dart';
import 'package:flutter_test/flutter_test.dart';

ExprSource e(String s) => ExprSource(s);

List<String> messages(List<Stmt> body) =>
    validate(Program(name: 't', body: body)).map((i) => i.message).toList();

void main() {
  for (final f in Directory('assets/examples').listSync().whereType<File>()) {
    test('fixture senza errori: ${f.uri.pathSegments.last}', () {
      expect(validate(decodeProgram(f.readAsStringSync())), isEmpty);
    });
  }

  test('dichiarazioni', () {
    expect(messages([Declare(name: 'età', type: VarType.integer)]).single, contains('accento'));
    expect(
      messages([Declare(name: 'a', type: VarType.integer), Declare(name: 'a', type: VarType.real)])
          .single,
      contains('già dichiarata'),
    );
  });

  test('uso prima della dichiarazione', () {
    final issues = validate(
      Program(
        name: 't',
        body: [
          Input(id: 'in', variable: 'a'),
          Declare(name: 'a', type: VarType.integer),
        ],
      ),
    );
    expect(issues.single.blockId, 'in');
    expect(issues.single.field, 'var');
    expect(issues.single.message, contains('non dichiarata'));
  });

  test('assegnazioni e compatibilità dei tipi', () {
    final decl = [
      Declare(name: 'i', type: VarType.integer),
      Declare(name: 'x', type: VarType.real),
      Declare(name: 's', type: VarType.string),
    ];
    expect(messages([...decl, Assign(target: 'x', value: e('i + 1'))]), isEmpty);
    expect(messages([...decl, Assign(target: 'i', value: e('x'))]).single, contains('int(...)'));
    expect(messages([...decl, Assign(target: 'i', value: e('i / 2'))]).single, contains('reale'));
    expect(messages([...decl, Assign(target: 's', value: e('i'))]).single, contains('stringa'));
    expect(messages([...decl, Assign(target: 'z', value: e('1'))]).single, contains("'z'"));
  });

  test('errori nelle espressioni con posizione', () {
    final issues = validate(
      Program(
        name: 't',
        body: [
          Declare(name: 'a', type: VarType.integer),
          Output(id: 'o', value: e('a + ')),
        ],
      ),
    );
    expect(issues.single.blockId, 'o');
    expect(issues.single.field, 'value');
    expect(issues.single.pos, isNotNull);
  });

  test('le condizioni devono essere booleane', () {
    final decl = Declare(name: 'n', type: VarType.integer);
    expect(messages([decl, If(cond: e('n'))]).single, contains('booleana'));
    expect(messages([decl, While(cond: e('n + 1'))]).single, contains('booleana'));
    expect(messages([decl, DoWhile(cond: e('"x"'))]).single, contains('booleana'));
    expect(messages([decl, If(cond: e('n > 0'))]), isEmpty);
  });

  test('do-while: il corpo viene prima della condizione', () {
    // la condizione usa una variabile dichiarata nel corpo
    expect(
      messages([
        DoWhile(
          body: [Declare(name: 'k', type: VarType.boolean)],
          cond: e('k'),
        ),
      ]),
      isEmpty,
    );
  });

  test('ciclo for', () {
    final i = Declare(name: 'i', type: VarType.integer);
    final x = Declare(name: 'x', type: VarType.real);
    For loop(String v, {String from = '1', String to = '10', String step = '1'}) =>
        For(variable: v, from: e(from), to: e(to), step: e(step));

    expect(messages([i, loop('i')]), isEmpty);
    expect(messages([i, loop('i', from: '10', to: '1', step: '-1')]), isEmpty);
    expect(messages([x, loop('x')]).single, contains('intera'));
    expect(messages([i, loop('k')]).single, contains('non dichiarata'));
    expect(messages([i, x, loop('i', to: 'x')]).single, contains('valore finale'));
    expect(messages([i, loop('i', step: '0')]).single, contains('non può essere 0'));
    expect(messages([i, loop('i', step: '-0')]).single, contains('non può essere 0'));
  });

  test('errori nei rami annidati', () {
    final issues = validate(
      Program(
        name: 't',
        body: [
          Declare(name: 'n', type: VarType.integer),
          While(
            cond: e('n > 0'),
            body: [
              If(
                cond: e('vero'),
                otherwise: [Assign(id: 'deep', target: 'n', value: e('m'))],
              ),
            ],
          ),
        ],
      ),
    );
    expect(issuesByBlock(issues).keys, ['deep']);
  });
}
