import 'package:flutter/material.dart';

import '../layout/layout_engine.dart';
import 'block_widget.dart';
import 'edge_painter.dart';
import 'theme.dart';

/// Disegna l'intero diagramma su un [Canvas] (senza "+" e senza selezione).
/// Usato per l'export PNG/PDF, sempre con i colori chiari.
void paintDiagram(Canvas canvas, DiagramLayout layout) {
  const dc = DiagramColors.light;
  EdgePainter(layout).paint(canvas, Size(layout.width, layout.height));
  for (final b in layout.boxes) {
    canvas.save();
    canvas.translate(b.x, b.y);
    final size = Size(b.w, b.h);
    final colors = dc.shape(b.shape);
    paintBlockShape(canvas, size, b.shape, fill: colors.fill, stroke: colors.stroke);
    final tp = TextPainter(
      text: arrowSpan(b.label, dc.blockText(b.shape)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, Offset((b.w - tp.width) / 2, (b.h - tp.height) / 2));
    canvas.restore();
  }
}
