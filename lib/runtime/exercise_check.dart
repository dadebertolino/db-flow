/// Verifica di un esercizio: esegue il diagramma su ogni caso di prova e
/// confronta l'output con quello atteso, in modo tollerante. Dart puro.
library;

import 'dart:math' as math;

import '../i18n/tr.dart';
import '../model/exercise.dart';
import '../model/program.dart';
import 'environment.dart';
import 'interpreter.dart';

enum CaseOutcome {
  passed,

  /// Il programma termina ma scrive qualcosa di diverso.
  wrongOutput,

  /// Il programma chiede più valori di quelli del caso.
  missingInput,

  /// Il programma termina senza leggere tutti i valori del caso.
  unusedInput,

  /// Un valore del caso non va bene per la variabile che lo legge.
  badInput,

  /// Errore durante l'esecuzione (anche: troppi passi).
  error,
}

final class CaseResult {
  const CaseResult(this.testCase, this.outcome, this.output, {this.error});

  final TestCase testCase;
  final CaseOutcome outcome;

  /// Righe scritte dal programma.
  final List<String> output;

  /// Messaggio per [CaseOutcome.error] e [CaseOutcome.badInput].
  final String? error;

  bool get passed => outcome == CaseOutcome.passed;
}

/// Esecuzione di [p] con gli input dati, senza confronto.
({List<String> output, CaseOutcome outcome, String? error}) runWithInputs(
  Program p,
  List<String> inputs, {
  math.Random? random,
  int maxSteps = 10000,
}) {
  final it = Interpreter(p, random: random, maxSteps: maxSteps);
  final out = <String>[];
  var next = 0;
  while (true) {
    switch (it.next()) {
      case StepEvent(:final output?):
        out.add(output);
      case StepEvent() || LoopStart():
        break;
      case InputRequest(:final type):
        if (next >= inputs.length) {
          return (output: out, outcome: CaseOutcome.missingInput, error: null);
        }
        final parsed = parseInput(inputs[next++], type);
        if (parsed.error != null) {
          return (output: out, outcome: CaseOutcome.badInput, error: parsed.error);
        }
        it.provideInput(parsed.value!);
      case Finished():
        return (
          output: out,
          outcome: next < inputs.length ? CaseOutcome.unusedInput : CaseOutcome.passed,
          error: null,
        );
      case Failed(:final message):
        return (output: out, outcome: CaseOutcome.error, error: message);
    }
  }
}

CaseResult checkCase(Program p, TestCase c, {math.Random? random}) {
  final r = runWithInputs(p, c.inputs, random: random);
  if (r.outcome != CaseOutcome.passed) {
    return CaseResult(c, r.outcome, r.output, error: r.error);
  }
  return CaseResult(
    c,
    outputsMatch(c.expected, r.output) ? CaseOutcome.passed : CaseOutcome.wrongOutput,
    r.output,
  );
}

List<CaseResult> checkExercise(Program p, {math.Random? random}) => [
  for (final c in p.exercise?.cases ?? const <TestCase>[]) checkCase(p, c, random: random),
];

// ---------------------------------------------------------------- confronto

/// Confronto tollerante, riga per riga: ignora maiuscole, spazi, righe vuote
/// e la punteggiatura `. , ; : ! ?`; i numeri valgono per il valore (`5` =
/// `5.0`, `2,5` = `2.5`); vero/falso in qualsiasi lingua.
bool outputsMatch(List<String> expected, List<String> actual) {
  final a = _lines(expected), b = _lines(actual);
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].length != b[i].length) return false;
    for (var j = 0; j < a[i].length; j++) {
      if (!_tokenEq(a[i][j], b[i][j])) return false;
    }
  }
  return true;
}

List<List<Object>> _lines(List<String> lines) => [
  for (final l in lines.expand((l) => l.split('\n')))
    if (_tokens(l) case final t when t.isNotEmpty) t,
];

final _decimalComma = RegExp(r'^(-?\d+),(\d+)([.;:!?]?)$');
final _token = RegExp(
  r'-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?|[\p{L}\p{N}_]+|[^\s\p{L}\p{N}]',
  unicode: true,
);
const _ignored = {'.', ',', ';', ':', '!', '?'};

List<Object> _tokens(String line) {
  final result = <Object>[];
  for (var chunk in line.toLowerCase().split(RegExp(r'\s+'))) {
    chunk = chunk.replaceFirstMapped(_decimalComma, (m) => '${m[1]}.${m[2]}${m[3]}');
    for (final m in _token.allMatches(chunk)) {
      final t = m[0]!;
      if (_ignored.contains(t)) continue;
      final n = double.tryParse(t);
      if (n != null) {
        result.add(n);
      } else if (trueWords.contains(t)) {
        result.add(true);
      } else if (falseWords.contains(t)) {
        result.add(false);
      } else {
        result.add(t);
      }
    }
  }
  return result;
}

bool _tokenEq(Object a, Object b) {
  if (a is double && b is double) {
    return (a - b).abs() <= 1e-6 * math.max(1, math.max(a.abs(), b.abs()));
  }
  return a == b;
}
