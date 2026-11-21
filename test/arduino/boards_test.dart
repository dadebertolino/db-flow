import 'dart:io';
import 'dart:ui' as ui;

import 'package:db_flow/arduino/board.dart';
import 'package:db_flow/arduino/pin_assign.dart';
import 'package:db_flow/arduino/pin_suggestions.dart';
import 'package:db_flow/codegen/generator.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/model/validator.dart';
import 'package:db_flow/render/board_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'arduino_test.dart' show cli, compile;

ExprSource e(String s) => ExprSource(s);

Program sketchOn(Board b, List<PinConfig> pins, List<Stmt> body) => Program(
  name: 'prova',
  kind: ProgramKind.arduino,
  arduino: ArduinoConfig(boardId: b.id, pins: pins),
  body: body,
);

List<String> messages(Program p) => validate(p).map((i) => i.message).toList();

void main() {
  setUp(() => setLanguage(AppLanguage.it));
  final tmp = Directory.systemTemp.createTempSync('dbflow_boards');
  tearDownAll(() => tmp.deleteSync(recursive: true));

  test('schede disponibili', () {
    expect(boards.keys, ['uno', 'nano', 'promini', 'micro', 'mega']);
    for (final b in boards.values) {
      expect(boardById(b.id), same(b));
    }
  });

  test('numeri dei pin', () {
    expect(arduinoNano.pinNumber('A7'), 21);
    expect(arduinoMicro.pinNumber('A0'), 18);
    expect(arduinoMicro.pinName(23), 'A5');
    expect(arduinoMega.pinNumber('A15'), 69);
    expect(arduinoMega.pinName(53), '53');
    expect(arduinoMega.pinName(54), 'A0');
    expect(arduinoMega.pwmPins, containsAll(['2', '13', '44', '46']));
    expect(arduinoMicro.serialPins, isEmpty, reason: 'USB nativa');
  });

  test('A6 e A7 di Nano e Pro Mini sono solo analogici', () {
    for (final b in [arduinoNano, arduinoProMini]) {
      expect(b.modesFor('A6'), [PinMode.analogInput]);
      expect(b.modesFor('A5'), contains(PinMode.output));
      expect(Component.led.fits(b, 'A7', PinMode.output), isFalse);
    }
    final pins = [
      const PinConfig(name: 'LUX', pin: 'A6', mode: PinMode.analogInput),
      const PinConfig(name: 'LED', pin: 'A7', mode: PinMode.output),
    ];
    final p = sketchOn(arduinoNano, pins, [
      Declare(name: 'v', type: VarType.integer),
      Assign(target: 'v', value: e('analogRead(LUX)')),
      Assign(target: 'v', value: e('digitalRead(LUX)')),
    ]);
    final m = messages(p);
    expect(m, contains(contains('LED'))); // A7 non può essere un'uscita
    expect(m, contains("'LUX' (pin A6) è solo un ingresso analogico: si legge con analogRead()."));
    expect(m.where((x) => x.contains('analogRead()')).length, 1);
    // nessuna proposta di digitalRead su A6
    final q = sketchOn(arduinoNano, const [], [
      Declare(name: 'v', type: VarType.integer),
      Assign(target: 'v', value: e('digitalRead(A6)')),
    ]);
    expect(suggestPins(q), isEmpty);
  });

  group('Micro: A6–A11 sono i pin 4, 6, 8, 9, 10, 12', () {
    test('numeri e nomi', () {
      expect(arduinoMicro.pinNumber('A6'), 24);
      expect(arduinoMicro.pinNumber('A11'), 29);
      expect(arduinoMicro.pinName(26), 'A8');
      expect(arduinoMicro.physical('A9'), '9');
      expect(arduinoMicro.analogNameOf('12'), 'A11');
      expect(arduinoMicro.samePin('A6', '4'), isTrue);
      expect(arduinoMicro.modesFor('A6'), [PinMode.analogInput]);
      expect(arduinoMicro.modesFor('4'), isNot(contains(PinMode.analogInput)));
      expect(arduinoMicro.physicalPins, isNot(contains('A6')));
    });

    test('lo stesso pin non si configura due volte con nomi diversi', () {
      final p = sketchOn(arduinoMicro, const [
        PinConfig(name: 'LED', pin: '4', mode: PinMode.output),
        PinConfig(name: 'POT', pin: 'A6', mode: PinMode.analogInput),
      ], const []);
      expect(messages(p), contains('il pin A6 (= 4) è configurato due volte'));
    });

    test('con il nome analogico si usa solo analogRead', () {
      final p = sketchOn(
        arduinoMicro,
        const [PinConfig(name: 'LUX', pin: 'A9', mode: PinMode.analogInput)],
        [
          Declare(name: 'v', type: VarType.integer),
          Assign(target: 'v', value: e('analogRead(LUX)')),
          Assign(target: 'v', value: e('digitalRead(LUX)')),
        ],
      );
      expect(messages(p), [
        "'LUX' (pin A9) si usa solo con analogRead(): come pin digitale è il pin 9.",
      ]);
    });

    test('nessuna proposta per un pin già configurato con l\'altro nome', () {
      final p = sketchOn(
        arduinoMicro,
        const [PinConfig(name: 'LED', pin: '4', mode: PinMode.output)],
        [
          Declare(name: 'v', type: VarType.integer),
          Assign(target: 'v', value: e('analogRead(A6)')),
        ],
      );
      expect(suggestPins(p), isEmpty);
    });

    test('un pin nuovo sul 4 sposta chi usa A6', () {
      final cfg = ArduinoConfig(
        boardId: 'micro',
        pins: const [
          PinConfig(
            name: 'POT',
            pin: 'A6',
            mode: PinMode.analogInput,
            component: Component.potentiometer,
          ),
        ],
      );
      final plan = planPin(cfg, null, const PinConfig(name: 'LED', pin: '4', mode: PinMode.output));
      expect(plan.displaced?.name, 'POT');
      expect(plan.displacedTo, 'A0');
    });

    test('analogRead(A6) compila', () async {
      final p = sketchOn(
        arduinoMicro,
        const [
          PinConfig(name: 'POT', pin: 'A6', mode: PinMode.analogInput),
          PinConfig(name: 'LUCE', pin: '9', mode: PinMode.output),
        ],
        [
          Declare(name: 'v', type: VarType.integer),
          Assign(target: 'v', value: e('analogRead(POT)')),
          AnalogWrite(pin: e('LUCE'), value: e('int(v / 4)')),
        ],
      );
      expect(messages(p), isEmpty);
      final code = generateCode(p, CodeLanguage.arduino);
      expect(code, contains('const int POT = A6;'));
      final r = await compile(tmp, 'micro_a6', code, arduinoMicro);
      expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
    }, skip: cli == null ? 'arduino-cli non disponibile' : false);
  });

  test('il file ricorda la scheda', () {
    final p = sketchOn(arduinoMega, const [
      PinConfig(name: 'LED', pin: '44', mode: PinMode.output),
    ], const []);
    expect(decodeProgram(encodeProgram(p)).arduino!.boardId, 'mega');
  });

  for (final b in boards.values) {
    group(b.name, () {
      test('ogni pin ha una posizione sul disegno, diversa dalle altre', () {
        final d = b.drawing!;
        final seen = <String>{};
        for (final pin in b.physicalPins) {
          final c = d.pinCenter(pin);
          expect(c, isNotNull, reason: pin);
          expect(c!.x, inInclusiveRange(0, d.width), reason: pin);
          expect(c.y, inInclusiveRange(0, d.height), reason: pin);
          expect(
            seen.add('${c.x.toStringAsFixed(2)},${c.y.toStringAsFixed(2)}'),
            isTrue,
            reason: '$pin sovrapposto',
          );
        }
      });

      test('toccando un pin si seleziona proprio quel pin', () {
        final cfg = ArduinoConfig(boardId: b.id);
        final d = b.drawing!;
        const width = 900.0;
        final size = Size(width, width / BoardPainter.aspectRatio(d));
        for (final pin in b.allPins) {
          // gli alias analogici (Micro: A6) stanno sul loro pin digitale
          final c = d.pinCenter(b.physical(pin))!;
          final at = BoardPainter.toLocal(d, width, (x: c.x, y: c.y));
          expect(BoardPainter.pinAt(cfg, size, at), b.physical(pin), reason: pin);
        }
      });

      test('il disegno si genera con tutti i pin configurati', () {
        final pins = [
          for (final (i, pin) in b.physicalPins.indexed)
            PinConfig(name: 'P$i', pin: pin, mode: b.modesFor(pin).first, component: Component.led),
        ];
        final cfg = ArduinoConfig(boardId: b.id, pins: pins);
        final recorder = ui.PictureRecorder();
        final size = Size(1000, 1000 / BoardPainter.aspectRatio(b.drawing!));
        BoardPainter(cfg, highlight: b.allPins.first).paint(Canvas(recorder), size);
        recorder.endRecording().dispose();
      });

      test(
        'lo sketch compila',
        () async {
          // ultimo pin PWM diverso dal LED integrato (sulla Micro anche il 13 è PWM)
          final pwm =
              (b.pwmPins.where((x) => x != b.ledBuiltin).toList()
                    ..sort((x, y) => int.parse(x).compareTo(int.parse(y))))
                  .last;
          final p = sketchOn(
            b,
            [
              PinConfig(name: 'LED', pin: b.ledBuiltin, mode: PinMode.output),
              PinConfig(name: 'LUCE', pin: pwm, mode: PinMode.output),
              const PinConfig(name: 'TASTO', pin: '2', mode: PinMode.inputPullup),
              PinConfig(name: 'POT', pin: b.analogPins.last, mode: PinMode.analogInput),
            ],
            [
              Declare(name: 'v', type: VarType.integer),
              Assign(target: 'v', value: e('analogRead(POT)')),
              AnalogWrite(pin: e('LUCE'), value: e('int(v / 4)')),
              If(
                cond: e('digitalRead(TASTO) == LOW'),
                then: [DigitalWrite(pin: e('LED'), value: e('HIGH'))],
                otherwise: [DigitalWrite(pin: e('LED'), value: e('LOW'))],
              ),
              Delay(ms: e('10')),
            ],
          );
          expect(messages(p), isEmpty);
          final r = await compile(tmp, 'scheda_${b.id}', generateCode(p, CodeLanguage.arduino), b);
          expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
        },
        skip: cli == null ? 'arduino-cli non disponibile' : false,
        timeout: const Timeout.factor(4),
      );
    });
  }
}
