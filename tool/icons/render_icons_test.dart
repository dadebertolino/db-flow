// Genera le immagini sorgente di icona e splash in assets/icon/.
//
//   flutter test tool/icons/render_icons_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// Il disegno è originale: un piccolo diagramma di flusso (inizio, decisione,
// due rami che si ricongiungono) su sfondo blu.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const blueLight = Color(0xFF2E74C9);
const blueDark = Color(0xFF173D78);
const amber = Color(0xFFFFC24B);
const white = Color(0xFFFFFFFF);

/// Disegna il logo in un quadrato di lato [side]. [scale] < 1 lascia margine
/// (zone di sicurezza delle icone adattive e dello splash di Android 12).
void paintLogo(Canvas canvas, double side, {bool background = true, double scale = 1}) {
  if (background) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(side, side), [blueLight, blueDark]),
    );
  }
  canvas.save();
  canvas.translate(side / 2, side / 2);
  canvas.scale(scale * side / 1024);
  canvas.translate(-512, -512);

  final stroke = Paint()
    ..color = white
    ..strokeWidth = 30
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final fillWhite = Paint()..color = white;

  void arrowHead(Offset tip) {
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 34, tip.dy - 46)
        ..lineTo(tip.dx + 34, tip.dy - 46)
        ..close(),
      fillWhite,
    );
  }

  // inizio
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(512, 190), width: 330, height: 124),
      const Radius.circular(62),
    ),
    fillWhite,
  );
  canvas.drawLine(const Offset(512, 252), const Offset(512, 318), stroke);
  arrowHead(const Offset(512, 350));

  // decisione
  const top = 350.0, mid = 470.0, bottom = 590.0, half = 180.0;
  final diamond = Path()
    ..moveTo(512, top)
    ..lineTo(512 + half, mid)
    ..lineTo(512, bottom)
    ..lineTo(512 - half, mid)
    ..close();
  canvas.drawPath(diamond, Paint()..color = amber);
  canvas.drawPath(diamond, stroke..color = white);

  // rami
  const left = 236.0, right = 788.0, boxTop = 640.0, boxH = 104.0, boxW = 196.0;
  for (final x in [left, right]) {
    final fromX = x < 512 ? 512 - half : 512 + half;
    canvas.drawPath(
      Path()
        ..moveTo(fromX, mid)
        ..lineTo(x, mid)
        ..lineTo(x, boxTop - 40),
      stroke,
    );
    arrowHead(Offset(x, boxTop - 4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - boxW / 2, boxTop, boxW, boxH),
        const Radius.circular(16),
      ),
      fillWhite,
    );
  }
  // ricongiungimento
  const join = 838.0;
  canvas.drawPath(
    Path()
      ..moveTo(left, boxTop + boxH)
      ..lineTo(left, join)
      ..lineTo(right, join)
      ..lineTo(right, boxTop + boxH),
    stroke,
  );
  canvas.drawCircle(const Offset(512, join), 26, fillWhite);
  canvas.drawLine(const Offset(512, join), const Offset(512, 880), stroke);
  canvas.restore();
}

Future<void> _save(String path, double side, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(side.toInt(), side.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
  image.dispose();
}

void main() {
  testWidgets('genera icone e splash', (tester) async {
    await tester.runAsync(() async {
      // icona completa (iOS e Android legacy)
      await _save('assets/icon/icon.png', 1024, (c) => paintLogo(c, 1024));
      // macOS: quadrato arrotondato con margine e ombra, come le icone di sistema
      // (griglia Apple: forma di 824 px su 1024, raggio ~185 px)
      await _save('assets/icon/icon_macos.png', 1024, (c) {
        final shape = RRect.fromRectAndRadius(
          const Rect.fromLTWH(100, 100, 824, 824),
          const Radius.circular(185),
        );
        c.drawRRect(
          shape.shift(const Offset(0, 10)),
          Paint()
            ..color = const Color(0x4D000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
        c.save();
        c.clipRRect(shape);
        c.translate(100, 100);
        paintLogo(c, 824);
        c.restore();
      });
      // primo piano dell'icona adattiva Android: contenuto nella zona sicura (~66%)
      await _save(
        'assets/icon/icon_foreground.png',
        1024,
        (c) => paintLogo(c, 1024, background: false, scale: 0.62),
      );
      // logo dello splash (sfondo blu fornito dal colore dello splash)
      await _save(
        'assets/icon/splash.png',
        768,
        (c) => paintLogo(c, 768, background: false, scale: 0.9),
      );
      // Android 12+: l'immagine viene ritagliata in un cerchio, il logo sta nei 2/3 centrali
      await _save(
        'assets/icon/splash_android12.png',
        1152,
        (c) => paintLogo(c, 1152, background: false, scale: math.sqrt(0.5) * 0.66 / 0.7),
      );
    });
    expect(File('assets/icon/icon.png').existsSync(), isTrue);
  });
}
