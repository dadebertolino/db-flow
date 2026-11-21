/// Proposte di configurazione dei pin, dedotte dall'uso nel diagramma. Dart puro.
library;

import '../layout/labels.dart' as labels;
import '../model/expr.dart';
import '../model/program.dart';
import '../model/stmt.dart';
import 'board.dart';

/// Pin usato nel diagramma ma non ancora configurato.
final class PinSuggestion {
  const PinSuggestion({
    required this.name,
    required this.mode,
    required this.reason,
    this.pin,
    this.component = Component.other,
    this.pwm = false,
  });

  /// Nome proposto (quello usato nel diagramma, oppure `PIN_13` per un numero).
  final String name;

  /// Pin, se è noto (scritto come numero o come A0…).
  final String? pin;

  final PinMode mode;

  /// Usato con `analogWrite`: serve un pin PWM.
  final bool pwm;

  /// Componente dedotto dall'uso: scritto → LED, letto digitale → pulsante,
  /// letto analogico → potenziometro.
  final Component component;

  /// Dove è stato trovato, es. `digitalWrite(LED, HIGH)`.
  final String reason;
}

List<PinSuggestion> suggestPins(Program program) {
  final cfg = program.arduino;
  if (cfg == null) return const [];
  final board = cfg.board;
  final out = <String, PinSuggestion>{};
  final declared = {
    for (final s in program.allStmts)
      if (s case Declare(:final name)) name,
  };

  void consider(Expr? e, PinMode mode, String reason, {bool pwm = false}) {
    void put(String key, PinSuggestion Function() make) {
      final old = out[key];
      if (old == null) {
        out[key] = make();
      } else if (pwm && !old.pwm && old.mode == mode && old.pin == null) {
        // prima digitalWrite, poi anche analogWrite: serve comunque il PWM
        out[key] = PinSuggestion(
          name: old.name,
          pin: old.pin,
          mode: old.mode,
          reason: old.reason,
          component: old.component,
          pwm: true,
        );
      }
    }

    switch (e) {
      case VarRef(:final name)
          when cfg.pinNamed(name) == null &&
              !declared.contains(name) &&
              !board.analogPins.contains(name):
        put(
          name,
          () => PinSuggestion(
            name: name,
            mode: mode,
            reason: reason,
            component: _componentFor(mode),
            pwm: pwm,
          ),
        );
      case VarRef(:final name) when board.analogPins.contains(name):
        // A6/A7 di Nano e Pro Mini: solo analogRead (l'errore lo segnala il validatore)
        if (!cfg.pins.any((p) => board.samePin(p.pin, name)) &&
            board.modesFor(name).contains(mode)) {
          put(
            'PIN_$name',
            () => PinSuggestion(
              name: 'PIN_$name',
              pin: name,
              mode: mode,
              reason: reason,
              component: _componentFor(mode),
              // pin fisso nel diagramma: se non è PWM lo segnala il validatore
            ),
          );
        }
      case _ when constInt(e) != null:
        final pin = board.pinName(constInt(e)!);
        if (pin != null &&
            !cfg.pins.any((p) => board.samePin(p.pin, pin)) &&
            board.modesFor(pin).contains(mode)) {
          put(
            'PIN_$pin',
            () => PinSuggestion(
              name: 'PIN_$pin',
              pin: pin,
              mode: mode,
              reason: reason,
              component: _componentFor(mode),
              // pin fisso nel diagramma: se non è PWM lo segnala il validatore
            ),
          );
        }
      default:
        break;
    }
  }

  void scan(Expr? e, String reason) {
    switch (e) {
      case Call(name: 'digitalRead', :final args) when args.length == 1:
        consider(args.single, Component.button.defaultMode, reason);
      case Call(name: 'analogRead', :final args) when args.length == 1:
        consider(args.single, PinMode.analogInput, reason);
      case Call(:final args):
        for (var a in args) {
          scan(a, reason);
        }
      case Unary(:final operand):
        scan(operand, reason);
      case Binary(:final left, :final right):
        scan(left, reason);
        scan(right, reason);
      default:
        break;
    }
  }

  for (final s in program.allStmts) {
    final reason = switch (s) {
      DigitalWrite(:final pin, :final value) => 'digitalWrite(${pin.text}, ${value.text})',
      AnalogWrite(:final pin, :final value) => 'analogWrite(${pin.text}, ${value.text})',
      _ => null,
    };
    switch (s) {
      case DigitalWrite(:final pin):
        consider(pin.expr, PinMode.output, reason!);
      case AnalogWrite(:final pin):
        consider(pin.expr, PinMode.output, reason!, pwm: true);
      case DigitalRead(:final pin):
        // il pulsante si collega di solito verso GND con il pull-up interno
        consider(pin.expr, Component.button.defaultMode, labels.blockLabel(s));
      case AnalogRead(:final pin):
        consider(pin.expr, PinMode.analogInput, labels.blockLabel(s));
      default:
        break;
    }
    for (final src in _exprs(s)) {
      scan(src.expr, src.text);
    }
  }
  return out.values.toList();
}

/// Nomi dei pin configurati usati per nome con `analogWrite`: devono stare su
/// un pin PWM. (Un numero scritto nel diagramma non si sposta: se non è PWM lo
/// segnala il validatore.)
Set<String> pwmPinNames(Program program) {
  final cfg = program.arduino;
  if (cfg == null) return const {};
  return {
    for (final s in program.allStmts)
      if (s case AnalogWrite(pin: ExprSource(expr: VarRef(:final name)))
          when cfg.pinNamed(name) != null)
        name,
  };
}

List<ExprSource> _exprs(Stmt s) => switch (s) {
  Assign(:final value) || Output(:final value) => [value],
  If(:final cond) || While(:final cond) || DoWhile(:final cond) => [cond],
  For(:final from, :final to, :final step) => [from, to, step],
  DigitalWrite(:final value) || AnalogWrite(:final value) => [value],
  Delay(:final ms) => [ms],
  DigitalRead() || AnalogRead() || Declare() || Input() || Comment() => const [],
};

Component _componentFor(PinMode mode) => switch (mode) {
  PinMode.output => Component.led,
  PinMode.input || PinMode.inputPullup => Component.button,
  PinMode.analogInput => Component.potentiometer,
};
