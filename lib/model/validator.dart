/// Validazione statica di un programma: produce i problemi da mostrare sui
/// blocchi (bordo rosso + messaggio). Dart puro.
///
/// Le variabili sono globali e vanno dichiarate prima dell'uso, nell'ordine in
/// cui i blocchi compaiono nel diagramma (dall'alto in basso; in un diagramma
/// Arduino prima `setup`, poi `loop`).
library;

import '../arduino/board.dart';
import '../expr/errors.dart';
import '../expr/functions.dart';
import '../expr/lexer.dart';
import '../expr/type_checker.dart';
import '../expr/types.dart';
import '../i18n/tr.dart';
import 'expr.dart';
import 'program.dart';
import 'stmt.dart';

/// Id usato per i problemi della configurazione dei pin (non di un blocco).
const arduinoConfigId = '#arduino';

final class Issue {
  const Issue(this.blockId, this.field, this.message, {this.pos, this.length = 1});

  /// Blocco coinvolto, oppure [arduinoConfigId] per la configurazione dei pin.
  final String blockId;

  /// Campo del blocco coinvolto (`name`, `target`, `var`, `value`, `cond`,
  /// `from`, `to`, `step`, `pin`, `ms`), per evidenziarlo nel dialog di modifica.
  final String field;

  /// Messaggio in italiano.
  final String message;

  /// Posizione nel testo dell'espressione, se l'errore è dentro un'espressione.
  final int? pos;
  final int length;

  @override
  String toString() => '[$blockId.$field] $message${pos == null ? '' : ' (colonna ${pos! + 1})'}';
}

List<Issue> validate(Program program) {
  final v = _Validator(program);
  if (program.isArduino) v.config();
  v.block(program.setup);
  v.block(program.body);
  return v.issues;
}

/// Problemi raggruppati per id di blocco.
Map<String, List<Issue>> issuesByBlock(List<Issue> issues) {
  final map = <String, List<Issue>>{};
  for (final i in issues) {
    (map[i.blockId] ??= []).add(i);
  }
  return map;
}

/// Costanti visibili nelle espressioni di un diagramma Arduino: `HIGH`, `LOW`,
/// `A0`… e i nomi dei pin configurati (tutte intere).
Map<String, VarType> arduinoConstantTypes(ArduinoConfig cfg) => {
  for (final c in arduinoConstants.keys) c: VarType.integer,
  for (final a in cfg.board.analogPins) a: VarType.integer,
  for (final p in cfg.pins)
    if (p.name.isNotEmpty) p.name: VarType.integer,
};

/// Uso di un pin, per i controlli sul modo configurato.
enum _PinUse { digitalWrite, analogWrite, digitalRead, analogRead }

final class _Validator {
  _Validator(this.program) {
    if (program.arduino case final cfg?) {
      constants.addAll(arduinoConstantTypes(cfg));
      vars.addAll(constants);
    }
  }

  final Program program;
  final issues = <Issue>[];
  final vars = <String, VarType>{};
  final constants = <String, VarType>{};

  ArduinoConfig? get cfg => program.arduino;

  void block(List<Stmt> stmts) {
    for (final s in stmts) {
      stmt(s);
    }
  }

  void add(Stmt s, String field, String message) => issues.add(Issue(s.id, field, message));

  /// Tipo dell'espressione, oppure `null` se contiene errori (già registrati).
  VarType? expr(Stmt s, String field, ExprSource src) {
    final syntaxError = src.error;
    if (syntaxError != null) {
      _exprIssue(s, field, syntaxError);
      return null;
    }
    // Nei diagrammi Arduino controlla prima i pin letti da digitalRead/analogRead:
    // un pin non configurato ha un messaggio più chiaro di "variabile non dichiarata".
    final unknownPins = cfg == null ? const <String>{} : _scanReads(s, field, src.expr!);
    try {
      return typeOf(
        src.expr!,
        unknownPins.isEmpty ? vars : {...vars, for (final p in unknownPins) p: VarType.integer},
        arduino: program.isArduino,
      );
    } on ExprError catch (e) {
      _exprIssue(s, field, e);
      return null;
    }
  }

  void _exprIssue(Stmt s, String field, ExprError e) =>
      issues.add(Issue(s.id, field, e.message, pos: e.pos, length: e.length));

  /// Verifica che [name] sia una variabile dichiarata; ne restituisce il tipo.
  VarType? variable(Stmt s, String field, String name, {bool write = true}) {
    if (name.isEmpty) {
      add(s, field, tr.valChooseVariable);
      return null;
    }
    if (write && constants.containsKey(name)) {
      add(s, field, tr.valConstant(name));
      return null;
    }
    final t = vars[name];
    if (t == null) add(s, field, tr.valUndeclared(name));
    return t;
  }

  void condition(Stmt s, ExprSource cond) {
    final t = expr(s, 'cond', cond);
    if (t != null && t != VarType.boolean) {
      add(s, 'cond', tr.valConditionBoolean(t));
    }
  }

  void stmt(Stmt s) {
    switch (s) {
      case Declare(:final name, :final type):
        final err = checkIdentifier(name);
        if (err != null) {
          add(s, 'name', err);
        } else if (constants.containsKey(name)) {
          add(s, 'name', tr.valNameIsPin(name));
        } else if (vars.containsKey(name)) {
          add(s, 'name', tr.valAlreadyDeclared(name));
        } else {
          vars[name] = type;
        }

      case Assign(:final target, :final value):
        final tt = variable(s, 'target', target);
        final vt = expr(s, 'value', value);
        if (tt != null && vt != null && !isAssignable(tt, vt)) {
          add(s, 'value', _assignMessage(target, tt, vt));
        }

      case Input(:final variable):
        this.variable(s, 'var', variable);

      case Output(:final value):
        expr(s, 'value', value);

      case If(:final cond, :final then, :final otherwise):
        condition(s, cond);
        block(then);
        block(otherwise);

      case While(:final cond, :final body):
        condition(s, cond);
        block(body);

      case DoWhile(:final body, :final cond):
        block(body);
        condition(s, cond);

      case For(:final variable, :final from, :final to, :final step, :final body):
        final t = this.variable(s, 'var', variable);
        if (t != null && t != VarType.integer) {
          add(s, 'var', tr.valCounterInteger(variable));
        }
        for (final (field, src, what) in [
          ('from', from, tr.whatFrom),
          ('to', to, tr.whatTo),
          ('step', step, tr.whatStep),
        ]) {
          final et = expr(s, field, src);
          if (et != null && et != VarType.integer) {
            add(s, field, tr.valMustBeInteger(what, et));
          }
        }
        if (_isZero(step.expr)) add(s, 'step', tr.valStepZero);
        block(body);

      case Comment():
        break;

      case DigitalWrite(:final pin, :final value):
        if (!_arduinoOnly(s)) return;
        _pinField(s, pin, _PinUse.digitalWrite);
        final vt = expr(s, 'value', value);
        if (vt != null && vt != VarType.integer && vt != VarType.boolean) {
          add(s, 'value', tr.valHighLow(vt));
        }

      case AnalogWrite(:final pin, :final value):
        if (!_arduinoOnly(s)) return;
        _pinField(s, pin, _PinUse.analogWrite);
        final vt = expr(s, 'value', value);
        if (vt != null && vt != VarType.integer) {
          add(s, 'value', tr.valPwmInteger(vt));
        }
        final max = cfg!.board.pwmMax;
        if (constInt(value.expr) case final v? when v < 0 || v > max) {
          add(s, 'value', tr.valPwmRange(max, v));
        }

      case DigitalRead(:final variable, :final pin) || AnalogRead(:final variable, :final pin):
        if (!_arduinoOnly(s)) return;
        final t = this.variable(s, 'var', variable);
        if (t != null && t != VarType.integer) {
          add(s, 'var', tr.valReadIntoInteger(variable));
        }
        _pinField(s, pin, s is DigitalRead ? _PinUse.digitalRead : _PinUse.analogRead);

      case Delay(:final ms):
        if (!_arduinoOnly(s)) return;
        final t = expr(s, 'ms', ms);
        if (t != null && t != VarType.integer) {
          add(s, 'ms', tr.valDelayInteger(t));
        }
        if (constInt(ms.expr) case final v? when v < 0) {
          add(s, 'ms', tr.valDelayNegative);
        }
    }
  }

  bool _arduinoOnly(Stmt s) {
    if (program.isArduino) return true;
    add(s, 'pin', tr.valArduinoOnlyBlock);
    return false;
  }

  // ------------------------------------------------------------ pin

  /// Controlla il campo `pin` di un blocco di scrittura.
  void _pinField(Stmt s, ExprSource pin, _PinUse use) {
    final e = pin.expr;
    if (pin.text.trim().isEmpty) {
      add(s, 'pin', tr.valChoosePin);
      return;
    }
    if (e is VarRef && !vars.containsKey(e.name)) {
      add(s, 'pin', _notConfigured(e.name));
      return;
    }
    final t = expr(s, 'pin', pin);
    if (t != null && t != VarType.integer) {
      add(s, 'pin', tr.valPinMustBeInt(t));
      return;
    }
    if (e != null) _checkPin(s, 'pin', e, use);
  }

  /// Pin letti nelle chiamate digitalRead/analogRead di [e]; restituisce i nomi
  /// sconosciuti (già segnalati).
  Set<String> _scanReads(Stmt s, String field, Expr e) {
    final unknown = <String>{};
    void visit(Expr x) {
      switch (x) {
        case Call(:final name, :final args) when name == 'digitalRead' || name == 'analogRead':
          final arg = args.isEmpty ? null : args.first;
          if (arg is VarRef && !vars.containsKey(arg.name)) {
            unknown.add(arg.name);
            issues.add(
              Issue(s.id, field, _notConfigured(arg.name), pos: arg.pos, length: arg.name.length),
            );
          } else if (arg != null) {
            _checkPin(
              s,
              field,
              arg,
              name == 'digitalRead' ? _PinUse.digitalRead : _PinUse.analogRead,
            );
          }
          args.forEach(visit);
        case Call(:final args):
          args.forEach(visit);
        case Unary(:final operand):
          visit(operand);
        case Binary(:final left, :final right):
          visit(left);
          visit(right);
        case Literal() || VarRef():
          break;
      }
    }

    visit(e);
    return unknown;
  }

  static String _notConfigured(String name) => tr.valPinNotConfigured(name);

  /// Controlla un pin noto (nome configurato, A0…, o numero) rispetto all'uso.
  void _checkPin(Stmt s, String field, Expr e, _PinUse use) {
    final cfg = this.cfg!;
    final board = cfg.board;
    PinConfig? conf;
    String? pin;
    String label;
    switch (e) {
      case VarRef(:final name) when cfg.pinNamed(name) != null:
        conf = cfg.pinNamed(name);
        pin = conf!.pin;
        label = tr.valPinNamed(name, conf.pin);
      case VarRef(:final name) when board.analogPins.contains(name):
        pin = name;
        label = tr.valPinNumber(name);
      case _ when constInt(e) != null:
        final n = constInt(e)!;
        pin = board.pinName(n);
        if (pin == null) {
          add(s, field, tr.valPinNotOnBoard('$n', board.name));
          return;
        }
        label = tr.valPinNumber(pin);
      default:
        return; // pin calcolato o in una variabile: non verificabile prima dell'esecuzione
    }
    conf ??= cfg.pins.where((p) => board.samePin(p.pin, pin!)).firstOrNull;
    if (conf == null) {
      add(s, field, tr.valPinNotConfiguredLabel(label));
      return;
    }
    if (board.isAnalogOnly(pin) && use != _PinUse.analogRead) {
      final digital = board.analogAliases[pin];
      add(s, field, digital == null ? tr.valAnalogOnly(label) : tr.valAnalogAlias(label, digital));
      return;
    }
    final mode = conf.mode;
    switch (use) {
      case _PinUse.digitalWrite || _PinUse.analogWrite:
        if (mode != PinMode.output) {
          add(s, field, tr.valPinNotOutput(label, mode.label));
          return;
        }
        if (use == _PinUse.analogWrite && !board.pwmPins.contains(pin)) {
          final pwm = board.pwmPins.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          add(s, field, tr.valNoPwm(label, board.name, pwm.join(', ')));
        }
      case _PinUse.digitalRead:
        if (mode == PinMode.output) {
          add(s, field, tr.valPinIsOutput(label));
        }
      case _PinUse.analogRead:
        if (!board.isAnalog(pin)) {
          add(s, field, tr.valAnalogReadPins(board.analogPins.join(', ')));
        } else if (mode != PinMode.analogInput) {
          add(s, field, tr.valAnalogReadMode(label));
        }
    }
  }

  // ------------------------------------------------------------ configurazione

  void config() {
    final cfg = this.cfg!;
    final board = cfg.board;
    void issue(String m) => issues.add(Issue(arduinoConfigId, 'pins', m));
    final names = <String>{}, used = <String>{};
    for (final p in cfg.pins) {
      final err = checkIdentifier(p.name);
      if (err != null) {
        issue(tr.valPinNameError(p.name, err));
      } else if (!names.add(p.name)) {
        issue(tr.valPinNameTwice(p.name));
      }
      if (!board.isValidPin(p.pin)) {
        issue(tr.valPinNotExists(p.name, p.pin, board.name));
      } else if (!used.add(board.physical(p.pin))) {
        final alias = board.analogAliases.containsKey(p.pin);
        issue(tr.valPinTwice(alias ? '${p.pin} (= ${board.physical(p.pin)})' : p.pin));
      } else if (!board.modesFor(p.pin).contains(p.mode)) {
        issue(tr.valPinModeInvalid(p.name, p.pin, p.mode.label));
      }
    }
    final usesSerial = program.allStmts.any((s) => s is Input || s is Output);
    if (usesSerial) {
      for (final p in cfg.pins.where((p) => board.serialPins.contains(p.pin))) {
        issue(tr.valSerialPins(p.name, board.serialPins.toList()));
      }
    }
  }

  static bool _isZero(Expr? e) => switch (e) {
    Literal(value: IntV(value: 0)) => true,
    Unary(op: UnaryOp.neg, :final operand) => _isZero(operand),
    _ => false,
  };

  static String _assignMessage(String target, VarType tt, VarType vt) {
    if (tt == VarType.integer && vt == VarType.real) {
      return tr.valAssignRealToInt(target);
    }
    return tr.valAssignType(vt, target, tt);
  }
}
