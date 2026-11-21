import 'package:db_flow/arduino/board.dart';
import 'package:db_flow/arduino/pin_assign.dart';
import 'package:flutter_test/flutter_test.dart';

const led = PinConfig(name: 'LED', pin: '9', mode: PinMode.output, component: Component.led);
const button = PinConfig(
  name: 'PULSANTE',
  pin: '2',
  mode: PinMode.inputPullup,
  component: Component.button,
);
const pot = PinConfig(
  name: 'POT',
  pin: 'A0',
  mode: PinMode.analogInput,
  component: Component.potentiometer,
);

Map<String, String> pinsOf(PinPlan p) => {for (final c in p.pins) c.name: c.pin};

void main() {
  final cfg = ArduinoConfig(pins: const [led, button, pot]);

  test('componenti: modo proposto e pin adatti', () {
    expect(Component.button.defaultMode, PinMode.inputPullup);
    expect(Component.potentiometer.fits(arduinoUno, 'A3', PinMode.analogInput), isTrue);
    expect(Component.potentiometer.fits(arduinoUno, '7', PinMode.analogInput), isFalse);
    expect(Component.led.fits(arduinoUno, '7', PinMode.input), isFalse);
    expect(Component.other.fits(arduinoUno, 'A1', PinMode.input), isTrue);
  });

  test('pin libero: nessuno spostamento', () {
    final p = planPin(cfg, null, const PinConfig(name: 'X', pin: '7', mode: PinMode.output));
    expect(p.ok, isTrue);
    expect(p.displaced, isNull);
    expect(pinsOf(p), {'LED': '9', 'PULSANTE': '2', 'POT': 'A0', 'X': '7'});
  });

  test('modifica su un pin occupato: scambio', () {
    final p = planPin(cfg, led, led.copyWith(pin: '2'));
    expect(p.ok, isTrue);
    expect(p.swapped, isTrue);
    expect(p.displaced!.name, 'PULSANTE');
    expect(p.displacedTo, '9');
    expect(pinsOf(p), {'LED': '2', 'PULSANTE': '9', 'POT': 'A0'});
  });

  test('scambio impossibile: il potenziometro non può andare su un pin digitale', () {
    final p = planPin(cfg, led, led.copyWith(pin: 'A0'));
    expect(p.ok, isFalse);
    expect(p.error, PinPlanError.cannotSwap);
    expect(p.displaced!.name, 'POT');
    expect(pinsOf(p), {'LED': '9', 'PULSANTE': '2', 'POT': 'A0'});
  });

  test('pin nuovo su un pin occupato: l\'occupante si sposta sul primo pin adatto', () {
    final p = planPin(cfg, null, const PinConfig(name: 'BUZZER', pin: '9', mode: PinMode.output));
    expect(p.ok, isTrue);
    expect(p.swapped, isFalse);
    expect(p.displaced!.name, 'LED');
    // il LED era su un pin PWM: va sul primo PWM libero
    expect(p.displacedTo, '3');
    expect(pinsOf(p)['BUZZER'], '9');
  });

  test('il potenziometro spostato resta su un pin analogico', () {
    final p = planPin(
      cfg,
      null,
      const PinConfig(name: 'LUCE', pin: 'A0', mode: PinMode.analogInput),
    );
    expect(p.displacedTo, 'A1');
  });

  test('nessun pin analogico libero: spostamento impossibile', () {
    final full = ArduinoConfig(
      pins: [
        for (final a in arduinoUno.analogPins)
          PinConfig(
            name: 'P$a',
            pin: a,
            mode: PinMode.analogInput,
            component: Component.potentiometer,
          ),
      ],
    );
    final p = planPin(full, null, const PinConfig(name: 'X', pin: 'A2', mode: PinMode.input));
    expect(p.error, PinPlanError.cannotMove);
  });

  test('i pin della seriale non vengono proposti negli spostamenti', () {
    expect(freePinFor(arduinoUno, button, {'2'}), '3');
  });
}
