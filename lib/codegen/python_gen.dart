/// Generatore Python 3. Dart puro.
///
/// Differenze note rispetto all'esecuzione nell'app (solo con numeri negativi
/// o casi limite): `%` di Python segue il segno del divisore; `round` di Python
/// arrotonda 0.5 al pari; dopo un `for` il contatore vale l'ultimo valore usato.
library;

import '../expr/types.dart';
import '../i18n/tr.dart';
import '../layout/labels.dart';
import '../model/expr.dart';
import '../model/stmt.dart';
import 'generator.dart';

final class PythonGenerator extends BaseGenerator {
  PythonGenerator(super.program);

  final _w = CodeWriter();

  @override
  String generate() {
    _w.line('# ${program.name}');
    _w.line('# ${tr.codeGenerated}');
    final imports = [if (usesCall('sqrt')) 'math', if (usesCall('random')) 'random'];
    if (imports.isNotEmpty) {
      _w.line();
      for (final i in imports) {
        _w.line('import $i');
      }
    }
    _w.line();
    _block(program.body);
    return _w.toString();
  }

  void _block(List<Stmt> list) {
    if (list.isEmpty || list.every((s) => s is Comment)) {
      for (final s in list) {
        _stmt(s);
      }
      _w.line('pass');
      return;
    }
    for (final s in list) {
      _stmt(s);
    }
  }

  void _stmt(Stmt s) {
    switch (s) {
      case Declare(:final name, :final type):
        _w.line('$name = ${_default(type)}');
      case Assign(:final target, :final value):
        _w.line('$target = ${_src(value)}');
      case Input(:final variable):
        final prompt = quote(inputPrompt(variable));
        _w.line(switch (vars[variable]) {
          VarType.integer => '$variable = int(input($prompt))',
          VarType.real => '$variable = float(input($prompt).replace(",", "."))',
          VarType.boolean => '$variable = input($prompt).strip().lower() in ($_pyTrueAnswers)',
          _ => '$variable = input($prompt)',
        });
      case Output(:final value):
        _w.line('print(${_src(value)})');
      case If(:final cond, :final then, :final otherwise):
        _w.line('if ${_src(cond)}:');
        _w.indented(() => _block(then));
        if (otherwise.isNotEmpty) {
          _w.line('else:');
          _w.indented(() => _block(otherwise));
        }
      case While(:final cond, :final body):
        _w.line('while ${_src(cond)}:');
        _w.indented(() => _block(body));
      case DoWhile(:final cond, :final body):
        _w.line('while True:');
        _w.indented(() {
          for (final b in body) {
            _stmt(b);
          }
          _w.line('if not (${_src(cond)}):');
          _w.indented(() => _w.line('break'));
        });
      case For(:final variable, :final from, :final to, :final step, :final body):
        _w.line('for $variable in ${_range(from, to, step)}:');
        _w.indented(() => _block(body));
      case DigitalWrite() || AnalogWrite() || DigitalRead() || AnalogRead() || Delay():
        _w.line('# ${tr.codeArduinoOnly(blockLabel(s))}');
      case Comment(:final text):
        for (final l in text.split('\n')) {
          _w.line('# $l');
        }
    }
  }

  String _range(ExprSource from, ExprSource to, ExprSource step) {
    final f = _src(from);
    final s = constInt(step.expr);
    final toConst = constInt(to.expr);
    String end(int delta) =>
        toConst != null ? '${toConst + delta}' : '${_expr(to.expr!, 5)} ${delta > 0 ? '+' : '-'} 1';
    if (to.expr == null || step.expr == null) return 'range($f, ${to.text}, ${step.text})';
    if (s == 1) return 'range($f, ${end(1)})';
    if (s != null) return 'range($f, ${end(s > 0 ? 1 : -1)}, $s)';
    final st = _src(step);
    return 'range($f, ${_expr(to.expr!, 5)} + (1 if $st > 0 else -1), $st)';
  }

  static String _default(VarType t) => switch (t) {
    VarType.integer => '0',
    VarType.real => '0.0',
    VarType.string => '""',
    VarType.boolean => 'False',
  };

  String _src(ExprSource src) =>
      src.expr == null ? '${src.text}  # ${tr.codeInvalidExpr(src.text)}' : _expr(src.expr!, 0);

  /// Precedenze di Python: or 1, and 2, not 3, confronti 4, + - 5, * / % 6, segno 7.
  String _expr(Expr e, int minPrec) {
    final (text, prec) = _render(e);
    return prec < minPrec ? '($text)' : text;
  }

  (String, int) _render(Expr e) {
    switch (e) {
      case Literal(:final value):
        return (
          switch (value) {
            IntV(:final value) => '$value',
            RealV(:final value) => '$value',
            StrV(:final value) => quote(value),
            BoolV(:final value) => value ? 'True' : 'False',
          },
          precAtom,
        );
      case VarRef(:final name):
        return (name, precAtom);
      case Unary(op: UnaryOp.neg, :final operand):
        final inner = _expr(operand, precUnary);
        return ('-${inner.startsWith('-') ? '($inner)' : inner}', precUnary);
      case Unary(op: UnaryOp.not, :final operand):
        // In Python `not` lega meno dei confronti: si racchiude l'operando se non è semplice.
        return ('not ${_expr(operand, precUnary)}', 3);
      case Binary(op: BinaryOp.concat, :final left, :final right):
        return ('${_asText(left)} + ${_asText(right)}', 5);
      case Binary(:final op, :final left, :final right):
        final p = precedenceOf(op);
        final rightMin = p + 1; // associatività a sinistra; confronti mai concatenati
        final leftMin = op.isComparison ? p + 1 : p;
        return ('${_expr(left, leftMin)} ${op.symbol} ${_expr(right, rightMin)}', p);
      case Call(:final name, :final args):
        final a = _expr(args.single, 0);
        return (
          switch (name) {
            'sqrt' => 'math.sqrt($a)',
            'random' => 'random.randrange($a)',
            _ => '$name($a)',
          },
          precAtom,
        );
    }
  }

  /// Operando di `&`: convertito in testo come lo mostra l'app.
  String _asText(Expr e) => switch (typeOfExpr(e)) {
    VarType.string => _expr(e, 5),
    VarType.boolean => '(${quote(tr.trueWord)} if ${_expr(e, 4)} else ${quote(tr.falseWord)})',
    _ => 'str(${_expr(e, 0)})',
  };
}

/// Risposte «vero» accettate in input booleano, come tupla Python.
final String _pyTrueAnswers = (trueAnswers.toList()..sort()).map((w) => '"$w"').join(', ');
