/// Interprete passo-passo, basato su un generatore. Dart puro.
///
/// Ogni chiamata a [Interpreter.next] esegue un blocco (o una verifica di
/// condizione) e restituisce un [RunEvent]. Una richiesta di input sospende
/// l'esecuzione finché non arriva [Interpreter.provideInput].
library;

import 'dart:math' as math;

import '../expr/types.dart';
import '../i18n/tr.dart';
import '../model/expr.dart';
import '../model/program.dart';
import '../model/stmt.dart';
import 'environment.dart';
import 'evaluator.dart';
import 'runtime_errors.dart';
import 'sim_board.dart';

sealed class RunEvent {
  const RunEvent(this.blockId);

  /// Blocco appena eseguito (da evidenziare).
  final String? blockId;
}

/// Un passo eseguito. [output]: testo scritto da un blocco "Scrivi".
/// [changed]: variabile appena modificata.
final class StepEvent extends RunEvent {
  const StepEvent(super.blockId, {this.output, this.changed, this.condition, this.delayMs});
  final String? output;
  final String? changed;

  /// Esito della condizione, per i blocchi decisionali.
  final bool? condition;

  /// Attesa di un blocco `delay`, in millisecondi (Arduino).
  final int? delayMs;
}

/// Arduino: inizia il giro numero [count] di `loop()`.
final class LoopStart extends RunEvent {
  const LoopStart(this.count) : super(null);
  final int count;
}

/// Il programma aspetta un valore per [variable].
final class InputRequest extends RunEvent {
  const InputRequest(super.blockId, this.variable, this.type);
  final String variable;
  final VarType type;
}

final class Finished extends RunEvent {
  const Finished() : super(null);
}

final class Failed extends RunEvent {
  const Failed(super.blockId, this.message);
  final String message;
}

final class Interpreter {
  Interpreter(this.program, {math.Random? random, this.maxSteps = 10000, SimBoard? board})
    : _rng = random ?? math.Random(),
      board = program.arduino == null ? null : (board ?? SimBoard(program.arduino!)) {
    if (program.arduino case final cfg?) {
      // Come nello sketch generato: costanti dei pin e variabili globali con
      // il valore iniziale (0, 0.0, "", falso), che restano tra un giro e l'altro.
      env.constants.addAll({
        'HIGH': const IntV(1),
        'LOW': const IntV(0),
        for (final a in cfg.board.analogPins) a: IntV(cfg.board.pinNumber(a)!),
        for (final p in cfg.pins)
          if (cfg.board.pinNumber(p.pin) case final n?) p.name: IntV(n),
      });
      for (final s in program.allStmts) {
        if (s case Declare(:final name, :final type) when env[name] == null) {
          env.declare(name, type);
          env.write(name, switch (type) {
            VarType.integer => const IntV(0),
            VarType.real => const RealV(0),
            VarType.string => const StrV(''),
            VarType.boolean => const BoolV(false),
          });
        }
      }
    }
  }

  /// Scheda simulata (solo per i diagrammi Arduino).
  final SimBoard? board;

  /// Arduino: giri di `loop()` iniziati.
  int loops = 0;
  int _loopSteps = 0;

  final Program program;
  final int maxSteps;
  final math.Random _rng;
  final env = Environment();

  int _steps = 0;
  int get steps => _steps;
  String? _current;
  InputRequest? _waiting;
  bool _done = false;

  late final Iterator<RunEvent> _it = _run().iterator;

  bool get isDone => _done;

  /// Richiesta di input in attesa, se c'è.
  InputRequest? get waitingFor => _waiting;

  /// Esegue il passo successivo. Dopo [Finished] o [Failed] restituisce sempre
  /// l'ultimo evento senza fare nulla.
  RunEvent next() {
    if (_waiting != null) throw StateError('in attesa di input');
    if (_done) return _last!;
    _it.moveNext();
    final e = _last = _it.current;
    if (e is InputRequest) _waiting = e;
    if (e is Finished || e is Failed) _done = true;
    return e;
  }

  RunEvent? _last;

  /// Fornisce il valore richiesto dall'ultimo [InputRequest].
  void provideInput(Value value) {
    final w = _waiting;
    if (w == null) throw StateError('nessun input richiesto');
    env.write(w.variable, value);
    _waiting = null;
  }

  Iterable<RunEvent> _run() sync* {
    try {
      if (program.isArduino) {
        // setup() una volta, poi loop() per sempre, come sulla scheda
        yield* _block(program.setup);
        while (true) {
          loops++;
          _loopSteps = 0;
          yield LoopStart(loops);
          yield* _block(program.body);
        }
      }
      yield* _block(program.body);
      yield const Finished();
    } on RuntimeError catch (e) {
      yield Failed(e.blockId ?? _current, e.message);
    }
  }

  void _tick(String id) {
    _current = id;
    _steps++;
    if (program.isArduino) {
      // il limite vale per ogni giro di loop(): loop() si ripete per sempre
      if (++_loopSteps > maxSteps) throw RuntimeError(tr.runTooManyStepsLoop(maxSteps), id);
      board!.advance(_msPerStep);
    } else if (_steps > maxSteps) {
      throw RuntimeError(tr.runTooManySteps(maxSteps), id);
    }
  }

  /// Tempo simulato di un blocco: la scheda vera impiega microsecondi, ma
  /// così `millis()` avanza anche nei cicli senza `delay`.
  static const _msPerStep = 1;

  Value _eval(ExprSource src) {
    final e = src.expr;
    if (e == null) throw RuntimeError(tr.runInvalidExpr(src.text));
    return evaluate(e, env, _rng, board);
  }

  int _pinValue(ExprSource src, String what) => _int(src, what);

  bool _cond(ExprSource src) {
    final v = _eval(src);
    if (v is! BoolV) {
      throw RuntimeError(tr.runConditionValue(v.display));
    }
    return v.value;
  }

  SimBoard _hw(String id) => board ?? (throw RuntimeError(tr.runArduinoNotSimulated, id));

  int _int(ExprSource src, String what) {
    final v = _eval(src);
    if (v is! IntV) throw RuntimeError(tr.runMustBeInteger(what, v.display));
    return v.value;
  }

  Iterable<RunEvent> _block(List<Stmt> list) sync* {
    for (final s in list) {
      yield* _stmt(s);
    }
  }

  Iterable<RunEvent> _stmt(Stmt s) sync* {
    switch (s) {
      case Declare(:final id, :final name, :final type):
        _tick(id);
        // Arduino: variabile globale, già dichiarata con il valore iniziale
        if (!program.isArduino) env.declare(name, type);
        yield StepEvent(id, changed: program.isArduino ? null : name);

      case Assign(:final id, :final target, :final value):
        _tick(id);
        env.write(target, _eval(value));
        yield StepEvent(id, changed: target);

      case Input(:final id, :final variable):
        _tick(id);
        final v = env[variable];
        if (v == null) throw RuntimeError(tr.runUndeclared(variable), id);
        yield InputRequest(id, variable, v.type);

      case Output(:final id, :final value):
        _tick(id);
        yield StepEvent(id, output: _eval(value).display);

      case If(:final id, :final cond, :final then, :final otherwise):
        _tick(id);
        final c = _cond(cond);
        yield StepEvent(id, condition: c);
        yield* _block(c ? then : otherwise);

      case While(:final id, :final cond, :final body):
        while (true) {
          _tick(id);
          final c = _cond(cond);
          yield StepEvent(id, condition: c);
          if (!c) break;
          yield* _block(body);
        }

      case DoWhile(:final id, :final cond, :final body):
        while (true) {
          yield* _block(body);
          _tick(id);
          final c = _cond(cond);
          yield StepEvent(id, condition: c);
          if (!c) break;
        }

      case For(:final id, :final variable, :final from, :final to, :final step, :final body):
        _tick(id);
        final start = _int(from, tr.whatFrom);
        final end = _int(to, tr.whatTo);
        final inc = _int(step, tr.whatStep);
        if (inc == 0) throw RuntimeError(tr.runStepZero, id);
        bool inRange(int v) => inc > 0 ? v <= end : v >= end;
        var i = start;
        env.write(variable, IntV(i));
        yield StepEvent(id, changed: variable, condition: inRange(i));
        while (inRange(i)) {
          yield* _block(body);
          _tick(id);
          final cur = env.read(variable);
          if (cur is! IntV) throw RuntimeError(tr.runCounterInteger(variable), id);
          i = cur.value + inc;
          env.write(variable, IntV(i));
          yield StepEvent(id, changed: variable, condition: inRange(i));
        }

      case Comment():
        break;

      case DigitalWrite(:final id, :final pin, :final value):
        _tick(id);
        _hw(id).digitalWrite(_pinValue(pin, tr.whatPin), _int(value, tr.whatValue));
        yield StepEvent(id);

      case AnalogWrite(:final id, :final pin, :final value):
        _tick(id);
        _hw(id).analogWrite(_pinValue(pin, tr.whatPin), _int(value, tr.whatValue));
        yield StepEvent(id);

      case Delay(:final id, :final ms):
        _tick(id);
        final wait = _int(ms, tr.whatValue);
        if (wait < 0) throw RuntimeError(tr.runDelayNegative(wait), id);
        _hw(id).advance(wait);
        yield StepEvent(id, delayMs: wait);

      case DigitalRead(:final id, :final variable, :final pin):
        _tick(id);
        env.write(variable, IntV(_hw(id).digitalRead(_pinValue(pin, tr.whatPin))));
        yield StepEvent(id, changed: variable);

      case AnalogRead(:final id, :final variable, :final pin):
        _tick(id);
        env.write(variable, IntV(_hw(id).analogRead(_pinValue(pin, tr.whatPin))));
        yield StepEvent(id, changed: variable);
    }
  }
}

/// Esegue tutto il programma con input già noti. Utile per test e confronti:
/// restituisce le righe di output e l'eventuale errore.
({List<String> output, String? error}) runToEnd(
  Program p,
  List<String> inputs, {
  math.Random? random,
  int maxSteps = 10000,
}) {
  final it = Interpreter(p, random: random, maxSteps: maxSteps);
  final out = <String>[];
  var nextInput = 0;
  while (true) {
    final e = it.next();
    switch (e) {
      case StepEvent(:final output?):
        out.add(output);
      case StepEvent() || LoopStart():
        break;
      case InputRequest(:final type):
        if (nextInput >= inputs.length) return (output: out, error: tr.runInputMissing);
        final parsed = parseInput(inputs[nextInput++], type);
        if (parsed.error != null) return (output: out, error: parsed.error);
        it.provideInput(parsed.value!);
      case Finished():
        return (output: out, error: null);
      case Failed(:final message):
        return (output: out, error: message);
    }
  }
}
