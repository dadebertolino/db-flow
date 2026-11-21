/// Esercizio con verifica dell'output: consegna e casi di prova. Dart puro.
library;

/// Un caso di prova: i valori dati in ingresso, uno per ogni blocco "Leggi",
/// e le righe che il programma deve scrivere.
final class TestCase {
  TestCase({List<String> inputs = const [], List<String> expected = const [], this.hidden = false})
    : inputs = List.unmodifiable(inputs),
      expected = List.unmodifiable(expected);

  final List<String> inputs;
  final List<String> expected;

  /// Nascosto: lo studente vede solo se passa, non i valori.
  final bool hidden;

  TestCase copyWith({List<String>? inputs, List<String>? expected, bool? hidden}) => TestCase(
    inputs: inputs ?? this.inputs,
    expected: expected ?? this.expected,
    hidden: hidden ?? this.hidden,
  );

  @override
  bool operator ==(Object other) =>
      other is TestCase &&
      other.hidden == hidden &&
      _listEq(other.inputs, inputs) &&
      _listEq(other.expected, expected);

  @override
  int get hashCode => Object.hash(hidden, Object.hashAll(inputs), Object.hashAll(expected));
}

/// Consegna e casi di prova allegati a un diagramma.
final class Exercise {
  Exercise({this.text = '', List<TestCase> cases = const [], this.locked = false})
    : cases = List.unmodifiable(cases);

  /// Testo della consegna.
  final String text;
  final List<TestCase> cases;

  /// Esercizio consegnato agli studenti: nell'app non si modifica e i casi
  /// nascosti non si mostrano. La copia del docente non è bloccata.
  final bool locked;

  List<TestCase> get visibleCases => [
    for (final c in cases)
      if (!c.hidden) c,
  ];

  Exercise copyWith({String? text, List<TestCase>? cases, bool? locked}) =>
      Exercise(text: text ?? this.text, cases: cases ?? this.cases, locked: locked ?? this.locked);

  @override
  bool operator ==(Object other) =>
      other is Exercise &&
      other.text == text &&
      other.locked == locked &&
      _listEq(other.cases, cases);

  @override
  int get hashCode => Object.hash(text, locked, Object.hashAll(cases));
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
