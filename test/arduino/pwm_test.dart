import 'package:db_flow/arduino/board.dart';
import 'package:db_flow/arduino/pin_assign.dart';
import 'package:db_flow/arduino/pin_suggestions.dart';
import 'package:db_flow/editor/editor_state.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/ui/arduino_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ExprSource e(String s) => ExprSource(s);

Program sketch(List<PinConfig> pins, List<Stmt> body) => Program(
  name: 'S',
  kind: ProgramKind.arduino,
  arduino: ArduinoConfig(pins: pins),
  body: body,
);

void main() {
  setUp(() => setLanguage(AppLanguage.it));

  group('proposte dal diagramma', () {
    test('analogWrite per nome chiede un pin PWM', () {
      final p = sketch(const [], [
        DigitalWrite(pin: e('LUCE'), value: e('HIGH')),
        AnalogWrite(pin: e('LUCE'), value: e('100')),
        AnalogWrite(pin: e('MOTORE'), value: e('50')),
        DigitalWrite(pin: e('LED'), value: e('LOW')),
        AnalogWrite(pin: e('7'), value: e('10')),
      ]);
      final s = {for (final x in suggestPins(p)) x.name: x};
      expect(s['LUCE']!.pwm, isTrue, reason: 'prima digitalWrite, poi analogWrite');
      expect(s['MOTORE']!.pwm, isTrue);
      expect(s['LED']!.pwm, isFalse);
      expect(s['PIN_7']!.pwm, isFalse, reason: 'numero fisso: lo segnala il validatore');
    });

    test('pin letto con digitalRead: pulsante con pull-up', () {
      final p = sketch(const [], [
        Declare(name: 'v', type: VarType.integer),
        DigitalRead(variable: 'v', pin: e('TASTO')),
      ]);
      final s = suggestPins(p).single;
      expect((s.component, s.mode), (Component.button, PinMode.inputPullup));
    });

    test('pin configurati usati con analogWrite', () {
      final p = sketch(
        const [
          PinConfig(name: 'LUCE', pin: '9', mode: PinMode.output),
          PinConfig(name: 'LED', pin: '13', mode: PinMode.output),
        ],
        [
          AnalogWrite(pin: e('LUCE'), value: e('100')),
          DigitalWrite(pin: e('LED'), value: e('HIGH')),
          AnalogWrite(pin: e('13'), value: e('1')),
        ],
      );
      expect(pwmPinNames(p), {'LUCE'});
    });
  });

  group('spostamento automatico', () {
    const luce = PinConfig(name: 'LUCE', pin: '9', mode: PinMode.output, component: Component.led);
    const led = PinConfig(name: 'LED', pin: '13', mode: PinMode.output, component: Component.led);
    final cfg = ArduinoConfig(pins: const [luce, led]);

    test('un pin usato con analogWrite va solo su un altro PWM', () {
      // nuovo pin sul 9: LUCE deve spostarsi, e solo su un pin PWM
      final plan = planPin(
        cfg,
        null,
        const PinConfig(name: 'X', pin: '9', mode: PinMode.output),
        pwmNames: {'LUCE'},
      );
      expect(plan.ok, isTrue);
      expect(arduinoUno.pwmPins, contains(plan.displacedTo));
      expect(plan.displacedTo, '3');
    });

    test('lo scambio con un pin senza PWM non è ammesso', () {
      // LED dal 13 al 9: LUCE dovrebbe andare sul 13, che non ha PWM
      final plan = planPin(cfg, led, led.copyWith(pin: '9'), pwmNames: {'LUCE'});
      expect(plan.error, PinPlanError.cannotSwap);
      // senza analogWrite lo scambio va bene
      expect(planPin(cfg, led, led.copyWith(pin: '9')).ok, isTrue);
    });
  });

  testWidgets('finestra del pin: per analogWrite si scelgono solo pin PWM', (tester) async {
    tester.view.physicalSize = const Size(1600, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final state = EditorState(sketch(const [], [AnalogWrite(pin: e('MOTORE'), value: e('128'))]));
    await tester.pumpWidget(MaterialApp(home: ArduinoSetupPage(state: state)));
    await tester.tap(find.widgetWithText(FilledButton, 'Aggiungi'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(find.text(tr.pwmNeeded), findsOneWidget);
    // il 7 non ha PWM: non si può scegliere
    await tester.tap(find.descendant(of: dialog, matching: find.text('7')));
    await tester.pumpAndSettle();
    final add = find.descendant(
      of: dialog,
      matching: find.widgetWithText(FilledButton, 'Aggiungi'),
    );
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    await tester.tap(find.descendant(of: dialog, matching: find.text('~6')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
    await tester.tap(add);
    await tester.pumpAndSettle();
    final p = state.program.arduino!.pins.single;
    expect((p.name, p.pin, p.mode), ('MOTORE', '6', PinMode.output));
  });
}
