import 'dart:io';

import 'package:db_flow/codegen/generator.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/runtime/interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Per rigenerare gli snapshot: `UPDATE_GOLDENS=1 flutter test test/codegen`
final update = Platform.environment['UPDATE_GOLDENS'] == '1';

const examples = {
  'massimo': ['3', '7'],
  'media': ['0', '3', '1', '2', '4.5'],
  'fattoriale': ['6'],
  'primo': ['91'],
  'mcd': ['48', '18'],
  'tabelline': <String>[],
};

Program example(String name) =>
    decodeProgram(File('assets/examples/$name.flow').readAsStringSync());

bool _has(String tool) => Process.runSync('which', [tool]).exitCode == 0;

/// Toglie i prompt di input e normalizza i reali interi (C stampa 3 invece di 3.0).
List<String> _normalize(String stdout, {bool realsAsC = false}) {
  var s = stdout.replaceAll(RegExp(r'Inserisci \w+: '), '');
  if (realsAsC) s = s.replaceAllMapped(RegExp(r'(\d+)\.0\b'), (m) => m[1]!);
  return s.split('\n').where((l) => l.isNotEmpty).toList();
}

void main() {
  final tmp = Directory.systemTemp.createTempSync('dbflow_codegen');
  tearDownAll(() => tmp.deleteSync(recursive: true));

  group('snapshot', () {
    for (final name in examples.keys) {
      for (final lang in CodeLanguage.forProgram(example(name))) {
        test('$name.${lang.extension}', () {
          final code = generateCode(example(name), lang);
          final golden = File('test/codegen/golden/$name.${lang.extension}');
          if (update || !golden.existsSync()) {
            golden
              ..createSync(recursive: true)
              ..writeAsStringSync(code);
          }
          expect(code, golden.readAsStringSync());
        });
      }
    }
  });

  group('il Python generato dà lo stesso output dell\'app', () {
    for (final MapEntry(key: name, value: inputs) in examples.entries) {
      test(name, () async {
        final expected = runToEnd(example(name), inputs).output;
        final file = File('${tmp.path}/$name.py')
          ..writeAsStringSync(generateCode(example(name), CodeLanguage.python));
        final proc = await Process.start('python3', [file.path]);
        proc.stdin.write(inputs.map((i) => '$i\n').join());
        await proc.stdin.close();
        final out = await proc.stdout.transform(systemEncoding.decoder).join();
        final err = await proc.stderr.transform(systemEncoding.decoder).join();
        expect(await proc.exitCode, 0, reason: err);
        expect(_normalize(out), expected);
      }, skip: _has('python3') ? false : 'python3 non disponibile');
    }
  });

  group('il C generato compila senza avvisi e dà lo stesso output', () {
    for (final MapEntry(key: name, value: inputs) in examples.entries) {
      test(name, () async {
        final expected = runToEnd(example(name), inputs).output;
        final src = File('${tmp.path}/$name.c')
          ..writeAsStringSync(generateCode(example(name), CodeLanguage.c));
        final exe = '${tmp.path}/$name';
        final cc = Process.runSync('cc', [
          '-std=c99',
          '-Wall',
          '-Wextra',
          '-o',
          exe,
          src.path,
          '-lm',
        ]);
        expect(cc.exitCode, 0, reason: '${cc.stderr}');
        expect('${cc.stderr}', isEmpty, reason: 'avvisi del compilatore');
        final proc = await Process.start(exe, []);
        proc.stdin.write(inputs.map((i) => '$i\n').join());
        await proc.stdin.close();
        final out = await proc.stdout.transform(systemEncoding.decoder).join();
        expect(await proc.exitCode, 0);
        expect(_normalize(out, realsAsC: true), _normalize(expected.join('\n'), realsAsC: true));
      }, skip: _has('cc') ? false : 'compilatore C non disponibile');
    }
  });

  group('casi particolari', () {
    ExprSource e(String s) => ExprSource(s);
    Program prog(List<Stmt> body) => Program(name: 'p', body: body);

    test('precedenze e parentesi in Python', () {
      final code = generateCode(
        prog([
          Declare(name: 'a', type: VarType.integer),
          Declare(name: 'b', type: VarType.boolean),
          Output(value: e('(a + 1) * 2')),
          Output(value: e('not b and a > 0')),
          Output(value: e('(not b) == vero')),
          Output(value: e('- -a')),
          Output(value: e('"b vale " & b')),
        ]),
        CodeLanguage.python,
      );
      expect(code, contains('print((a + 1) * 2)'));
      expect(code, contains('print(not b and a > 0)'));
      expect(code, contains('print((not b) == True)'));
      expect(code, contains('print(-(-a))'));
      expect(code, contains('print("b vale " + ("vero" if b else "falso"))'));
    });

    test('C: divisione reale tra interi, stringhe e confronto di testo', () {
      final code = generateCode(
        prog([
          Declare(name: 'a', type: VarType.integer),
          Declare(name: 's', type: VarType.string),
          Assign(target: 's', value: e('"n=" & a')),
          Assign(target: 's', value: e('s & "!"')),
          Output(value: e('a / 2')),
          If(cond: e('s == "x"')),
          For(variable: 'a', from: e('10'), to: e('0'), step: e('-2')),
        ]),
        CodeLanguage.c,
      );
      expect(code, contains('snprintf(s, sizeof s, "n=%d", a);'));
      expect(code, contains('strcpy(s, tmp);'));
      expect(code, contains('printf("%g\\n", (double) a / 2);'));
      expect(code, contains('if (strcmp(s, "x") == 0) {'));
      expect(code, contains('for (a = 10; a >= 0; a -= 2) {'));
      expect(code, contains('#include <string.h>'));
    });

    test('Python: range con passo negativo o variabile', () {
      final code = generateCode(
        prog([
          Declare(name: 'i', type: VarType.integer),
          Declare(name: 'p', type: VarType.integer),
          For(variable: 'i', from: e('10'), to: e('1'), step: e('-3')),
          For(variable: 'i', from: e('1'), to: e('p'), step: e('p')),
        ]),
        CodeLanguage.python,
      );
      expect(code, contains('for i in range(10, 0, -3):'));
      expect(code, contains('for i in range(1, p + (1 if p > 0 else -1), p):'));
    });

    test('programma vuoto', () {
      final empty = Program(name: 'vuoto');
      expect(generateCode(empty, CodeLanguage.python), contains('pass'));
      expect(generateCode(empty, CodeLanguage.c), contains('return 0;'));
      expect(generateCode(empty, CodeLanguage.pseudo), contains('INIZIO\nFINE'));
    });
  });
}
