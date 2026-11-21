import 'dart:convert';
import 'dart:io';

import 'package:db_flow/codegen/generator.dart';
import 'package:db_flow/io/export_pdf.dart';
import 'package:db_flow/io/export_png.dart';
import 'package:db_flow/io/export_svg.dart';
import 'package:db_flow/io/share.dart';
import 'package:db_flow/layout/layout_engine.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final program = decodeProgram(File('assets/examples/primo.flow').readAsStringSync());
  final layout = layoutProgram(program);

  test('SVG: una forma e un testo per ogni blocco, testo con caratteri speciali', () {
    final svg = diagramSvg(layout, title: 'Primo <prova> & co');
    expect(svg, startsWith('<?xml'));
    expect(svg.trim(), endsWith('</svg>'));
    final shapes = RegExp('<(polygon|rect x=)').allMatches(svg).length;
    expect(shapes, layout.boxes.length);
    expect(svg, contains('<title>Primo &lt;prova&gt; &amp; co</title>'));
    expect(svg, contains('n &amp; &quot; è primo&quot;'));
    expect(svg, contains('marker-end="url(#freccia)"'));
  });

  test('PDF: documento valido con pagina del codice', () async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
    );
    final bytes = await diagramPdf(
      title: 'Numero primo',
      png: png,
      code: generateCode(program, CodeLanguage.pseudo),
      codeTitle: 'Pseudocodice',
    );
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('PDF: simboli non disponibili nei font standard', () {
    expect(pdfSafe('a ← b'), 'a <- b');
    expect(pdfSafe('città'), 'città');
    expect(pdfSafe('ok 👍'), 'ok ?');
  });

  testWidgets('PNG: immagine valida', (tester) async {
    final bytes = await tester.runAsync(() => diagramPng(layout, pixelRatio: 1));
    expect(bytes!.sublist(1, 4), ascii.encode('PNG'));
  });

  test('nomi di file sicuri', () {
    expect(safeFileName('Media: a/b?'), 'Media_ a_b_');
    expect(safeFileName('   '), 'diagramma');
  });
}
