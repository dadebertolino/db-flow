import 'dart:io';

import 'package:db_flow/arduino/board.dart';
import 'package:db_flow/expr/types.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/model/validator.dart';
import 'package:db_flow/runtime/interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

ExprSource e(String s) => ExprSource(s);

Program example(String name) =>
    decodeProgram(File('assets/examples/$name.flow').readAsStringSync());

Program sketch(
  List<PinConfig> pins,
  List<Stmt> body, {
  List<Stmt> setup = const [],
  String board = 'uno',
}) => Program(
  name: 'S',
  kind: ProgramKind.arduino,
  arduino: ArduinoConfig(boardId: board, pins: pins),
  setup: setup,
  body: body,
);

/// Esegue fino all'inizio del giro [loops] + 1 di loop() (o a un errore).
List<RunEvent> runLoops(Interpreter it, int loops) {
  final events = <RunEvent>[];
  while (true) {
    final ev = it.next();
    events.add(ev);
    if (ev is Failed || ev is InputRequest) return events;
    if (ev is LoopStart && ev.count > loops) return events;
  }
}

void main() {
  setUp(() => setLanguage(AppLanguage.it));

  test('Blink: il LED si accende e si spegne, i delay fanno passare il tempo', () {
    final p = example('blink');
    expect(validate(p), isEmpty);
    final it = Interpreter(p);
    expect(it.next(), isA<LoopStart>());
    it.next(); // digitalWrite(LED, HIGH)
    expect(it.board!.output('13')!.high, isTrue);
    final delay = it.next() as StepEvent;
    expect(delay.delayMs, 500);
    expect(it.board!.millis(), greaterThanOrEqualTo(500));
    it.next(); // digitalWrite(LED, LOW)
    expect(it.board!.output('13')!.high, isFalse);
    runLoops(it, 3);
    expect(it.loops, 4);
    expect(it.board!.millis(), inInclusiveRange(3000, 3100));
  });

  test('pulsante con pull-up: premuto = LOW', () {
    final p = example('pulsante');
    final it = Interpreter(p);
    runLoops(it, 1);
    expect(it.env.read('stato').display, '1', reason: 'a riposo HIGH');
    expect(it.board!.output('13')!.high, isFalse);
    it.board!.setPressed('2', true);
    runLoops(it, 2);
    expect(it.env.read('stato').display, '0');
    expect(it.board!.output('13')!.high, isTrue);
  });

  test('potenziometro e PWM', () {
    final p = example('dimmer');
    final it = Interpreter(p);
    it.board!.setAnalog('A0', 1000);
    final events = runLoops(it, 1);
    expect(it.board!.output('9'), isNotNull);
    expect(it.board!.output('9')!.pwm, isTrue);
    expect(it.board!.output('9')!.level, 250);
    final out = events.whereType<StepEvent>().map((e) => e.output).nonNulls;
    expect(out.single, 'Potenziometro: 1000  LED: 250');
  });

  test('le variabili sono globali: mantengono il valore tra i giri', () {
    final p = sketch(const [], [
      Declare(name: 'n', type: VarType.integer),
      Assign(target: 'n', value: e('n + 1')),
    ]);
    final it = Interpreter(p);
    runLoops(it, 3);
    expect(it.env.read('n').display, '3');
    expect(it.env.all.map((v) => v.name), ['n'], reason: 'HIGH, LOW, A0… sono costanti');
  });

  test('costanti: nomi dei pin, A0, HIGH e LOW; millis avanza', () {
    final p = sketch(
      const [PinConfig(name: 'LED', pin: '7', mode: PinMode.output)],
      [
        Declare(name: 'x', type: VarType.integer),
        Assign(target: 'x', value: e('LED + A1 + HIGH')),
        Delay(ms: e('250')),
        Declare(name: 't', type: VarType.integer),
        Assign(target: 't', value: e('millis()')),
      ],
    );
    final it = Interpreter(p);
    runLoops(it, 1);
    expect(it.env.read('x').display, '23'); // 7 + 15 + 1
    expect((it.env.read('t') as IntV).value, greaterThanOrEqualTo(250));
  });

  test('setup() una volta, poi loop()', () {
    final p = sketch(
      const [],
      [Declare(name: 'b', type: VarType.integer), Assign(target: 'b', value: e('b + 1'))],
      setup: [
        Declare(name: 'a', type: VarType.integer),
        Assign(target: 'a', value: e('a + 1')),
      ],
    );
    final it = Interpreter(p);
    runLoops(it, 4);
    expect((it.env.read('a').display, it.env.read('b').display), ('1', '4'));
  });

  test('ciclo infinito dentro loop(): errore dopo 10000 passi nello stesso giro', () {
    final p = sketch(const [], [While(cond: e('HIGH == 1'))]);
    final ev = runLoops(Interpreter(p), 1).last;
    expect(ev, isA<Failed>());
    expect((ev as Failed).message, contains('un solo giro di loop()'));
  });

  test('loop() senza fine non è un errore', () {
    final p = sketch(const [], [Delay(ms: e('1'))]);
    final it = Interpreter(p, maxSteps: 50);
    final events = runLoops(it, 200);
    expect(events.whereType<Failed>(), isEmpty);
    expect(it.loops, 201);
  });

  test('errori: valore PWM fuori campo, pin inesistente, delay negativo', () {
    String fail(List<Stmt> body) {
      final p = sketch(
        const [PinConfig(name: 'L', pin: '9', mode: PinMode.output)],
        [Declare(name: 'v', type: VarType.integer), ...body],
      );
      return (runLoops(Interpreter(p), 1).last as Failed).message;
    }

    expect(
      fail([Assign(target: 'v', value: e('300')), AnalogWrite(pin: e('L'), value: e('v'))]),
      'analogWrite accetta valori da 0 a 255, invece vale 300',
    );
    expect(
      fail([Assign(target: 'v', value: e('99')), DigitalWrite(pin: e('v'), value: e('HIGH'))]),
      'il pin 99 non esiste sulla scheda Arduino Uno',
    );
    expect(
      fail([Assign(target: 'v', value: e('-5')), Delay(ms: e('v'))]),
      'delay non può essere negativo, invece vale -5',
    );
  });

  test('Micro: analogRead(A6) legge il pin 4', () {
    final p = sketch(
      const [
        PinConfig(
          name: 'POT',
          pin: 'A6',
          mode: PinMode.analogInput,
          component: Component.potentiometer,
        ),
      ],
      [Declare(name: 'v', type: VarType.integer), AnalogRead(variable: 'v', pin: e('POT'))],
      board: 'micro',
    );
    final it = Interpreter(p);
    it.board!.setAnalog('4', 321);
    runLoops(it, 1);
    expect(it.env.read('v').display, '321');
  });
}
