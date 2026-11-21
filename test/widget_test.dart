import 'dart:io';

import 'package:db_flow/app.dart';
import 'package:db_flow/app_info.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/arduino/board.dart';
import 'package:db_flow/editor/editor_state.dart';
import 'package:db_flow/render/board_painter.dart';
import 'package:db_flow/ui/arduino_setup_page.dart';
import 'package:db_flow/ui/about_page.dart';
import 'package:db_flow/ui/splash_page.dart';
import 'package:db_flow/ui/code_page.dart';
import 'package:db_flow/ui/editor_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tmp = Directory.systemTemp.createTempSync('dbflow_test');
  final storage = FlowStorage(baseDir: () async => tmp);
  tearDownAll(() => tmp.deleteSync(recursive: true));
  // Ogni test parte in italiano (alcuni avviano l'app con la lingua del sistema).
  setUp(() => setLanguage(AppLanguage.it));
  tearDown(() => setLanguage(AppLanguage.it));

  testWidgets("l'app si avvia", (tester) async {
    await tester.pumpWidget(
      DbFlowApp(storage: storage, locale: const Locale('it'), splashDuration: Duration.zero),
    );
    expect(find.text('DB Flow'), findsOneWidget);
  });

  Future<void> pumpEditor(WidgetTester tester, Program p) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(file: File('${tmp.path}/t.flow'), program: p, storage: storage),
      ),
    );
  }

  testWidgets('editor: inserisci un commento e annulla', (tester) async {
    await pumpEditor(tester, Program(name: 'Prova'));
    expect(find.text('Inizio'), findsOneWidget);
    expect(find.text('Fine'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Inserisci un blocco').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ciao');
    await tester.pump();
    await tester.tap(find.text('Inserisci'));
    await tester.pumpAndSettle();
    expect(find.text('ciao'), findsOneWidget);

    await tester.tap(find.byTooltip('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('ciao'), findsNothing);
    await tester.tap(find.byTooltip('Ripeti'));
    await tester.pumpAndSettle();
    expect(find.text('ciao'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // salvataggio automatico
  });

  testWidgets('editor: i blocchi con errori sono segnalati', (tester) async {
    await pumpEditor(
      tester,
      Program(
        name: 'Errori',
        body: [Output(id: 'o', value: ExprSource('x + 1'))],
      ),
    );
    expect(find.textContaining('1 problema'), findsOneWidget);
    await tester.tap(find.text('Scrivi x + 1'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text("variabile 'x' non dichiarata"), findsOneWidget);
  });

  testWidgets('editor: dichiarazione con nome non valido', (tester) async {
    await pumpEditor(
      tester,
      Program(
        name: 'D',
        body: [Declare(id: 'd', name: 'a', type: VarType.integer)],
      ),
    );
    await tester.tap(find.text('intero a'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Modifica'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'età');
    await tester.pump();
    expect(find.textContaining('accento'), findsOneWidget);
    await tester.tap(find.text('Annulla').last);
    await tester.pumpAndSettle();
  });

  testWidgets('esecuzione: passo-passo con input su telefono', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = decodeProgram(File('assets/examples/massimo.flow').readAsStringSync());
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(file: File('${tmp.path}/m.flow'), program: p, storage: storage),
      ),
    );
    await tester.tap(find.byTooltip('Esegui'));
    await tester.pumpAndSettle();
    expect(find.text('Variabili'), findsOneWidget);
    expect(find.bySemanticsLabel('Inserisci un blocco'), findsNothing);

    await tester.tap(find.byTooltip('Fino alla fine'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Scrivi un valore per a'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.text('Invio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('Invio'));
    await tester.pumpAndSettle();
    expect(find.textContaining('numero intero'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '11');
    await tester.tap(find.text('Invio'));
    await tester.pumpAndSettle();
    expect(find.text('Il massimo è 11'), findsOneWidget);
    expect(find.textContaining('Terminato'), findsOneWidget);

    await tester.tap(find.byTooltip('Torna a modificare'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Inserisci un blocco'), findsWidgets);
  });

  testWidgets('esecuzione bloccata se ci sono errori', (tester) async {
    await pumpEditor(
      tester,
      Program(
        name: 'E',
        body: [Output(value: ExprSource('y'))],
      ),
    );
    await tester.tap(find.text('Esegui'));
    await tester.pump();
    expect(find.textContaining('Correggi prima'), findsOneWidget);
  });

  testWidgets('pagina del codice', (tester) async {
    final p = decodeProgram(File('assets/examples/mcd.flow').readAsStringSync());
    await tester.pumpWidget(MaterialApp(home: CodePage(program: p)));
    expect(find.textContaining('ALGORITMO MCD'), findsOneWidget);
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    expect(find.textContaining('while b != 0:'), findsOneWidget);
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(find.textContaining('int main(void)'), findsOneWidget);
  });

  testWidgets('Arduino: helper dei pin con proposta e anteprima di setup()', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = Program(
      name: 'Semaforo',
      kind: ProgramKind.arduino,
      body: [DigitalWrite(id: 'w', pin: ExprSource('ROSSO'), value: ExprSource('HIGH'))],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(file: File('${tmp.path}/s.flow'), program: p, storage: storage),
      ),
    );
    expect(find.text('setup()'), findsOneWidget);
    expect(find.text('loop()'), findsOneWidget);
    expect(find.text('digitalWrite(ROSSO, HIGH)'), findsOneWidget);
    expect(find.byTooltip('Esegui'), findsOneWidget, reason: 'la simulazione');
    expect(find.textContaining('1 problema'), findsOneWidget);

    await tester.tap(find.byTooltip('Pin e scheda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ROSSO → LED'), findsOneWidget);
    await tester.tap(find.text('Aggiungi').first);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.ensureVisible(find.descendant(of: dialog, matching: find.text('12')));
    await tester.tap(find.descendant(of: dialog, matching: find.text('12')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Aggiungi')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('pinMode(ROSSO, OUTPUT);'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('pinMode(ROSSO, OUTPUT);'), findsOneWidget);
    expect(find.textContaining('const int ROSSO = 12;'), findsOneWidget);
    expect(find.textContaining('non configurati'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('problema'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('nuovo diagramma: scelta Arduino', (tester) async {
    await tester.pumpWidget(
      DbFlowApp(storage: storage, locale: const Locale('it'), splashDuration: Duration.zero),
    );
    await tester.pump();
    await tester.tap(find.text('Nuovo diagramma'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Arduino'), findsOneWidget);
    await tester.tap(find.text('Arduino'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('setup() e una loop()'), findsOneWidget);
  });

  testWidgets('disegno della scheda: tocco su un pin libero e su uno configurato', (tester) async {
    final cfg = ArduinoConfig(
      pins: const [PinConfig(name: 'LED', pin: '13', mode: PinMode.output)],
    );
    const size = Size(800, 800 / 1.0);
    final d = cfg.board.drawing!;
    final s = BoardPainter.scaleFor(d, size.width);
    Offset at(String pin) {
      final c = d.pinCenter(pin)!;
      return BoardPainter.toLocal(d, size.width, (x: c.x, y: c.y));
    }

    expect(BoardPainter.pinAt(cfg, size, at('13')), '13');
    expect(BoardPainter.pinAt(cfg, size, at('A3')), 'A3');
    expect(BoardPainter.pinAt(cfg, size, at('13') - Offset(0, 10 * s)), '13');
    expect(BoardPainter.pinAt(cfg, size, const Offset(5, 400)), isNull);

    final p = Program(name: 'B', kind: ProgramKind.arduino, arduino: cfg);
    final state = EditorState(p);
    await tester.pumpWidget(MaterialApp(home: ArduinoSetupPage(state: state)));
    expect(find.byType(BoardView), findsOneWidget);
    final box = tester.getRect(
      find.descendant(of: find.byType(BoardView), matching: find.byType(CustomPaint)).first,
    );
    final c = d.pinCenter('7')!;
    await tester.tapAt(box.topLeft + BoardPainter.toLocal(d, box.width, (x: c.x, y: c.y)));
    await tester.pumpAndSettle();
    expect(find.text('Nuovo pin'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'MOTORE');
    await tester.pump();
    await tester.tap(find.text('Aggiungi').last);
    await tester.pumpAndSettle();
    final added = state.program.arduino!.pins.last;
    expect((added.name, added.pin, added.component), ('MOTORE', '7', Component.led));
  });

  testWidgets('scelta del pin: i pin occupati si vedono e si scambiano', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cfg = ArduinoConfig(
      pins: const [
        PinConfig(name: 'LED', pin: '13', mode: PinMode.output, component: Component.led),
        PinConfig(
          name: 'PULSANTE',
          pin: '2',
          mode: PinMode.inputPullup,
          component: Component.button,
        ),
      ],
    );
    final state = EditorState(Program(name: 'S', kind: ProgramKind.arduino, arduino: cfg));
    await tester.pumpWidget(MaterialApp(home: ArduinoSetupPage(state: state)));
    final ledTile = find.ancestor(of: find.text('LED'), matching: find.byType(ListTile)).first;
    await tester.ensureVisible(ledTile);
    await tester.pumpAndSettle();
    await tester.tap(ledTile);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    // il pin 2 mostra chi lo usa
    expect(find.descendant(of: dialog, matching: find.text('PULSANTE')), findsOneWidget);
    await tester.tap(find.descendant(of: dialog, matching: find.text('2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('si scambiano'), findsOneWidget);
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    final pins = {for (final p in state.program.arduino!.pins) p.name: p.pin};
    expect(pins, {'LED': '2', 'PULSANTE': '13'});
    expect(find.textContaining('PULSANTE spostato sul pin 13'), findsOneWidget);
    // un solo «Annulla» ripristina tutto
    state.undo();
    expect(
      {for (final p in state.program.arduino!.pins) p.name: p.pin},
      {'LED': '13', 'PULSANTE': '2'},
    );
  });

  testWidgets('informazioni: versione, privacy, guida, licenze', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    expect(find.text('Versione $appVersion'), findsOneWidget);
    expect(find.text('Nessuna raccolta dati'), findsOneWidget);
    expect(find.textContaining('open source'), findsNothing);
    await tester.scrollUntilVisible(find.text('digitalRead(pin)'), 300);
    expect(find.text('digitalRead(pin)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Licenze dei componenti usati'), 300);
    await tester.tap(find.text('Licenze dei componenti usati'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  test('la versione mostrata coincide con pubspec.yaml', () {
    final m = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(m!.group(1), appVersion);
  });

  testWidgets('schermata di avvio: nome, versione, autore, almeno un secondo', (tester) async {
    await tester.pumpWidget(DbFlowApp(storage: storage, locale: const Locale('it')));
    expect(find.text('DB Flow'), findsOneWidget);
    expect(find.text('Versione $appVersion'), findsOneWidget);
    expect(find.text(appAuthor), findsOneWidget);
    // lo sfondo copre tutto lo schermo, non solo la colonna del testo
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(SplashView)), screen);
    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text(appAuthor), findsOneWidget, reason: 'ancora visibile prima di un secondo');
    expect(find.text('Nuovo diagramma'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(appAuthor), findsNothing);
    expect(find.text('Nuovo diagramma'), findsOneWidget);
  });
}
