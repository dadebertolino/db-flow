import 'dart:convert';
import 'dart:io';

import 'package:db_flow/arduino/board.dart';
import 'package:db_flow/arduino/pin_suggestions.dart';
import 'package:db_flow/codegen/generator.dart';
import 'package:db_flow/editor/commands.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/slot.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/model/validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Per rigenerare gli snapshot: `UPDATE_GOLDENS=1 flutter test test/arduino`
final update = Platform.environment['UPDATE_GOLDENS'] == '1';

const arduinoExamples = ['blink', 'pulsante', 'dimmer'];

Program example(String name) =>
    decodeProgram(File('assets/examples/$name.flow').readAsStringSync());

/// arduino-cli: variabile ARDUINO_CLI, quello nel PATH o quello dell'Arduino IDE (macOS).
String? findArduinoCli() {
  final env = Platform.environment['ARDUINO_CLI'];
  if (env != null && File(env).existsSync()) return env;
  final which = Process.runSync('which', ['arduino-cli']);
  if (which.exitCode == 0) return '${which.stdout}'.trim();
  const ide =
      '/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli';
  return File(ide).existsSync() ? ide : null;
}

final cli = findArduinoCli();

ExprSource e(String s) => ExprSource(s);

Program sketch(List<PinConfig> pins, List<Stmt> body, {List<Stmt> setup = const []}) => Program(
  name: 'prova',
  kind: ProgramKind.arduino,
  arduino: ArduinoConfig(pins: pins),
  setup: setup,
  body: body,
);

const led = PinConfig(name: 'LED', pin: '13', mode: PinMode.output);
const pwmLed = PinConfig(name: 'LUCE', pin: '9', mode: PinMode.output);
const button = PinConfig(name: 'PULSANTE', pin: '2', mode: PinMode.inputPullup);
const pot = PinConfig(name: 'POT', pin: 'A0', mode: PinMode.analogInput);

List<String> messages(Program p) => validate(p).map((i) => i.message).toList();

/// Compila lo sketch per la scheda indicata; restituisce l'output degli errori.
Future<ProcessResult> compile(Directory tmp, String name, String code, Board board) async {
  final dir = Directory('${tmp.path}/$name')..createSync(recursive: true);
  File('${dir.path}/$name.ino').writeAsStringSync(code);
  return Process.run(cli!, ['compile', '--fqbn', board.fqbn, '--warnings', 'all', dir.path]);
}

/// Sketch che usa tutte le funzionalità, per verificare che compili.
Program everything() => sketch(
  [led, pwmLed, button, pot],
  setup: [
    Declare(name: 'n', type: VarType.integer),
    Declare(name: 'x', type: VarType.real),
    Declare(name: 's', type: VarType.string),
    Declare(name: 'ok', type: VarType.boolean),
    Declare(name: 'i', type: VarType.integer),
    Assign(target: 's', value: e('"ciao"')),
  ],
  [
    Input(variable: 'n'),
    Input(variable: 'x'),
    Input(variable: 's'),
    Input(variable: 'ok'),
    Assign(target: 'n', value: e('1000 * 60 + millis()')),
    Assign(target: 'x', value: e('n / 3 + sqrt(2)')),
    Assign(target: 's', value: e('s & " n=" & n & " ok=" & ok')),
    Assign(target: 'n', value: e('len(s) + round(x) + int(x) + abs(-3) + random(6) - -1')),
    Assign(target: 'ok', value: e('"abc" < s and not (s == "x") or n % 2 == 0')),
    Output(value: e('"valore: " & n & ", " & x & ", " & ok')),
    Output(value: e('ok')),
    If(
      cond: e('digitalRead(PULSANTE) == LOW'),
      then: [DigitalWrite(pin: e('LED'), value: e('HIGH'))],
      otherwise: [DigitalWrite(pin: e('LED'), value: e('LOW'))],
    ),
    For(
      variable: 'i',
      from: e('0'),
      to: e('255'),
      step: e('5'),
      body: [
        AnalogWrite(pin: e('LUCE'), value: e('i')),
        Delay(ms: e('10')),
      ],
    ),
    For(
      variable: 'i',
      from: e('3'),
      to: e('1'),
      step: e('-1'),
      body: [Output(value: e('i'))],
    ),
    While(
      cond: e('analogRead(POT) > 1000'),
      body: [Delay(ms: e('1'))],
    ),
    DoWhile(
      body: [Assign(target: 'n', value: e('n - 1'))],
      cond: e('n > 0'),
    ),
    Comment(text: 'fine'),
  ],
);

void main() {
  final tmp = Directory.systemTemp.createTempSync('dbflow_arduino');
  tearDownAll(() => tmp.deleteSync(recursive: true));

  group('esempi', () {
    for (final name in arduinoExamples) {
      test('$name: nessun problema', () => expect(validate(example(name)), isEmpty));

      for (final lang in CodeLanguage.forProgram(example(name))) {
        test('snapshot $name.${lang.extension}', () {
          final code = generateCode(example(name), lang);
          final golden = File('test/arduino/golden/$name.${lang.extension}');
          if (update || !golden.existsSync()) {
            golden
              ..createSync(recursive: true)
              ..writeAsStringSync(code);
          }
          expect(code, golden.readAsStringSync());
        });
      }

      test(
        '$name compila per Arduino Uno',
        () async {
          final r = await compile(
            tmp,
            name,
            generateCode(example(name), CodeLanguage.arduino),
            arduinoUno,
          );
          expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
        },
        skip: cli == null ? 'arduino-cli non disponibile' : false,
        timeout: const Timeout.factor(4),
      );
    }
  });

  test('sketch con tutte le funzionalità: valido e compila senza avvisi', () async {
    final p = everything();
    expect(messages(p), isEmpty);
    final code = generateCode(p, CodeLanguage.arduino);
    expect(code, contains('long n = 0;'));
    expect(code, contains('String s = "";'));
    expect(code, contains('pinMode(PULSANTE, INPUT_PULLUP);'));
    expect(code, isNot(contains('pinMode(POT')));
    expect(code, contains('Serial.begin(9600);'));
    expect(code, contains('1000L * 60'));
    expect(code, contains("n = Serial.readStringUntil('\\n').toInt();"));
    expect(code, contains('Serial.print("valore: ");'));
    expect(code, contains('Serial.println(ok ? "vero" : "falso");'));
    expect(code, contains('String(s) == "x"'.replaceFirst('String(s)', 's')));
    expect(code, contains('String("abc") < s'));
    if (cli == null) return;
    final r = await compile(tmp, 'tutto', code, arduinoUno);
    expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
    final sketchWarnings = '${r.stderr}'.split('\n').where((l) => l.contains('tutto.ino'));
    expect(sketchWarnings, isEmpty, reason: '${r.stderr}');
  }, timeout: const Timeout.factor(4));

  group('validazione dei pin', () {
    test('pin non configurato', () {
      final m = messages(sketch([], [DigitalWrite(pin: e('LED'), value: e('HIGH'))]));
      expect(m.single, contains("pin 'LED' non configurato"));
      final r = messages(sketch([], [Output(value: e('digitalRead(BTN)'))]));
      expect(r.single, contains("pin 'BTN' non configurato"));
      final n = messages(sketch([], [DigitalWrite(pin: e('13'), value: e('HIGH'))]));
      expect(n.single, contains('il pin 13 non è configurato'));
    });

    test('scrittura su un ingresso e lettura di un\'uscita', () {
      expect(
        messages(sketch([button], [DigitalWrite(pin: e('PULSANTE'), value: e('HIGH'))])).single,
        contains("dev'essere un'uscita"),
      );
      expect(
        messages(sketch([led], [Output(value: e('digitalRead(LED)'))])).single,
        contains("è un'uscita"),
      );
    });

    test('PWM solo sui pin che lo supportano', () {
      expect(
        messages(sketch([led], [AnalogWrite(pin: e('LED'), value: e('100'))])).single,
        contains('3, 5, 6, 9, 10, 11'),
      );
      expect(messages(sketch([pwmLed], [AnalogWrite(pin: e('LUCE'), value: e('100'))])), isEmpty);
      expect(
        messages(sketch([pwmLed], [AnalogWrite(pin: e('LUCE'), value: e('300'))])).single,
        contains('da 0 a 255'),
      );
    });

    test('analogRead solo su A0–A5 configurati come analogici', () {
      expect(messages(sketch([pot], [Output(value: e('analogRead(POT)'))])), isEmpty);
      const digitalA1 = PinConfig(name: 'S', pin: 'A1', mode: PinMode.input);
      expect(
        messages(sketch([digitalA1], [Output(value: e('analogRead(S)'))])).single,
        contains('ingresso analogico'),
      );
      expect(
        messages(sketch([button], [Output(value: e('analogRead(PULSANTE)'))])).single,
        contains('A0, A1'),
      );
    });

    test('pin inesistente, pin o nome doppi, pin seriali', () {
      expect(
        messages(sketch([const PinConfig(name: 'X', pin: '20', mode: PinMode.output)], [])).single,
        contains('non esiste'),
      );
      expect(
        messages(sketch([led, const PinConfig(name: 'LED2', pin: '13', mode: PinMode.output)], [])),
        contains(contains('configurato due volte')),
      );
      expect(
        messages(sketch([led, const PinConfig(name: 'LED', pin: '12', mode: PinMode.output)], [])),
        contains(contains('usato per due pin')),
      );
      const rx = PinConfig(name: 'RX', pin: '0', mode: PinMode.input);
      expect(messages(sketch([rx], [])), isEmpty);
      expect(
        messages(sketch([rx], [Output(value: e('1'))])).single,
        contains('comunicazione seriale'),
      );
    });

    test('costanti e nomi', () {
      expect(
        messages(sketch([led], [Assign(target: 'LED', value: e('3'))])).single,
        contains('costante'),
      );
      expect(
        messages(sketch([led], [Declare(name: 'LED', type: VarType.integer)])).single,
        contains('già il nome di un pin'),
      );
      expect(
        messages(sketch([const PinConfig(name: 'delay', pin: '7', mode: PinMode.output)], []))
            .single,
        contains('riservata'),
      );
    });

    test('delay', () {
      expect(messages(sketch([], [Delay(ms: e('-5'))])).single, contains('negativa'));
      expect(messages(sketch([], [Delay(ms: e('0.5'))])).single, contains('millisecondi interi'));
    });

    test('blocchi e funzioni Arduino non ammessi negli algoritmi', () {
      final p = Program(
        name: 'a',
        body: [
          Delay(ms: e('5')),
          Output(value: e('millis()')),
        ],
      );
      final m = messages(p);
      expect(m, contains(contains('solo nei diagrammi Arduino')));
      expect(m, contains("'millis' si può usare solo nei diagrammi Arduino"));
    });
  });

  test('proposte dei pin dedotte dal diagramma', () {
    final p = sketch(
      [led],
      [
        DigitalWrite(pin: e('LED'), value: e('HIGH')),
        DigitalWrite(pin: e('ROSSO'), value: e('LOW')),
        AnalogWrite(pin: e('6'), value: e('10')),
        If(cond: e('digitalRead(TASTO) == LOW and analogRead(A2) > 5')),
      ],
    );
    final s = {for (final x in suggestPins(p)) x.name: x};
    expect(s.keys, unorderedEquals(['ROSSO', 'PIN_6', 'TASTO', 'PIN_A2']));
    expect(s['ROSSO']!.mode, PinMode.output);
    expect(s['PIN_6']!.pin, '6');
    expect(s['TASTO']!.mode, PinMode.inputPullup, reason: 'come il componente pulsante');
    expect(s['PIN_A2']!.mode, PinMode.analogInput);
  });

  group('file e modifiche', () {
    test('un file della versione 1 si apre come algoritmo', () {
      final p = decodeProgram(
        jsonEncode({
          'format': 'db-flow',
          'version': 1,
          'name': 'vecchio',
          'body': [
            {'id': 'a', 't': 'comment', 'text': 'x'},
          ],
        }),
      );
      expect(p.kind, ProgramKind.algorithm);
      expect(p.arduino, isNull);
      expect(programToJson(p)['version'], 2);
    });

    test('round-trip di uno sketch con configurazione', () {
      final p = everything();
      final back = decodeProgram(encodeProgram(p));
      expect(jsonEncode(programToJson(back)), jsonEncode(programToJson(p)));
      expect(back.arduino!.pins.map((p) => p.mode), [
        PinMode.output,
        PinMode.output,
        PinMode.inputPullup,
        PinMode.analogInput,
      ]);
    });

    test('scheda sconosciuta e pin malformati vengono gestiti', () {
      final p = decodeProgram(
        jsonEncode({
          'format': 'db-flow',
          'version': 2,
          'name': 'x',
          'kind': 'arduino',
          'arduino': {
            'board': 'mega9000',
            'baud': 'veloce',
            'pins': [
              {'name': 'A', 'pin': '3', 'mode': 'output'},
              {'name': 'B', 'mode': 'output'},
              'rotto',
            ],
          },
          'body': <Object>[],
        }),
      );
      expect(p.arduino!.boardId, 'uno');
      expect(p.arduino!.baud, 9600);
      expect(p.arduino!.pins.single.name, 'A');
    });

    test('inserimento nella parte setup', () {
      var p = sketch([], []);
      p = insertAt(p, const Slot(setupListId, Branch.body, 0), Comment(id: 'c', text: 'x'));
      expect(p.setup.single.id, 'c');
      expect(p.body, isEmpty);
      expect(findBlock(p, 'c'), isNotNull);
      p = removeBlock(p, 'c');
      expect(p.setup, isEmpty);
    });

    test('blocchi Arduino solo nei diagrammi Arduino', () {
      expect(BlockKind.available(ProgramKind.algorithm), isNot(contains(BlockKind.delay)));
      expect(BlockKind.available(ProgramKind.arduino), contains(BlockKind.delay));
    });
  });

  test('profilo della scheda Uno', () {
    expect(arduinoUno.pinNumber('A0'), 14);
    expect(arduinoUno.pinName(19), 'A5');
    expect(arduinoUno.pinName(20), isNull);
    expect(arduinoUno.modesFor('A0'), contains(PinMode.analogInput));
    expect(arduinoUno.modesFor('7'), isNot(contains(PinMode.analogInput)));
  });

  group('blocchi di lettura dei pin', () {
    test('validazione', () {
      final ok = sketch(
        [button, pot],
        [DigitalRead(variable: 'v', pin: e('PULSANTE')), AnalogRead(variable: 'v', pin: e('POT'))],
        setup: [Declare(name: 'v', type: VarType.integer)],
      );
      expect(messages(ok), isEmpty);
      expect(
        messages(
          sketch(
            [led],
            [DigitalRead(variable: 'v', pin: e('LED'))],
            setup: [Declare(name: 'v', type: VarType.integer)],
          ),
        ).single,
        contains("è un'uscita"),
      );
      expect(
        messages(
          sketch(
            [pot],
            [AnalogRead(variable: 'r', pin: e('POT'))],
            setup: [Declare(name: 'r', type: VarType.real)],
          ),
        ).single,
        contains('variabile intera'),
      );
      expect(
        messages(
          sketch(
            [],
            [AnalogRead(variable: 'v', pin: e('SENS'))],
            setup: [Declare(name: 'v', type: VarType.integer)],
          ),
        ).single,
        contains("pin 'SENS' non configurato"),
      );
    });

    test('codice, file e proposte', () {
      final p = sketch(
        [button],
        [DigitalRead(variable: 'v', pin: e('PULSANTE')), AnalogRead(variable: 'v', pin: e('LUX'))],
        setup: [Declare(name: 'v', type: VarType.integer)],
      );
      final code = generateCode(p, CodeLanguage.arduino);
      expect(code, contains('v = digitalRead(PULSANTE);'));
      expect(code, contains('v = analogRead(LUX);'));
      final back = decodeProgram(encodeProgram(p));
      expect(back.body.first, isA<DigitalRead>());
      expect((back.body.last as AnalogRead).pin.text, 'LUX');
      expect(suggestPins(p).single.mode, PinMode.analogInput);
    });
  });

  group('disegno della scheda', () {
    test('ogni pin utilizzabile della Uno ha una posizione sul disegno', () {
      final d = arduinoUno.drawing!;
      for (final pin in arduinoUno.allPins) {
        final c = d.pinCenter(pin);
        expect(c, isNotNull, reason: pin);
        expect(c!.x, inInclusiveRange(0, d.width), reason: pin);
        expect(c.y, inInclusiveRange(0, d.height), reason: pin);
      }
      expect(d.pinCenter('13')!.side, Side.top);
      expect(d.pinCenter('A0')!.side, Side.bottom);
    });
  });
}
