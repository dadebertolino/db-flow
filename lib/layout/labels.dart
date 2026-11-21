/// Testo mostrato dentro ogni blocco. Dart puro.
library;

import '../i18n/tr.dart';
import '../model/stmt.dart';

String _or(String s) => s.trim().isEmpty ? '?' : s.trim();

String blockLabel(Stmt s) => switch (s) {
  Declare(:final name, :final type) => '${type.label} ${_or(name)}',
  Assign(:final target, :final value) => '${_or(target)} ← ${_or(value.text)}',
  Input(:final variable) => tr.labelRead(_or(variable)),
  Output(:final value) => tr.labelWrite(_or(value.text)),
  If(:final cond) || While(:final cond) || DoWhile(:final cond) => _or(cond.text),
  For(:final variable, :final from, :final to, :final step) => tr.labelFor(
    _or(variable),
    _or(from.text),
    _or(to.text),
    step.text.trim() == '1' ? null : _or(step.text),
  ),
  Comment(:final text) => _or(text),
  DigitalWrite(:final pin, :final value) => 'digitalWrite(${_or(pin.text)}, ${_or(value.text)})',
  AnalogWrite(:final pin, :final value) => 'analogWrite(${_or(pin.text)}, ${_or(value.text)})',
  Delay(:final ms) => 'delay(${_or(ms.text)})',
  DigitalRead(:final variable, :final pin) => '${_or(variable)} ← digitalRead(${_or(pin.text)})',
  AnalogRead(:final variable, :final pin) => '${_or(variable)} ← analogRead(${_or(pin.text)})',
};
