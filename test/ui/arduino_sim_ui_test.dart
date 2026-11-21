import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/ui/editor_page.dart';
import 'package:db_flow/ui/run_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Program example(String name) =>
    decodeProgram(File('assets/examples/$name.flow').readAsStringSync());

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dbflow_sim');
    setLanguage(AppLanguage.it);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pumpEditor(
    WidgetTester tester,
    Program p, {
    Size size = const Size(1600, 2400),
    double ratio = 2,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(
          file: File('${tmp.path}/t.flow'),
          program: p,
          storage: FlowStorage(baseDir: () async => tmp),
        ),
      ),
    );
  }

  /// «Esegui» nella barra: pulsante con testo (schermo largo) o icona (telefono).
  Future<void> startRun(WidgetTester tester) async {
    final icon = find.byTooltip('Esegui');
    await tester.tap(icon.evaluate().isNotEmpty ? icon : find.text('Esegui'));
    await tester.pumpAndSettle();
  }

  testWidgets('Blink: passo dopo passo il LED si accende e si spegne', (tester) async {
    await pumpEditor(tester, example('blink'));
    await startRun(tester);
    expect(find.text('Circuito'), findsOneWidget);
    expect(find.textContaining('spento'), findsOneWidget);
    Future<void> step() async {
      await tester.tap(find.byTooltip('Un passo'));
      await tester.pump();
    }

    await step(); // inizio di loop()
    await step(); // digitalWrite(LED, HIGH)
    expect(find.textContaining('acceso · HIGH'), findsOneWidget);
    await step(); // delay(500)
    expect(find.textContaining('millis() = 50'), findsOneWidget);
    await step(); // digitalWrite(LED, LOW)
    expect(find.textContaining('spento · LOW'), findsOneWidget);

    // «fino alla fine del giro»: si arriva al giro 2 di loop()
    await tester.tap(find.byTooltip('Fino alla fine di questo giro di loop()'));
    await tester.pump();
    expect(find.textContaining('giro 2 di loop()'), findsOneWidget);
  });

  testWidgets('Blink in esecuzione automatica: i delay durano davvero', (tester) async {
    await pumpEditor(tester, example('blink'));
    await startRun(tester);
    // velocità al massimo: 0,1 s per blocco
    await tester.drag(find.byType(Slider).first, const Offset(2000, 0));
    await tester.pump();
    await tester.tap(find.byTooltip('Esegui').last);
    await tester.pump();
    // 0,1 s: inizio di loop(); 0,2 s: LED acceso; poi delay(500)
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('acceso'), findsOneWidget);
    // a 0,7 s il delay non è ancora finito
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.textContaining('acceso'), findsOneWidget);
    // a 0,85 s il LED è spento: il delay è durato mezzo secondo
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('spento'), findsOneWidget);
    await tester.tap(find.byTooltip('Pausa'));
    await tester.pump();
  });

  testWidgets('Pulsante: premendolo nel circuito il LED si accende', (tester) async {
    await pumpEditor(tester, example('pulsante'));
    await startRun(tester);
    final toEnd = find.byTooltip('Fino alla fine di questo giro di loop()');
    await tester.tap(toEnd);
    await tester.pump();
    await tester.tap(toEnd);
    await tester.pump();
    expect(find.text('rilasciato'), findsOneWidget);
    expect(find.textContaining('spento'), findsOneWidget);
    await tester.tap(find.text('rilasciato'));
    await tester.pump();
    expect(find.text('premuto'), findsOneWidget);
    await tester.tap(toEnd);
    await tester.pump();
    expect(find.textContaining('acceso'), findsOneWidget);
  });

  testWidgets('Dimmer: il cursore del potenziometro cambia il PWM', (tester) async {
    await pumpEditor(tester, example('dimmer'));
    await startRun(tester);
    final slider = find.byType(Slider).last;
    await tester.drag(slider, const Offset(2000, 0));
    await tester.pump();
    await tester.tap(find.byTooltip('Fino alla fine di questo giro di loop()'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fino alla fine di questo giro di loop()'));
    await tester.pump();
    expect(find.textContaining('PWM 255 (100%)'), findsOneWidget);
  });

  testWidgets('telefono: tre schede, Circuito per prima', (tester) async {
    await pumpEditor(tester, example('blink'), size: const Size(390 * 3, 844 * 3), ratio: 3);
    await startRun(tester);
    final tabs = tester.widget<TabBar>(find.byType(TabBar)).tabs.cast<Tab>();
    expect(tabs.map((t) => t.text), ['Circuito', 'Variabili', 'Console']);
    expect(find.textContaining('spento'), findsOneWidget);
    expect(RunController.maxConsoleLines, 500);
  });
}
