import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/model/exercise.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:db_flow/ui/editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../runtime/builtin_exercises_test.dart' show solutions;

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dbflow_ex');
    setLanguage(AppLanguage.it);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Program somma() => decodeProgram(File('assets/exercises/somma.flow').readAsStringSync());

  Future<void> pumpEditor(WidgetTester tester, Program p) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
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

  testWidgets('studente: la verifica di un diagramma vuoto non passa', (tester) async {
    await pumpEditor(tester, somma());
    expect(find.textContaining('Leggi due numeri interi'), findsOneWidget);
    await tester.tap(find.text('Verifica'));
    await tester.pumpAndSettle();
    expect(find.text('Risultato della verifica'), findsOneWidget);
    expect(find.text('Superati 0 casi su 4'), findsOneWidget);
    expect(find.text('Caso nascosto'), findsNWidgets(2));
    expect(find.text('Caso 1'), findsOneWidget);
    expect(find.text('Il diagramma termina senza leggere tutti i dati del caso.'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('0/4'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('studente: con la soluzione tutti i casi passano', (tester) async {
    await pumpEditor(tester, somma().copyWith(body: solutions['somma']));
    await tester.tap(find.text('Verifica'));
    await tester.pumpAndSettle();
    expect(find.text('Tutti i casi superati!'), findsOneWidget);
    expect(find.text('superato'), findsNWidgets(4));
  });

  testWidgets('studente: con errori nel diagramma prima si correggono', (tester) async {
    await pumpEditor(tester, somma().copyWith(body: [Output(value: ExprSource('a +'))]));
    await tester.tap(find.text('Verifica'));
    await tester.pump();
    expect(find.text('Prima correggi gli errori segnalati nel diagramma.'), findsOneWidget);
    expect(find.text('Risultato della verifica'), findsNothing);
  });

  testWidgets('studente: la consegna ricevuta non mostra i casi nascosti', (tester) async {
    await pumpEditor(tester, somma());
    await tester.tap(find.textContaining('Leggi due numeri interi'));
    await tester.pumpAndSettle();
    expect(find.text('Caso 1'), findsOneWidget);
    expect(find.text('Caso 2'), findsOneWidget);
    expect(find.text('Caso 3'), findsNothing);
    expect(find.text('più 2 casi nascosti'), findsOneWidget);
    expect(find.textContaining('100'), findsNothing, reason: 'dati del caso nascosto');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('docente: crea un esercizio e calcola l\'output dal diagramma', (tester) async {
    final p = decodeProgram(File('assets/examples/massimo.flow').readAsStringSync());
    await pumpEditor(tester, p);
    await tester.tap(find.byTooltip('Altro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crea esercizio'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Scrivi il maggiore tra due numeri.');
    await tester.tap(find.text('Aggiungi caso'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(1), '3\n9');
    await tester.tap(find.text('Calcola dal diagramma'));
    await tester.pumpAndSettle();
    expect(find.text('Output calcolato per 1 caso'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
      'Il massimo è 9',
    );
    await tester.tap(find.text('Nascosto agli studenti'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Scrivi il maggiore tra due numeri.'), findsOneWidget);

    // La soluzione del docente supera il proprio caso.
    await tester.tap(find.text('Verifica'));
    await tester.pumpAndSettle();
    expect(find.text('Tutti i casi superati!'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Riaprendo la consegna, il caso è ancora lì, nascosto e modificabile.
    await tester.tap(find.text('Scrivi il maggiore tra due numeri.'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('docente: togliere l\'esercizio', (tester) async {
    final p = decodeProgram(File('assets/examples/massimo.flow').readAsStringSync())
        .withExercise(Exercise(text: 'Consegna di prova'));
    await pumpEditor(tester, p);
    await tester.tap(find.text('Consegna di prova'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Togli esercizio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Togli'));
    await tester.pumpAndSettle();
    expect(find.text('Consegna di prova'), findsNothing);
    expect(find.text('Verifica'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('niente esercizi nei diagrammi Arduino', (tester) async {
    await pumpEditor(tester, Program(name: 'Sketch', kind: ProgramKind.arduino));
    await tester.tap(find.byTooltip('Altro'));
    await tester.pumpAndSettle();
    expect(find.text('Crea esercizio'), findsNothing);
  });
}
