/// Generatore di sketch Arduino (`.ino`, C++). Dart puro.
///
/// Scelte:
/// - le variabili sono globali; `intero` → `long` (su Uno `int` arriva solo a
///   32767), `reale` → `float`, `stringa` → `String`, `booleano` → `bool`;
/// - i pin configurati diventano costanti (`const int LED = 13;`) e `setup()`
///   inizia con i `pinMode` e, se servono, con `Serial.begin`;
/// - "Leggi" aspetta una riga dalla seriale e la converte; "Scrivi" usa
///   `Serial.print` a pezzi (niente concatenazioni di `String` in memoria).
library;

import '../arduino/board.dart';
import '../expr/types.dart';
import '../i18n/tr.dart';
import '../model/expr.dart';
import '../model/stmt.dart';
import 'generator.dart';

final class ArduinoGenerator extends BaseGenerator {
  ArduinoGenerator(super.program);

  final _w = CodeWriter('  ');

  ArduinoConfig get cfg => program.arduino!;

  bool get _usesSerial => program.allStmts.any((s) => s is Input || s is Output);

  @override
  String generate() {
    final board = cfg.board;
    _w.line('// ${program.name}');
    _w.line('// ${tr.codeGeneratedFor(board.name)}');
    if (cfg.pins.isNotEmpty) {
      _w.line('//');
      _w.line('// ${tr.codeConnections}');
      for (final p in cfg.pins) {
        final what = p.component == Component.other ? '' : '${p.component.label}, ';
        _w.line('//   ${p.name.padRight(12)} pin ${p.pin.padRight(3)} ($what${p.mode.label})');
      }
    }
    _w.line();
    for (final p in cfg.pins) {
      _w.line('const int ${p.name} = ${p.pin};');
    }
    if (cfg.pins.isNotEmpty) _w.line();
    for (final e in vars.entries) {
      _w.line(switch (e.value) {
        VarType.integer => 'long ${e.key} = 0;',
        VarType.real => 'float ${e.key} = 0.0;',
        VarType.string => 'String ${e.key} = "";',
        VarType.boolean => 'bool ${e.key} = false;',
      });
    }
    if (vars.isNotEmpty) _w.line();

    _w.line('void setup() {');
    _w.indented(() {
      for (final p in cfg.pins) {
        if (p.mode.arduino case final mode?) _w.line('pinMode(${p.name}, $mode);');
      }
      if (_usesSerial) _w.line('Serial.begin(${cfg.baud});');
      _block(program.setup);
    });
    _w.line('}');
    _w.line();
    _w.line('void loop() {');
    _w.indented(() => _block(program.body));
    _w.line('}');
    return _w.toString();
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
        break; // variabili globali, dichiarate in cima
      case Assign(:final target, :final value):
        _w.line('$target = ${_src(value)};');
      case Input(:final variable):
        _w.line('Serial.print(${quote(inputPrompt(variable))});');
        _w.line('while (Serial.available() == 0) {');
        _w.line('}');
        switch (vars[variable]) {
          case VarType.integer:
            _w.line("$variable = Serial.readStringUntil('\\n').toInt();");
          case VarType.real:
            _w.line("$variable = Serial.readStringUntil('\\n').toFloat();");
          case VarType.boolean:
            _w.line('{');
            _w.indented(() {
              final r = tr.codeAnswerVar;
              _w.line("String $r = Serial.readStringUntil('\\n');");
              _w.line('$r.trim();');
              _w.line('$r.toLowerCase();');
              _w.line(
                '$variable = $r.length() > 0 && String("$trueInitials").indexOf($r.charAt(0)) >= 0;',
              );
            });
            _w.line('}');
          default:
            _w.line("$variable = Serial.readStringUntil('\\n');");
            _w.line('$variable.trim();');
        }
        _w.line('Serial.println(${_printable(VarRef(variable, 0))});');
      case Output(:final value):
        final e = value.expr;
        if (e == null) {
          _w.line('// ${tr.codeInvalidExpr(value.text)}');
          return;
        }
        final parts = _parts(e);
        for (var i = 0; i < parts.length; i++) {
          final fn = i == parts.length - 1 ? 'println' : 'print';
          _w.line('Serial.$fn(${_printable(parts[i])});');
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
        final st = constInt(step.expr);
        final t = _src(to);
        final cond = switch (st) {
          null => '(${_src(step)} > 0 ? $variable <= $t : $variable >= $t)',
          > 0 => '$variable <= $t',
          _ => '$variable >= $t',
        };
        final inc = switch (st) {
          1 => '$variable++',
          -1 => '$variable--',
          null => '$variable += ${_src(step)}',
          > 0 => '$variable += $st',
          _ => '$variable -= ${-st}',
        };
        _braced('for ($variable = ${_src(from)}; $cond; $inc)', body);
      case Comment(:final text):
        for (final l in text.split('\n')) {
          _w.line('// $l');
        }
      case DigitalWrite(:final pin, :final value):
        _w.line('digitalWrite(${_src(pin)}, ${_src(value)});');
      case AnalogWrite(:final pin, :final value):
        _w.line('analogWrite(${_src(pin)}, ${_src(value)});');
      case Delay(:final ms):
        _w.line('delay(${_src(ms)});');
      case DigitalRead(:final variable, :final pin):
        _w.line('$variable = digitalRead(${_src(pin)});');
      case AnalogRead(:final variable, :final pin):
        _w.line('$variable = analogRead(${_src(pin)});');
    }
  }

  /// Pezzi di un'espressione di testo (`a & " " & b` → `[a, " ", b]`).
  List<Expr> _parts(Expr e) {
    final isJoin =
        e is Binary &&
        (e.op == BinaryOp.concat || (e.op == BinaryOp.add && typeOfExpr(e) == VarType.string));
    if (!isJoin) return [e];
    return [..._parts(e.left), ..._parts(e.right)];
  }

  /// Argomento per `Serial.print`: i booleani diventano le parole vero/falso della lingua.
  String _printable(Expr e) => typeOfExpr(e) == VarType.boolean
      ? '${_expr(e, 2)} ? ${quote(tr.trueWord)} : ${quote(tr.falseWord)}'
      : _expr(e, 0);

  String _src(ExprSource src) =>
      src.expr == null ? '/* ${tr.codeInvalidExpr(src.text)} */ 0' : _expr(src.expr!, 0);

  String _expr(Expr e, int minPrec) {
    final (text, prec) = _render(e);
    return prec < minPrec ? '($text)' : text;
  }

  bool _isIntLiteral(Expr e) => e is Literal && e.value is IntV;

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
        if (op == BinaryOp.concat || (op == BinaryOp.add && typeOfExpr(e) == VarType.string)) {
          return (_stringJoin(e), p);
        }
        // Dentro `||` si racchiude `&&` tra parentesi (più leggibile, niente avvisi).
        final leftMin = op == BinaryOp.or ? p + 2 : (op.isComparison ? p + 1 : p);
        var l = _expr(left, leftMin);
        final r = _expr(right, op == BinaryOp.or ? p + 2 : p + 1);
        // Tra due costanti intere il calcolo avverrebbe in `int` a 16 bit: si forza `long`.
        if ((op == BinaryOp.mul || op == BinaryOp.add || op == BinaryOp.sub) &&
            _isIntLiteral(left) &&
            _isIntLiteral(right)) {
          l = '${l}L';
        }
        final lt = typeOfExpr(left), rt = typeOfExpr(right);
        if (op.isComparison && lt == VarType.string && left is Literal) {
          l = 'String($l)';
        }
        return switch (op) {
          BinaryOp.and => ('$l && $r', p),
          BinaryOp.or => ('$l || $r', p),
          BinaryOp.div when lt == VarType.integer && rt == VarType.integer => (
            '(float) $l / $r',
            p,
          ),
          _ => ('$l ${op.symbol} $r', p),
        };
      case Call(:final name, :final args):
        if (args.isEmpty) return ('$name()', precAtom);
        final arg = args.single;
        final a = _expr(arg, 0);
        return switch (name) {
          'int' => ('(long) ($a)', precUnary),
          'len' => (arg is VarRef ? '$a.length()' : 'String($a).length()', precAtom),
          _ => ('$name($a)', precAtom),
        };
    }
  }

  /// Concatenazione come `String`: il primo pezzo diventa una `String`, gli
  /// altri si aggiungono con `+`.
  String _stringJoin(Expr e) {
    final parts = _parts(e);
    final out = <String>[];
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      final t = typeOfExpr(p);
      var s = t == VarType.boolean
          ? '(${_expr(p, 2)} ? ${quote(tr.trueWord)} : ${quote(tr.falseWord)})'
          : _expr(p, 6);
      if (i == 0 && !(t == VarType.string && p is VarRef)) s = 'String($s)';
      out.add(s);
    }
    return out.join(' + ');
  }
}
