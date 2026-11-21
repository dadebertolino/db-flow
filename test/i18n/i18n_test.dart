// Verifica di ogni lingua: esempi tradotti validi ed eseguibili, codice
// generato, messaggi effettivamente tradotti.
import 'dart:io';

import 'package:db_flow/codegen/generator.dart';
import 'package:db_flow/expr/errors.dart';
import 'package:db_flow/expr/parser.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/layout/layout_engine.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/validator.dart';
import 'package:db_flow/runtime/interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Esempi e input con cui eseguirli (gli stessi in ogni lingua).
const exampleInputs = {
  'massimo': ['3', '7'],
  'media': ['0', '3', '1', '2', '4.5'],
  'fattoriale': ['6'],
  'primo': ['91'],
  'mcd': ['48', '18'],
  'tabelline': <String>[],
  'blink': <String>[],
  'pulsante': <String>[],
  'dimmer': <String>[],
};

/// Cartella degli esempi di una lingua (l'italiano è nella cartella principale).
String examplesDir(AppLanguage l) =>
    l == AppLanguage.it ? 'assets/examples' : 'assets/examples/${l.name}';

String parseError(String src) {
  try {
    parseExpression(src);
  } on ExprError catch (e) {
    return e.message;
  }
  return '';
}

void main() {
  tearDown(() => setLanguage(AppLanguage.it));

  for (final lang in AppLanguage.values) {
    group(lang.nativeName, () {
      setUp(() => setLanguage(lang));

      for (final MapEntry(key: name, value: inputs) in exampleInputs.entries) {
        test('esempio $name: valido, eseguibile, genera codice', () {
          final file = File('${examplesDir(lang)}/$name.flow');
          expect(file.existsSync(), isTrue, reason: file.path);
          final p = decodeProgram(file.readAsStringSync());
          expect(validate(p).map((i) => i.message), isEmpty, reason: file.path);
          expect(layoutProgram(p).boxes, isNotEmpty);
          for (final l in CodeLanguage.forProgram(p)) {
            expect(generateCode(p, l), isNotEmpty);
          }
          if (!p.isArduino) {
            final r = runToEnd(p, inputs);
            expect(r.error, isNull, reason: '${file.path}: ${r.error}');
            expect(r.output, isNotEmpty);
          }
        });
      }

      test('stessi esempi, stessa struttura dell\'italiano', () {
        for (final name in exampleInputs.keys) {
          final it = decodeProgram(File('assets/examples/$name.flow').readAsStringSync());
          final other = decodeProgram(File('${examplesDir(lang)}/$name.flow').readAsStringSync());
          expect(other.kind, it.kind, reason: name);
          expect(other.allStmts.length, it.allStmts.length, reason: name);
          expect(
            other.allStmts.map((s) => s.runtimeType).toList(),
            it.allStmts.map((s) => s.runtimeType).toList(),
            reason: name,
          );
        }
      });

      test('messaggi e parole chiave nella lingua giusta', () {
        expect(tr.language, lang);
        expect(parseError('a +'), isNotEmpty);
        expect(tr.pIf('x'), contains('x'));
        expect(tr.inputPrompt('n'), contains('n'));
        if (lang != AppLanguage.it) {
          final it = trFor(AppLanguage.it);
          expect(parseError('a +'), isNot(it.parseIncomplete), reason: 'non tradotto');
          expect(tr.newDiagram, isNot(it.newDiagram));
          expect(tr.pIf('x'), isNot(it.pIf('x')));
          expect(tr.typeInteger, isNot(it.typeInteger));
          expect(
            tr.privacySections('A', 'B', 'C', 'D').length,
            it.privacySections('A', 'B', 'C', 'D').length,
          );
          expect(tr.guideBlockItems.length, it.guideBlockItems.length);
          expect(tr.guideExpressionItems.length, it.guideExpressionItems.length);
        }
        // le parole di vero/falso della lingua sono accettate dal parser
        expect(parseError(tr.trueWord), isEmpty);
        expect(parseError(tr.falseWord), isEmpty);
      });

      test('nessuna affermazione vietata', () {
        final all = [
          ...tr.privacySections('App', 'Prof. X', 'L', 'x@y.it').expand((s) => [s.$1, ...s.$2]),
          tr.licenseText('L'),
          tr.aboutDescription,
          tr.privacySummary,
        ].join(' ');
        expect(
          RegExp(r'open.?source|GDPR|RGPD|DSGVO', caseSensitive: false).hasMatch(all),
          isFalse,
        );
      });
    });
  }

  test('ogni lingua ha un nome di programma predefinito diverso dal vuoto', () {
    for (final l in AppLanguage.values) {
      expect(trFor(l).untitled, isNotEmpty);
      expect(Program(name: trFor(l).untitled).name, isNotEmpty);
    }
  });
}
