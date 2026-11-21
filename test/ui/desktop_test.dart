import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/share.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/ui/editor_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dbflow_desk');
    setLanguage(AppLanguage.it);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pumpMassimo(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(
          file: File('${tmp.path}/t.flow'),
          program: decodeProgram(File('assets/examples/massimo.flow').readAsStringSync()),
          storage: FlowStorage(baseDir: () async => tmp),
        ),
      ),
    );
    await tester.pump();
  }

  test('computer o dispositivo mobile', () {
    for (final (p, desktop) in [
      (TargetPlatform.macOS, true),
      (TargetPlatform.windows, true),
      (TargetPlatform.linux, true),
      (TargetPlatform.iOS, false),
      (TargetPlatform.android, false),
    ]) {
      debugDefaultTargetPlatformOverride = p;
      expect(isDesktop, desktop, reason: '$p');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tastiera: Canc elimina il blocco selezionato, Ctrl+Z lo ripristina', (tester) async {
    await pumpMassimo(tester);
    await tester.tap(find.text('Leggi a'));
    await tester.pump(kDoubleTapTimeout * 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.text('Leggi a'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('Leggi a'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(find.text('Leggi a'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tastiera: Esc deseleziona, Invio apre la modifica', (tester) async {
    await pumpMassimo(tester);
    await tester.tap(find.text('Leggi b'));
    await tester.pump(kDoubleTapTimeout * 2);
    expect(find.byTooltip('Elimina'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byTooltip('Elimina'), findsNothing);

    await tester.tap(find.text('Leggi b'));
    await tester.pump(kDoubleTapTimeout * 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('clic destro su un blocco lo seleziona', (tester) async {
    await pumpMassimo(tester);
    await tester.tap(find.text('Leggi a'), buttons: kSecondaryButton);
    await tester.pump();
    expect(find.byTooltip('Elimina'), findsOneWidget);
  });
}
