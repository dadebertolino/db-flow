import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/layout_engine.dart';
import 'theme.dart';

/// Disegna frecce, punti di ricongiungimento ed etichette vero/falso.
class EdgePainter extends CustomPainter {
  EdgePainter(this.layout, {this.colors = DiagramColors.light});

  final DiagramLayout layout;
  final DiagramColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = colors.edge
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = colors.edge;

    for (final e in layout.edges) {
      final pts = e.points;
      final path = Path()..moveTo(pts.first.x, pts.first.y);
      for (final p in pts.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, line);
      if (e.arrow && pts.length >= 2) _arrowHead(canvas, pts[pts.length - 2], pts.last, fill);
    }

    for (final d in layout.dots) {
      canvas.drawCircle(Offset(d.x, d.y), 3.5, fill);
    }

    for (final l in layout.labels) {
      final tp = TextPainter(
        text: TextSpan(text: l.text, style: colors.edgeLabel),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(l.at.x - tp.width / 2, l.at.y - tp.height / 2));
    }
  }

  void _arrowHead(Canvas canvas, Pt from, Pt to, Paint paint) {
    const len = 9.0, half = 4.5;
    final angle = math.atan2(to.y - from.y, to.x - from.x);
    final tip = Offset(to.x, to.y);
    Offset rot(double dx, double dy) => Offset(
      tip.dx + dx * math.cos(angle) - dy * math.sin(angle),
      tip.dy + dx * math.sin(angle) + dy * math.cos(angle),
    );
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(rot(-len, -half).dx, rot(-len, -half).dy)
        ..lineTo(rot(-len, half).dx, rot(-len, half).dy)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(EdgePainter old) => !identical(old.layout, layout) || old.colors != colors;
}
