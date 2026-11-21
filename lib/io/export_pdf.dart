import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../i18n/tr.dart';

/// I font standard del PDF coprono solo l'alfabeto latino di base: si
/// sostituiscono i simboli non disponibili.
String pdfSafe(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    b.write(switch (r) {
      0x2190 => '<-', // ←
      0x2192 => '->',
      0x2026 => '...',
      0x2018 || 0x2019 => "'",
      0x201C || 0x201D => '"',
      < 0x100 => String.fromCharCode(r),
      _ => '?',
    });
  }
  return b.toString();
}

/// PDF A4: prima pagina con titolo e diagramma, poi (se c'è) il codice.
Future<Uint8List> diagramPdf({
  required String title,
  required Uint8List png,
  String? code,
  String? codeTitle,
  Uint8List? wiringPng,
  List<String> wiringLines = const [],
}) async {
  final doc = pw.Document(title: pdfSafe(title), creator: 'DB Flow');
  final image = pw.MemoryImage(png);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            pdfSafe(title),
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Expanded(
            child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        ],
      ),
    ),
  );
  if (wiringPng != null) {
    final wiring = pw.MemoryImage(wiringPng);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              tr.pdfWiring,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Image(wiring, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 16),
            for (final l in wiringLines)
              pw.Text(pdfSafe(l), style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
  if (code != null) {
    final lines = pdfSafe(code).split('\n');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text(
            pdfSafe(codeTitle ?? tr.pdfCode),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          for (final l in lines)
            pw.Text(
              l.isEmpty ? ' ' : l,
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
        ],
      ),
    );
  }
  return doc.save();
}
