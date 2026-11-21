// Grafica per la scheda Google Play, in build/store/play/ (non in git):
// icona 512×512 e grafica in primo piano 1024×500 in cinque lingue.
//
//   flutter test tool/store/render_play_graphics_test.dart
//
// Il logo è quello di tool/icons/render_icons_test.dart; il testo usa Roboto
// (licenza Apache 2.0), presa dalla cache dell'SDK di Flutter.
//
// La grafica in primo piano è un PNG RGB a 24 bit, senza canale alfa: Google
// la rifiuta con l'alfa (e dart:ui scrive solo PNG RGBA). L'icona resta a 32 bit.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../icons/render_icons_test.dart' show amber, blueDark, blueLight, paintLogo, white;

const _out = 'build/store/play';

/// Sottotitoli della scheda App Store (store/app-store.md), uguali in ogni lingua.
const _taglines = {
  'it': 'Diagrammi di flusso eseguibili',
  'en': 'Flowcharts you can run',
  'fr': 'Organigrammes exécutables',
  'de': 'Ausführbare Ablaufpläne',
  'es': 'Diagramas de flujo ejecutables',
};

Future<void> _save(
  String path,
  int w,
  int h,
  void Function(Canvas) paint, {
  bool opaque = false,
}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(w, h);
  final Uint8List bytes;
  if (opaque) {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    bytes = _pngRgb(rgba!.buffer.asUint8List(), w, h);
  } else {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = png!.buffer.asUint8List();
  }
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  image.dispose();
}

/// PNG RGB a 8 bit per canale (tipo di colore 2), senza alfa.
Uint8List _pngRgb(Uint8List rgba, int w, int h) {
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // nessun filtro
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      raw.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  final out = BytesBuilder()..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final body = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(body)
      ..add(_u32(_crc32(body)));
  }

  chunk('IHDR', [..._u32(w), ..._u32(h), 8, 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes()));
  chunk('IEND', []);
  return out.takeBytes();
}

List<int> _u32(int v) => [v >> 24 & 0xFF, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF];

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}

Future<void> _loadRoboto() async {
  final fonts = '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('$fonts/Roboto-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void _text(
  Canvas c,
  String s,
  Offset at,
  double size,
  FontWeight weight,
  Color color,
  double maxW,
) {
  final p = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 2,
  )..layout(maxWidth: maxW);
  p.paint(c, at);
}

void main() {
  testWidgets('genera la grafica di Google Play', (tester) async {
    await tester.runAsync(() async {
      await _loadRoboto();
      // icona: 512×512, piena (Google applica da sé la maschera arrotondata)
      await _save('$_out/icon-512.png', 512, 512, (c) => paintLogo(c, 512));

      for (final MapEntry(key: lang, value: tagline) in _taglines.entries) {
        await _save('$_out/feature-graphic-$lang.png', 1024, 500, opaque: true, (c) {
          c.drawRect(
            const Rect.fromLTWH(0, 0, 1024, 500),
            Paint()
              ..shader = ui.Gradient.linear(Offset.zero, const Offset(1024, 500), [
                blueLight,
                blueDark,
              ]),
          );
          c.save();
          c.translate(40, 30);
          paintLogo(c, 440, background: false, scale: 0.95);
          c.restore();
          const x = 500.0, w = 480.0;
          _text(c, 'DB Flow', const Offset(x, 120), 104, FontWeight.bold, white, w);
          _text(c, tagline, const Offset(x, 252), 40, FontWeight.w500, white, w);
          _text(c, 'Python · C · Arduino', const Offset(x, 370), 34, FontWeight.w500, amber, w);
        });
      }
    });
  });
}
