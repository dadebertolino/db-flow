import '../arduino/board.dart';
import '../i18n/tr.dart';
import 'exercise.dart';
import 'stmt.dart';

/// Tipo di diagramma.
enum ProgramKind {
  /// Algoritmo generico: Inizio → corpo → Fine.
  algorithm,

  /// Sketch Arduino: `setup()` eseguito una volta, poi `loop()` ripetuto.
  arduino;

  String get label => this == algorithm ? tr.kindAlgorithm : tr.kindArduino;

  static ProgramKind fromName(String? n) => n == 'arduino' ? arduino : algorithm;
}

/// Id fittizio della lista `setup` negli [Slot] (il corpo principale ha `null`).
const setupListId = '#setup';

/// Programma completo. Immutabile: ogni modifica produce un nuovo [Program]
/// (base per undo/redo a snapshot).
///
/// Per un diagramma Arduino [body] è il contenuto di `loop()` e [setup] quello
/// di `setup()`; per un algoritmo [setup] è sempre vuoto.
final class Program {
  Program({
    required this.name,
    List<Stmt> body = const [],
    this.kind = ProgramKind.algorithm,
    List<Stmt> setup = const [],
    ArduinoConfig? arduino,
    Exercise? exercise,
  }) : body = List.unmodifiable(body),
       setup = List.unmodifiable(setup),
       arduino = kind == ProgramKind.arduino ? (arduino ?? ArduinoConfig()) : null,
       exercise = kind == ProgramKind.algorithm ? exercise : null;

  /// Versione corrente del formato file `.flow`.
  static const formatVersion = 2;

  final String name;
  final ProgramKind kind;
  final List<Stmt> body;
  final List<Stmt> setup;

  /// Configurazione hardware; presente solo nei diagrammi Arduino.
  final ArduinoConfig? arduino;

  /// Consegna e casi di prova; solo per gli algoritmi.
  final Exercise? exercise;

  bool get isArduino => kind == ProgramKind.arduino;

  /// Tutti i blocchi in ordine di esecuzione: prima `setup`, poi il corpo.
  Iterable<Stmt> get allStmts sync* {
    yield* walk(setup);
    yield* walk(body);
  }

  Program copyWith({String? name, List<Stmt>? body, List<Stmt>? setup, ArduinoConfig? arduino}) =>
      Program(
        name: name ?? this.name,
        kind: kind,
        body: body ?? this.body,
        setup: setup ?? this.setup,
        arduino: arduino ?? this.arduino,
        exercise: exercise,
      );

  /// Copia con l'esercizio sostituito o tolto (`null`).
  Program withExercise(Exercise? e) =>
      Program(name: name, kind: kind, body: body, setup: setup, arduino: arduino, exercise: e);
}

/// Visita in pre-ordine tutti i blocchi di [stmts], rami e corpi compresi.
Iterable<Stmt> walk(List<Stmt> stmts) sync* {
  for (final s in stmts) {
    yield s;
    switch (s) {
      case If(:final then, :final otherwise):
        yield* walk(then);
        yield* walk(otherwise);
      case While(:final body) || DoWhile(:final body) || For(:final body):
        yield* walk(body);
      case Declare() ||
          Assign() ||
          Input() ||
          Output() ||
          Comment() ||
          DigitalWrite() ||
          AnalogWrite() ||
          DigitalRead() ||
          AnalogRead() ||
          Delay():
        break;
    }
  }
}
