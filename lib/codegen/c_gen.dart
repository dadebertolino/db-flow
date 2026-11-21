/// Generatore C (C99). Dart puro.
///
/// Scelte: le dichiarazioni sono raccolte in cima a `main` (le variabili sono
/// globali nel diagramma); stringhe come `char[256]`; booleani con
/// `stdbool.h`; le espressioni di testo (`&`, `+` tra stringhe) diventano
/// stringhe di formato per `printf`/`snprintf`. I reali si stampano con `%g`.
library;

import '../expr/types.dart';
import '../i18n/tr.dart';
import '../layout/labels.dart';
import '../model/expr.dart';
import '../model/program.dart';
import '../model/stmt.dart';
import 'generator.dart';

final class CGenerator extends BaseGenerator {
  CGenerator(super.program);

  final _w = CodeWriter();

  @override
  String generate() {
    final readsBool = walk(program.body)
        .any((s) => s is Input && vars[s.variable] == VarType.boolean);
    final usesString = usesType(VarType.string) || _hasStringCompare || readsBool;
    final headers = [
      'stdio.h',
      if (usesType(VarType.boolean) || _hasBoolLiteral) 'stdbool.h',
      if (usesCall('abs') || usesCall('random')) 'stdlib.h',
      if (usesString || usesCall('len')) 'string.h',
      if (usesCall('sqrt') || usesCall('round') || usesCall('abs')) 'math.h',
      if (usesCall('random')) 'time.h',
    ];
    _w.line('/* ${program.name.replaceAll('*/', '* /')} */');
    _w.line('/* ${tr.codeGenerated} */');
    _w.line();
    for (final h in headers) {
      _w.line('#include <$h>');
    }
    _w.line();
    _w.line('int main(void) {');
    _w.indented(() {
      for (final e in vars.entries) {
        _w.line(switch (e.value) {
          VarType.integer => 'int ${e.key} = 0;',
          VarType.real => 'double ${e.key} = 0.0;',
          VarType.string => 'char ${e.key}[256] = "";',
          VarType.boolean => 'bool ${e.key} = false;',
        });
      }
      if (usesCall('random')) _w.line('srand((unsigned) time(NULL));');
      if (vars.isNotEmpty || usesCall('random')) _w.line();
      _block(program.body);
      _w.line('return 0;');
    });
    _w.line('}');
    return _w.toString();
  }

  bool get _hasBoolLiteral => _anyExpr((e) => e is Literal && e.value is BoolV);

  bool get _hasStringCompare =>
      _anyExpr((e) => e is Binary && e.op.isComparison && typeOfExpr(e.left) == VarType.string);

  bool _anyExpr(bool Function(Expr) test) {
    bool visit(Expr e) =>
        test(e) ||
        switch (e) {
          Unary(:final operand) => visit(operand),
          Binary(:final left, :final right) => visit(left) || visit(right),
          Call(:final args) => args.any(visit),
          _ => false,
        };
    for (final s in _allStmts) {
      for (final src in exprsOf(s)) {
        if (src.expr case final e? when visit(e)) return true;
      }
    }
    return false;
  }

  late final _allStmts = [for (final s in _walk(program.body)) s];

  static Iterable<Stmt> _walk(List<Stmt> list) sync* {
    for (final s in list) {
      yield s;
      switch (s) {
        case If(:final then, :final otherwise):
          yield* _walk(then);
          yield* _walk(otherwise);
        case While(:final body) || DoWhile(:final body) || For(:final body):
          yield* _walk(body);
        default:
          break;
      }
    }
  }

  void _block(List<Stmt> list) {
    for (final s in list) {
      _stmt(s);
    }
  }

  void _braced(String head, List<Stmt> body, [String tail = '}']) {
    _w.line('$head {');
    _w.indented(() => _block(body));
    _w.line(tail);
  }

  void _stmt(Stmt s) {
    switch (s) {
      case Declare():
        break; // dichiarazioni già raccolte in cima a main
      case Assign(:final target, :final value):
        _assign(target, value);
      case Input(:final variable):
        _w.line('printf(${quote(inputPrompt(variable))});');
        switch (vars[variable]) {
          case VarType.integer:
            _w.line('scanf("%d", &$variable);');
          case VarType.real:
            _w.line('scanf("%lf", &$variable);');
          case VarType.boolean:
            _w.line('{');
            _w.indented(() {
              final r = tr.codeAnswerVar;
              _w.line('char $r[16] = "";');
              _w.line('scanf("%15s", $r);');
              _w.line(
                '$variable = $r[0] != 0 && strchr("$trueInitials${trueInitials.toUpperCase()}", $r[0]) != NULL;',
              );
            });
            _w.line('}');
          default:
            _w.line('scanf(" %255[^\\n]", $variable);');
        }
      case Output(:final value):
        final e = value.expr;
        if (e == null) {
          _w.line('/* ${tr.codeInvalidExpr(value.text)} */');
        } else {
          final (fmt, args) = _format(e);
          _w.line('printf(${quote('$fmt\n')}${_args(args)});');
        }
      case If(:final cond, :final then, :final otherwise):
        if (otherwise.isEmpty) {
          _braced('if (${_src(cond)})', then);
        } else {
          _braced('if (${_src(cond)})', then, '} else {');
          _w.indented(() => _block(otherwise));
          _w.line('}');
        }
      case While(:final cond, :final body):
        _braced('while (${_src(cond)})', body);
      case DoWhile(:final cond, :final body):
        _braced('do', body, '} while (${_src(cond)});');
      case For(:final variable, :final from, :final to, :final step, :final body):
        final s = constInt(step.expr);
        final t = _src(to);
        final cond = switch (s) {
          null => '(${_src(step)} > 0 ? $variable <= $t : $variable >= $t)',
          > 0 => '$variable <= $t',
          _ => '$variable >= $t',
        };
        final inc = switch (s) {
          1 => '$variable++',
          -1 => '$variable--',
          null => '$variable += ${_src(step)}',
          > 0 => '$variable += $s',
          _ => '$variable -= ${-s}',
        };
        _braced('for ($variable = ${_src(from)}; $cond; $inc)', body);
      case DigitalWrite() || AnalogWrite() || DigitalRead() || AnalogRead() || Delay():
        _w.line('/* ${tr.codeArduinoOnly(blockLabel(s))} */');
      case Comment(:final text):
        for (final l in text.split('\n')) {
          _w.line('// $l');
        }
    }
  }

  void _assign(String target, ExprSource value) {
    final e = value.expr;
    if (e == null) {
      _w.line('/* ${tr.codeInvalidExpr(value.text)} */');
      return;
    }
    if (vars[target] != VarType.string) {
      _w.line('$target = ${_expr(e, 0)};');
      return;
    }
    final (fmt, args) = _format(e);
    final usesSelf = args.any((a) => RegExp('\\b$target\\b').hasMatch(a));
    if (!usesSelf) {
      _w.line('snprintf($target, sizeof $target, ${quote(fmt)}${_args(args)});');
    } else {
      _w.line('{');
      _w.indented(() {
        _w.line('char tmp[256];');
        _w.line('snprintf(tmp, sizeof tmp, ${quote(fmt)}${_args(args)});');
        _w.line('strcpy($target, tmp);');
      });
      _w.line('}');
    }
  }

  static String _args(List<String> args) => args.isEmpty ? '' : ', ${args.join(', ')}';

  /// Scompone un'espressione di testo in stringa di formato + argomenti.
  (String, List<String>) _format(Expr e) {
    final fmt = StringBuffer();
    final args = <String>[];
    void part(Expr p) {
      final isTextJoin =
          p is Binary &&
          (p.op == BinaryOp.concat || (p.op == BinaryOp.add && typeOfExpr(p) == VarType.string));
      if (isTextJoin) {
        part(p.left);
        part(p.right);
        return;
      }
      if (p case Literal(value: StrV(:final value))) {
        fmt.write(value.replaceAll('%', '%%'));
        return;
      }
      switch (typeOfExpr(p)) {
        case VarType.integer:
          fmt.write('%d');
          args.add(_expr(p, 0));
        case VarType.real:
          fmt.write('%g');
          args.add(_expr(p, 0));
        case VarType.boolean:
          fmt.write('%s');
          args.add('${_expr(p, 2)} ? ${quote(tr.trueWord)} : ${quote(tr.falseWord)}');
        case VarType.string || null:
          fmt.write('%s');
          args.add(_expr(p, 0));
      }
    }

    part(e);
    return (fmt.toString(), args);
  }

  String _src(ExprSource src) =>
      src.expr == null ? '/* ${tr.codeInvalidExpr(src.text)} */ 0' : _expr(src.expr!, 0);

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
            BoolV(:final value) => value ? 'true' : 'false',
          },
          precAtom,
        );
      case VarRef(:final name):
        return (name, precAtom);
      case Unary(:final op, :final operand):
        final inner = _expr(operand, precUnary);
        final safe = inner.startsWith('-') ? '($inner)' : inner;
        return ('${op == UnaryOp.neg ? '-' : '!'}$safe', precUnary);
      case Binary(:final op, :final left, :final right):
        final p = precedenceOf(op);
        // Dentro `||` si racchiude `&&` tra parentesi (più leggibile, niente avvisi).
        final leftMin = op == BinaryOp.or ? p + 2 : (op.isComparison ? p + 1 : p);
        final l = _expr(left, leftMin);
        final r = _expr(right, op == BinaryOp.or ? p + 2 : p + 1);
        if (op.isComparison && typeOfExpr(left) == VarType.string) {
          return ('strcmp(${_expr(left, 0)}, ${_expr(right, 0)}) ${op.symbol} 0', p);
        }
        return switch (op) {
          BinaryOp.and => ('$l && $r', p),
          BinaryOp.or => ('$l || $r', p),
          BinaryOp.div
              when typeOfExpr(left) == VarType.integer && typeOfExpr(right) == VarType.integer =>
            ('(double) $l / $r', p),
          BinaryOp.concat || BinaryOp.add when typeOfExpr(e) == VarType.string => (
            '/* ${tr.codeConcatUnsupported} */ ""',
            precAtom,
          ),
          _ => ('$l ${op.symbol} $r', p),
        };
      case Call(:final name, :final args):
        final arg = args.single;
        final a = _expr(arg, 0);
        return switch (name) {
          'abs' when typeOfExpr(arg) == VarType.real => ('fabs($a)', precAtom),
          'int' => ('(int) (${_expr(arg, 0)})', precUnary),
          'round' => ('(int) lround($a)', precUnary),
          'len' => ('(int) strlen($a)', precUnary),
          'random' => ('rand() % ${_expr(arg, precUnary)}', 6),
          _ => ('$name($a)', precAtom),
        };
    }
  }
}
