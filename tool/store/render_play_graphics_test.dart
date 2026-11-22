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

  // Microsoft Store (Partner Center › Schede dello Store › Logo dello Store e
  // immagini promozionali), in build/store/microsoft/: tutte opache.
  testWidgets('genera la grafica del Microsoft Store', (tester) async {
    await tester.runAsync(() async {
      await _loadRoboto();
      const out = 'build/store/microsoft';
      void background(Canvas c, double w, double h) => c.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(w, h), [blueLight, blueDark]),
      );
      void centered(
        Canvas c,
        String s,
        double y,
        double size,
        FontWeight weight,
        Color color,
        double w,
      ) {
        final p = TextPainter(
          text: TextSpan(
            text: s,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: size,
              fontWeight: weight,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 2,
        )..layout(minWidth: w * 0.84, maxWidth: w * 0.84);
        p.paint(c, Offset(w * 0.08, y));
      }

      // icona del riquadro 300×300 e box art 1:1 2160×2160: uguali in ogni lingua
      await _save('$out/tile-300.png', 300, 300, opaque: true, (c) => paintLogo(c, 300));
      await _save('$out/box-art-2160.png', 2160, 2160, opaque: true, (c) {
        background(c, 2160, 2160);
        c.save();
        c.translate(380, 200);
        paintLogo(c, 1400, background: false, scale: 0.95);
        c.restore();
        centered(c, 'DB Flow', 1640, 260, FontWeight.bold, white, 2160);
      });

      for (final MapEntry(key: lang, value: tagline) in _taglines.entries) {
        // poster 2:3, 1440×2160
        await _save('$out/poster-$lang.png', 1440, 2160, opaque: true, (c) {
          background(c, 1440, 2160);
          c.save();
          c.translate(220, 180);
          paintLogo(c, 1000, background: false, scale: 0.95);
          c.restore();
          centered(c, 'DB Flow', 1240, 200, FontWeight.bold, white, 1440);
          centered(c, tagline, 1500, 84, FontWeight.w500, white, 1440);
          centered(c, 'Python · C · Arduino', 1820, 72, FontWeight.w500, amber, 1440);
        });
        // immagine 16:9, 3840×2160 (come la grafica di Google Play, più grande)
        await _save('$out/hero-$lang.png', 3840, 2160, opaque: true, (c) {
          background(c, 3840, 2160);
          c.save();
          c.translate(240, 300);
          paintLogo(c, 1560, background: false, scale: 0.95);
          c.restore();
          const x = 1960.0, w = 1700.0;
          _text(c, 'DB Flow', const Offset(x, 560), 360, FontWeight.bold, white, w);
          _text(c, tagline, const Offset(x, 1000), 140, FontWeight.w500, white, w);
          _text(c, 'Python · C · Arduino', const Offset(x, 1420), 120, FontWeight.w500, amber, w);
        });
      }
    });
  });
}
