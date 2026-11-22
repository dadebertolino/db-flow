// Screenshot per le schede degli store. Non fa parte di `flutter test`: si
// lancia con `tool/screenshots/take.sh`, che guida i simulatori e raccoglie le
// immagini. Usa una cartella temporanea per i diagrammi e le preferenze: i
// dati veri dell'app (anche sul Mac, dove il contenitore è lo stesso) non
// vengono toccati.
//
// Ogni schermata viene annunciata con una riga `DBFLOW_SHOT <lingua> <nome> <file>`:
// - iPhone e iPad: `<file>` è `-`, lo script cattura il simulatore (con la barra di stato);
// - Mac: il test rende la finestra a 2880×1800 e scrive il PNG in `<file>`.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:db_flow/app.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/settings.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/render/board_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Lingue da fotografare: `--dart-define=SHOT_LANGS=it,en`; di default tutte.
const _langs = String.fromEnvironment('SHOT_LANGS', defaultValue: 'it,en,fr,de,es');

/// Tempo lasciato allo script per catturare il simulatore.
const _captureWait = Duration(milliseconds: 2500);

/// Dispositivo reso dal test: sul Mac `--dart-define=SHOT_DEVICE=ipad`, di
/// default il Mac; sul PC sempre Windows.
final _device = Platform.isWindows
    ? 'windows'
    : const String.fromEnvironment('SHOT_DEVICE', defaultValue: 'mac');

/// Misure in punti e densità: Mac 2880×1800, iPad 13" 2064×2752, Windows
/// 1920×1080 (Microsoft Store: almeno 1366×768).
const _sizes = {
  'mac': (Size(1440, 900), 2.0),
  'ipad': (Size(1032, 1376), 2.0),
  'windows': (Size(1280, 720), 1.5),
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  for (final code in _langs.split(',')) {
    final lang = AppLanguage.fromCode(code.trim())!;
    testWidgets('screenshot ${lang.name}', (tester) async {
      await _session(tester, lang);
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}

Future<void> _session(WidgetTester tester, AppLanguage lang) async {
  // Sul Mac e sul PC si rende l'immagine da sé, alla misura del dispositivo
  // scelto (lo schermo di sviluppo è più piccolo; il simulatore iPad senza
  // finestra è troppo lento e instabile). L'iPad si comporta come su iOS e ha
  // lo spazio della barra di stato (24 punti), che resta vuoto. Su Windows le
  // immagini vanno in %TEMP%\dbflow_shots\windows\<lingua>.
  final mac = Platform.isMacOS || Platform.isWindows;
  if (mac) {
    final (size, ratio) = _sizes[_device]!;
    tester.view.physicalSize = size * ratio;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    if (_device == 'ipad') {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.padding = const FakeViewPadding(top: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 48);
    }
  }

  final tmp = await tester.runAsync(() => Directory.systemTemp.createTemp('dbflow_shots'));
  addTearDown(() => tester.runAsync(() => tmp!.delete(recursive: true)));
  final storage = FlowStorage(baseDir: () async => tmp!);
  final settings = AppSettings(baseDir: () async => tmp!);
  await tester.runAsync(() => settings.setThemeMode(ThemeMode.light));

  setLanguage(lang);
  Future<Program> asset(String base, String name) async {
    final dir = lang == AppLanguage.it ? base : '$base/${lang.name}';
    return decodeProgram(await rootBundle.loadString('$dir/$name.flow'));
  }

  final examples = <String, Program>{};
  for (final n in ['primo', 'mcd', 'dimmer', 'fattoriale', 'blink', 'tabelline']) {
    examples[n] = (await tester.runAsync(() => asset('assets/examples', n)))!;
  }
  final exercise = (await tester.runAsync(() => asset('assets/exercises', 'massimo3')))!;
  final solved = exercise.copyWith(body: _massimo3Solution);

  // Diagrammi già salvati, perché la home non sia vuota (dal meno recente).
  for (final p in [examples['tabelline']!, examples['blink']!, examples['fattoriale']!, solved]) {
    await tester.runAsync(() async {
      await storage.create(p);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  }

  await tester.pumpWidget(
    DbFlowApp(
      key: ValueKey(lang),
      storage: storage,
      settings: settings,
      locale: Locale(lang.name),
      splashDuration: Duration.zero,
    ),
  );
  await _settle(tester);

  Future<void> shot(String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
    if (!mac) {
      // ignore: avoid_print
      print('DBFLOW_SHOT ${lang.name} $name -');
      await tester.runAsync(() => Future<void>.delayed(_captureWait));
      return;
    }
    final file = File('${Directory.systemTemp.path}/dbflow_shots/$_device/${lang.name}/$name.png');
    await tester.runAsync(() async {
      final view = tester.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      // Il livello radice è già in pixel fisici.
      final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    });
    // ignore: avoid_print
    print('DBFLOW_SHOT ${lang.name} $name ${file.path}');
  }

  // 1. Home
  await shot('home');

  // 2. Editor e 3. codice Python: «Numero primo»
  await _openExample(tester, examples['primo']!.name);
  await _fitAll(tester);
  await shot('editor');
  await tester.tap(find.byTooltip(tr.more));
  await _settle(tester);
  await tester.tap(find.text(tr.code));
  await _settle(tester);
  await tester.tap(find.text('Python'));
  await _settle(tester);
  await shot('code');
  await _back(tester); // editor
  await _back(tester); // home

  // 4. Esecuzione passo-passo: «MCD» con 84 e 36
  await _openExample(tester, examples['mcd']!.name);
  await _tapRun(tester);
  for (final value in ['84', '36']) {
    for (var i = 0; i < 10 && find.byType(TextField).evaluate().isEmpty; i++) {
      await _step(tester);
    }
    await tester.enterText(find.byType(TextField), value);
    await tester.tap(find.text(tr.send));
    await _settle(tester);
  }
  for (var i = 0; i < 5; i++) {
    await _step(tester);
  }
  await shot('run');
  await _stopRun(tester);
  await _back(tester); // home

  // 5. Pin e scheda e 6. simulazione: «Dimmer»
  await _openExample(tester, examples['dimmer']!.name);
  final pinsIcon = find.byTooltip(tr.pinsAndBoard);
  await tester.tap(pinsIcon.evaluate().isNotEmpty ? pinsIcon.first : find.text(tr.pin));
  await _settle(tester);
  // la scheda intera al centro, con le etichette dei componenti
  await Scrollable.ensureVisible(tester.element(find.byType(BoardView)), alignment: 0.5);
  await _settle(tester);
  await shot('pins');
  await _back(tester);
  await _tapRun(tester);
  // velocità al massimo, poi esecuzione automatica
  await tester.drag(find.byType(Slider).first, const Offset(2000, 0));
  await _settle(tester);
  await tester.tap(find.byTooltip(tr.run).last);
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(find.byTooltip(tr.pause).last);
  await _settle(tester);
  await shot('arduino');
  await _stopRun(tester);
  await _back(tester);

  // 7. Esercizio risolto e verificato
  await _openSaved(tester, solved.name);
  await tester.tap(find.text(tr.verify));
  await _settle(tester);
  await _back(tester); // dalla pagina dei risultati all'editor, con «5/5» nella consegna
  await _fitAll(tester, minScale: 0.8);
  await shot('exercise');
  // va azzerata prima dei controlli finali del test (un tearDown è troppo tardi)
  debugDefaultTargetPlatformOverride = null;
}

final _massimo3Solution = <Stmt>[
  for (final n in ['a', 'b', 'c', 'm']) Declare(name: n, type: VarType.integer),
  for (final n in ['a', 'b', 'c']) Input(variable: n),
  Assign(target: 'm', value: ExprSource('a')),
  If(
    cond: ExprSource('b > m'),
    then: [Assign(target: 'm', value: ExprSource('b'))],
  ),
  If(
    cond: ExprSource('c > m'),
    then: [Assign(target: 'm', value: ExprSource('c'))],
  ),
  Output(value: ExprSource('m')),
];

/// Come `pumpAndSettle`, ma con un limite: le animazioni infinite non lo bloccano.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame) break;
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _back(WidgetTester tester) async {
  await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
  await _settle(tester);
}

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await _settle(tester);
}

/// Apre un esempio dalla home (ne crea una copia).
Future<void> _openExample(WidgetTester tester, String name) async {
  await _scrollTo(tester, find.text(name));
  await tester.tap(find.text(name).last);
  await _settle(tester);
}

/// Apre un diagramma salvato (in cima alla home).
Future<void> _openSaved(WidgetTester tester, String name) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  await _settle(tester);
  await tester.tap(find.text(name).first);
  await _settle(tester);
}

/// «Esegui» nella barra: icona sul telefono, pulsante con testo altrove.
Future<void> _tapRun(WidgetTester tester) async {
  final icon = find.byTooltip(tr.run);
  await tester.tap(icon.evaluate().isNotEmpty ? icon.first : find.text(tr.run));
  await _settle(tester);
}

/// Rimpicciolisce il diagramma perché stia tutto nello schermo (non sotto [minScale]).
Future<void> _fitAll(WidgetTester tester, {double minScale = 0.55}) async {
  final viewer = find.byType(InteractiveViewer);
  final iv = tester.widget<InteractiveViewer>(viewer);
  final view = tester.getSize(viewer);
  final diagram = tester.getSize(find.descendant(of: viewer, matching: find.byWidget(iv.child!)));
  final scale = math
      .min(1.0, math.min((view.width - 32) / diagram.width, (view.height - 32) / diagram.height))
      .clamp(minScale, 1.0);
  final dx = math.max(0.0, (view.width - diagram.width * scale) / 2);
  final dy = math.max(0.0, (view.height - diagram.height * scale) / 2);
  iv.transformationController!.value = Matrix4.translationValues(dx, dy, 0)
    ..multiply(Matrix4.diagonal3Values(scale, scale, 1));
  await _settle(tester);
}

/// Dall'esecuzione torna alla modifica.
Future<void> _stopRun(WidgetTester tester) async {
  final icon = find.byTooltip(tr.backToEdit);
  await tester.tap(icon.evaluate().isNotEmpty ? icon.first : find.text(tr.edit).first);
  await _settle(tester);
}

Future<void> _step(WidgetTester tester) async {
  await tester.tap(find.byTooltip(tr.oneStep));
  await _settle(tester);
}
