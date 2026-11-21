/// Generazione del codice: interfaccia e strumenti comuni. Dart puro.
library;

import '../expr/errors.dart';
import '../expr/type_checker.dart';
import '../i18n/tr.dart';
import '../model/expr.dart';
import '../model/program.dart';
import '../model/stmt.dart';
import '../model/validator.dart' show arduinoConstantTypes;
import 'arduino_gen.dart';
import 'c_gen.dart';
import 'pseudo_gen.dart';
import 'python_gen.dart';

enum CodeLanguage {
  arduino('Arduino', 'ino'),
  pseudo('', 'txt'),
  python('Python', 'py'),
  c('C', 'c');

  const CodeLanguage(this._label, this.extension);
  final String _label;

  /// Nome mostrato (lo pseudocodice è tradotto).
  String get label => this == pseudo ? tr.codeLanguagePseudo : _label;
  final String extension;

  /// Linguaggi disponibili per un programma.
  static List<CodeLanguage> forProgram(Program p) =>
      p.isArduino ? const [arduino, pseudo] : const [pseudo, python, c];
}

String generateCode(Program p, CodeLanguage lang) => switch (lang) {
  CodeLanguage.python => PythonGenerator(p).generate(),
  CodeLanguage.c => CGenerator(p).generate(),
  CodeLanguage.pseudo => PseudoGenerator(p).generate(),
  CodeLanguage.arduino => ArduinoGenerator(p).generate(),
};

/// Prompt mostrato prima di ogni lettura nel codice generato.
String inputPrompt(String variable) => tr.inputPrompt(variable);

/// Testo con indentazione.
final class CodeWriter {
  CodeWriter([this.unit = '    ']);
  final String unit;
  final _buf = StringBuffer();
  int depth = 0;

  void line([String text = '']) {
    if (text.isEmpty) {
      _buf.writeln();
    } else {
      _buf.writeln('${unit * depth}$text');
    }
  }

  void indented(void Function() body) {
    depth++;
    body();
    depth--;
  }

  @override
  String toString() => _buf.toString();
}

/// Base comune: tipi delle variabili e delle espressioni.
abstract class BaseGenerator {
  BaseGenerator(this.program)
    : vars = {
        for (final s in program.allStmts)
          if (s case Declare(:final name, :final type) when name.isNotEmpty) name: type,
      },
      constants = program.arduino == null ? const {} : arduinoConstantTypes(program.arduino!);

  final Program program;

  /// Variabili dichiarate (in ordine).
  final Map<String, VarType> vars;

  /// Costanti di Arduino (HIGH, LOW, A0…, nomi dei pin).
  final Map<String, VarType> constants;

  String generate();

  /// Tipo di [e], o `null` se l'espressione contiene errori.
  VarType? typeOfExpr(Expr e) {
    try {
      return typeOf(e, {...constants, ...vars}, arduino: program.isArduino);
    } on ExprError {
      return null;
    }
  }

  /// Usa le funzioni o i blocchi indicati?
  bool usesCall(String name) => _calls.contains(name);
  bool usesType(VarType t) => vars.values.contains(t);

  late final Set<String> _calls = {
    for (final s in program.allStmts)
      for (final src in exprsOf(s))
        if (src.expr case final e?) ..._callNames(e),
  };

  static Iterable<String> _callNames(Expr e) sync* {
    switch (e) {
      case Call(:final name, :final args):
        yield name;
        for (final a in args) {
          yield* _callNames(a);
        }
      case Unary(:final operand):
        yield* _callNames(operand);
      case Binary(:final left, :final right):
        yield* _callNames(left);
        yield* _callNames(right);
      case Literal() || VarRef():
        break;
    }
  }
}

/// Espressioni contenute in un blocco.
List<ExprSource> exprsOf(Stmt s) => switch (s) {
  Assign(:final value) || Output(:final value) => [value],
  If(:final cond) || While(:final cond) || DoWhile(:final cond) => [cond],
  For(:final from, :final to, :final step) => [from, to, step],
  DigitalWrite(:final pin, :final value) || AnalogWrite(:final pin, :final value) => [pin, value],
  Delay(:final ms) => [ms],
  DigitalRead(:final pin) || AnalogRead(:final pin) => [pin],
  Declare() || Input() || Comment() => const [],
};

/// Letterale stringa tra virgolette doppie, valido in Python e in C.
String quote(String s) {
  final b = StringBuffer('"');
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    b.write(switch (ch) {
      '\\' => r'\\',
      '"' => r'\"',
      '\n' => r'\n',
      '\t' => r'\t',
      _ => ch,
    });
  }
  b.write('"');
  return b.toString();
}

/// Precedenze nel nostro linguaggio (più alto = lega di più).
int precedenceOf(BinaryOp op) => switch (op) {
  BinaryOp.or => 1,
  BinaryOp.and => 2,
  BinaryOp.eq || BinaryOp.ne || BinaryOp.lt || BinaryOp.le || BinaryOp.gt || BinaryOp.ge => 4,
  BinaryOp.add || BinaryOp.sub || BinaryOp.concat => 5,
  BinaryOp.mul || BinaryOp.div || BinaryOp.mod => 6,
};

const precUnary = 7;
const precAtom = 9;

/// Iniziali delle risposte «vero» accettate in input booleano, in tutte le
/// lingue (vero, true, wahr, sì, yes, oui, ja, 1).
const trueInitials = 'vtwsyoj1';
