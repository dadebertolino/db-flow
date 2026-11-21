import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../i18n/tr.dart';

/// Nome di file sicuro a partire dal nome del diagramma.
String safeFileName(String name) {
  final s = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
  return s.isEmpty ? tr.defaultFileName : (s.length > 80 ? s.substring(0, 80) : s);
}

/// Rettangolo del widget [context], necessario su iPad per il menu di condivisione.
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Computer (macOS, Windows, Linux): al posto della condivisione si salva il
/// file dove sceglie l'utente.
bool get isDesktop => switch (defaultTargetPlatform) {
  TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux => true,
  _ => false,
};

/// Scrive [bytes] in un file temporaneo e apre il menu di condivisione del sistema.
/// Il file passa direttamente all'app scelta dall'utente (Mail, AirDrop, File…).
/// Su computer apre invece la finestra "Salva con nome".
Future<void> shareBytes(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
  Rect? origin,
}) async {
  if (isDesktop) {
    await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType);
    return;
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mimeType)],
      sharePositionOrigin: origin,
    ),
  );
}

Future<void> shareText(String text, {Rect? origin}) =>
    SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));

/// Nome valido per uno sketch Arduino (e per la sua cartella): lettere senza
/// accenti, cifre, `_`, `-` e `.`; inizia con una lettera o una cifra; al
/// massimo 63 caratteri.
String sketchName(String name) {
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', //
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n', 'ß': 'ss',
  };
  var s = [for (final c in name.trim().split('')) accents[c.toLowerCase()] ?? c].join();
  s = s
      .replaceAll(RegExp(r'[^A-Za-z0-9_.\-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[_.\-]+|[_.\-]+$'), '');
  if (s.isEmpty) return 'sketch';
  return s.length > 63 ? s.substring(0, 63) : s;
}

/// Sketch per l'Arduino IDE. Su computer chiede una cartella e crea
/// `<nome>/<nome>.ino` (l'IDE vuole lo sketch in una cartella con lo stesso
/// nome) e restituisce il percorso; altrove condivide il file `.ino`, e l'IDE,
/// aprendolo, propone di creare la cartella.
Future<String?> saveArduinoSketch(String code, String name, {Rect? origin}) async {
  final sketch = sketchName(name);
  if (!isDesktop) {
    await shareBytes(
      utf8.encode(code),
      fileName: '$sketch.ino',
      mimeType: 'text/plain',
      origin: origin,
    );
    return null;
  }
  final base = await FilePicker.getDirectoryPath(dialogTitle: tr.chooseSketchFolder);
  if (base == null) return null;
  final sep = Platform.pathSeparator;
  final dir = Directory('$base$sep$sketch');
  await dir.create(recursive: true);
  final file = File('${dir.path}$sep$sketch.ino');
  await file.writeAsString(code, flush: true);
  return file.path;
}
