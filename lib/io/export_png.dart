import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../arduino/board.dart';
import '../layout/layout_engine.dart';
import '../render/board_painter.dart';
import '../render/diagram_painter.dart';

/// Immagine PNG del diagramma su sfondo bianco. [pixelRatio] 3 come da guida,
/// ridotto se l'immagine supererebbe [maxSide] pixel per lato.
Future<Uint8List> diagramPng(
  DiagramLayout layout, {
  double pixelRatio = 3,
  double maxSide = 8000,
}) async {
  final scale = math.min(pixelRatio, maxSide / math.max(layout.width, layout.height));
  final w = (layout.width * scale).ceil(), h = (layout.height * scale).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  canvas.drawRect(Offset.zero & Size(layout.width, layout.height), Paint()..color = Colors.white);
  paintDiagram(canvas, layout);
  final image = await recorder.endRecording().toImage(w, h);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Disegno della scheda con i collegamenti, largo [width] pixel. `null` se la
/// scheda non ha un disegno.
Future<Uint8List?> boardPng(ArduinoConfig config, {double width = 1800, String? fontFamily}) async {
  final d = config.board.drawing;
  if (d == null) return null;
  final size = Size(width, width / BoardPainter.aspectRatio(d));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  BoardPainter(config, fontFamily: fontFamily).paint(canvas, size);
  final image = await recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
