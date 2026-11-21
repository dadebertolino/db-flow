import 'dart:io';
import 'dart:math' as math;

import 'package:db_flow/app.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/settings.dart';
import 'package:db_flow/io/storage.dart';
import 'package:db_flow/layout/layout_engine.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/render/theme.dart';
import 'package:db_flow/ui/editor_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rapporto di contrasto WCAG tra due colori.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dbflow_theme');
    setLanguage(AppLanguage.it);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  group('colori del diagramma', () {
    for (final dc in [DiagramColors.light, DiagramColors.dark]) {
      final name = dc.isDark ? 'scuro' : 'chiaro';
      test('tema $name: testo leggibile su ogni blocco', () {
        for (final s in Shape.values) {
          final fill = dc.shape(s).fill;
          final text = dc.blockText(s).color!;
          expect(contrast(text, fill), greaterThanOrEqualTo(4.5), reason: '$s');
        }
      });
      test('tema $name: bordi, frecce e stati visibili sullo sfondo', () {
        for (final s in Shape.values) {
          expect(
            contrast(dc.shape(s).stroke, dc.background),
            greaterThanOrEqualTo(2.5),
            reason: '$s',
          );
        }
        for (final c in [dc.edge, dc.active, dc.selection, dc.error, dc.warning]) {
          expect(contrast(c, dc.background), greaterThanOrEqualTo(3), reason: '$c');
        }
      });
    }

    test('il tema scuro ha sfondi scuri, quello chiaro sfondi chiari', () {
      expect(DiagramColors.dark.background.computeLuminance(), lessThan(0.05));
      expect(DiagramColors.light.background.computeLuminance(), greaterThan(0.9));
      expect(appTheme(Brightness.dark).extension<DiagramColors>(), DiagramColors.dark);
      expect(appTheme(Brightness.light).extension<DiagramColors>(), DiagramColors.light);
    });
  });

  group('preferenza del tema', () {
    test('predefinito: come il dispositivo', () async {
      final s = AppSettings(baseDir: () async => tmp);
      await s.load();
      expect(s.themeMode, ThemeMode.system);
    });

    test('la scelta viene salvata e riletta', () async {
      final s = AppSettings(baseDir: () async => tmp);
      var notified = 0;
      s.addListener(() => notified++);
      await s.setThemeMode(ThemeMode.dark);
      expect(notified, 1);
      final again = AppSettings(baseDir: () async => tmp);
      await again.load();
      expect(again.themeMode, ThemeMode.dark);
    });

    test('un file illeggibile lascia il predefinito', () async {
      File('${tmp.path}/impostazioni.json').writeAsStringSync('{non json');
      final s = AppSettings(baseDir: () async => tmp);
      await s.load();
      expect(s.themeMode, ThemeMode.system);
    });
  });

  testWidgets('dal menu della home si passa al tema scuro', (tester) async {
    final settings = AppSettings(baseDir: () async => tmp);
    await tester.pumpWidget(
      DbFlowApp(
        storage: FlowStorage(baseDir: () async => tmp),
        settings: settings,
        locale: const Locale('it'),
        splashDuration: Duration.zero,
      ),
    );
    await tester.pump();
    BuildContext ctx() => tester.element(find.text('DB Flow'));
    expect(Theme.of(ctx()).brightness, Brightness.light);

    await tester.tap(find.byTooltip('Tema'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Scuro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(settings.themeMode, ThemeMode.dark);
    expect(Theme.of(ctx()).brightness, Brightness.dark);
    expect(DiagramColors.of(ctx()), DiagramColors.dark);
  });

  testWidgets("l'editor usa i colori scuri del diagramma", (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: EditorPage(
          file: File('${tmp.path}/t.flow'),
          program: Program(name: 'Prova'),
          storage: FlowStorage(baseDir: () async => tmp),
        ),
      ),
    );
    expect(find.text('Inizio'), findsOneWidget);
    final canvas = find.byWidgetPredicate(
      (w) => w is Container && w.color == DiagramColors.dark.background,
    );
    expect(canvas, findsOneWidget);
    final label = tester.widget<Text>(find.text('Inizio'));
    expect((label.style ?? label.textSpan?.style)?.color, DiagramColors.dark.text);
  });

  for (final b in Brightness.values) {
    testWidgets('telefono, tema ${b.name}: «Esegui» ha l\'icona chiara sul fondo pieno', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1320, 2868);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final theme = appTheme(b);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: EditorPage(
            file: File('${tmp.path}/t.flow'),
            program: Program(name: 'Prova'),
            storage: FlowStorage(baseDir: () async => tmp),
          ),
        ),
      );
      final icon = find.descendant(
        of: find.byTooltip('Esegui'),
        matching: find.byIcon(Icons.play_arrow),
      );
      final color = IconTheme.of(tester.element(icon)).color;
      final shown = tester.widget<Icon>(icon).color ?? color;
      expect(shown, theme.colorScheme.onPrimary);
      expect(contrast(shown!, theme.colorScheme.primary), greaterThanOrEqualTo(4.5));
    });
  }

  group('freccia «←» su Android', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('su Android la freccia usa il font dedicato, il resto no', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final span = arrowSpan('a ← b ← 1', blockTextStyle);
      expect(span.toPlainText(), 'a ← b ← 1');
      final arrows = span.children!.whereType<TextSpan>().where((c) => c.text == '←');
      expect(arrows, hasLength(2));
      expect(arrows.every((c) => c.style?.fontFamily == arrowFont), isTrue);
      final others = span.children!.whereType<TextSpan>().where((c) => c.text != '←');
      expect(others.every((c) => c.style == null), isTrue);
    });

    test('su iOS e macOS il testo resta semplice', () {
      for (final p in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = p;
        final span = arrowSpan('a ← b', blockTextStyle);
        expect(span.children, isNull);
        expect(span.text, 'a ← b');
      }
    });

    test('il font è dichiarato nel pubspec', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/fonts/DBFlowArrow.ttf'));
      expect(File('assets/fonts/DBFlowArrow.ttf').existsSync(), isTrue);
    });
  });
}
