import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/incoming.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Archivio in memoria: nei test di widget l'I/O reale avviato dall'app non termina.
class MemoryStorage extends FlowStorage {
  final saved = <Program>[];

  @override
  Future<List<StoredFlow>> list() async => [
    for (final (i, p) in saved.indexed) StoredFlow(File('$i.flow'), p.name, DateTime(2026)),
  ];

  @override
  Future<File> create(Program p) async {
    saved.add(p);
    return File('${saved.length - 1}.flow');
  }

  @override
  Future<void> save(File file, Program p) async {}
}

void main() {
  late Directory tmp;
  const channel = MethodChannel('dbflow/files');
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dbflow_in');
    setLanguage(AppLanguage.it);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
    tmp.deleteSync(recursive: true);
  });

  Future<MemoryStorage> pumpHome(WidgetTester tester, IncomingFiles incoming) async {
    final storage = MemoryStorage();
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(storage: storage, incoming: incoming),
      ),
    );
    // lettura dei file e salvataggio della copia: I/O reale
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    return storage;
  }

  testWidgets('un file ricevuto prima dell\'avvio si apre come copia', (tester) async {
    final text = File('assets/exercises/somma.flow').readAsStringSync();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'pending' ? [text] : null,
    );
    final storage = await pumpHome(tester, IncomingFiles());
    expect(find.textContaining('Leggi due numeri interi'), findsOneWidget, reason: 'editor aperto');
    expect(storage.saved.single.name, 'Somma di due numeri');
  });

  testWidgets('Windows: il file passato come argomento si apre', (tester) async {
    final path = '${tmp.path}/prova.flow';
    File(path).writeAsStringSync(File('assets/examples/mcd.flow').readAsStringSync());
    await pumpHome(tester, IncomingFiles(launchArgs: ['--altro', path]));
    expect(find.text('MCD (algoritmo di Euclide)'), findsOneWidget);
    expect(find.byTooltip('Annulla'), findsOneWidget, reason: 'editor aperto');
  });

  testWidgets('un file che non è un diagramma viene rifiutato', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'pending' ? ['ciao, non sono JSON'] : null,
    );
    await pumpHome(tester, IncomingFiles());
    expect(find.text(tr.importFailed(tr.fileDamaged)), findsOneWidget);
  });
}
