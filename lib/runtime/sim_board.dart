/// Scheda Arduino simulata: livelli dei pin, uscite PWM, pulsanti,
/// potenziometri e tempo. Dart puro.
///
/// I pin si indicano con il nome del pin fisico (`"13"`, `"A0"`; sulla Micro
/// A6 è il pin `"4"`), come in [Board.physical].
library;

import '../arduino/board.dart';
import '../i18n/tr.dart';
import 'evaluator.dart';
import 'runtime_errors.dart';

/// Stato di un'uscita: livello digitale oppure valore PWM (0–255).
final class PinOutput {
  const PinOutput.digital(bool high) : level = high ? 255 : 0, pwm = false;
  const PinOutput.pwm(this.level) : pwm = true;

  /// 0–255: 0 = LOW, 255 = HIGH; i valori intermedi solo con il PWM.
  final int level;
  final bool pwm;

  bool get high => level > 0;
}

final class SimBoard implements Hardware {
  SimBoard(this.config) {
    for (final p in config.pins) {
      final pin = board.physical(p.pin);
      switch (p.mode) {
        case PinMode.analogInput:
          _analog[pin] = p.component == Component.potentiometer ? 512 : 0;
        case PinMode.input || PinMode.inputPullup || PinMode.output:
          break;
      }
    }
  }

  final ArduinoConfig config;
  Board get board => config.board;

  int _millis = 0;
  final _outputs = <String, PinOutput>{};
  final _pressed = <String>{};
  final _highInputs = <String>{};
  final _analog = <String, int>{};

  /// Ultima modifica (contatore): l'interfaccia la usa per ridisegnarsi.
  int version = 0;

  // ------------------------------------------------------------ lettura dello stato

  /// Uscita del pin, `null` se non è mai stato scritto (LOW).
  PinOutput? output(String pin) => _outputs[board.physical(pin)];

  bool isPressed(String pin) => _pressed.contains(board.physical(pin));
  bool isHighInput(String pin) => _highInputs.contains(board.physical(pin));
  int analogValue(String pin) => _analog[board.physical(pin)] ?? 0;

  // ------------------------------------------------------------ comandi dell'utente

  /// Preme o rilascia il pulsante collegato a [pin].
  void setPressed(String pin, bool pressed) {
    final p = board.physical(pin);
    pressed ? _pressed.add(p) : _pressed.remove(p);
    version++;
  }

  /// Livello di un ingresso digitale generico (non pulsante).
  void setHighInput(String pin, bool high) {
    final p = board.physical(pin);
    high ? _highInputs.add(p) : _highInputs.remove(p);
    version++;
  }

  /// Valore letto da `analogRead` (0–1023).
  void setAnalog(String pin, int value) {
    _analog[board.physical(pin)] = value.clamp(0, board.analogMax);
    version++;
  }

  /// Scheda per una nuova esecuzione: uscite spente e tempo a zero, ma
  /// pulsanti, potenziometri e ingressi restano come li ha messi l'utente.
  SimBoard restarted() => SimBoard(config)
    .._pressed.addAll(_pressed)
    .._highInputs.addAll(_highInputs)
    .._analog.addAll(_analog);

  // ------------------------------------------------------------ programma

  /// Pin fisico dal numero usato nel programma, oppure errore.
  String pinOf(int n) {
    final name = board.pinName(n);
    if (name == null) throw RuntimeError(tr.runPinNotOnBoard(n, board.name));
    return board.physical(name);
  }

  PinConfig? _config(String physical) =>
      config.pins.where((p) => board.physical(p.pin) == physical).firstOrNull;

  void digitalWrite(int pinNumber, int value) {
    _outputs[pinOf(pinNumber)] = PinOutput.digital(value != 0);
    version++;
  }

  void analogWrite(int pinNumber, int value) {
    if (value < 0 || value > board.pwmMax) {
      throw RuntimeError(tr.runPwmRange(value, board.pwmMax));
    }
    final pin = pinOf(pinNumber);
    // senza PWM l'Arduino vero scrive LOW sotto metà e HIGH sopra
    _outputs[pin] = board.pwmPins.contains(pin)
        ? PinOutput.pwm(value)
        : PinOutput.digital(value >= (board.pwmMax + 1) ~/ 2);
    version++;
  }

  /// Avanza l'orologio simulato.
  void advance(int ms) {
    _millis += ms;
    version++;
  }

  @override
  int millis() => _millis;

  @override
  int digitalRead(int pinNumber) {
    final pin = pinOf(pinNumber);
    final conf = _config(pin);
    switch (conf?.mode) {
      case PinMode.output:
        return (_outputs[pin]?.high ?? false) ? 1 : 0;
      case PinMode.inputPullup:
        // pulsante verso GND: a riposo HIGH, premuto LOW
        return conf!.component == Component.button
            ? (_pressed.contains(pin) ? 0 : 1)
            : (_highInputs.contains(pin) ? 1 : 0);
      case PinMode.input:
        return conf!.component == Component.button
            ? (_pressed.contains(pin) ? 1 : 0)
            : (_highInputs.contains(pin) ? 1 : 0);
      case PinMode.analogInput:
        return (_analog[pin] ?? 0) >= (board.analogMax + 1) ~/ 2 ? 1 : 0;
      case null:
        return 0;
    }
  }

  @override
  int analogRead(int pinNumber) {
    final pin = pinOf(pinNumber);
    if (!board.isAnalog(board.pinName(pinNumber)!)) {
      throw RuntimeError(tr.runAnalogReadPin(board.pinName(pinNumber)!));
    }
    return _analog[pin] ?? 0;
  }
}
