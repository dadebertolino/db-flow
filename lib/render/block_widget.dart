import 'package:flutter/material.dart';

import '../layout/layout_engine.dart';
import '../layout/palette.dart';
import 'theme.dart';

/// Percorso della forma [shape] in un rettangolo [size].
Path shapePath(Shape shape, Size size, {double? skew, double? hexInset}) {
  final poly = shapePolygon(shape, size.width, size.height, skew: skew, hexInset: hexInset);
  if (poly == null) {
    final r = shapeCornerRadius(shape, size.height);
    return Path()..addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, Radius.circular(r)));
  }
  final p = Path()..moveTo(poly.first.x, poly.first.y);
  for (final pt in poly.skip(1)) {
    p.lineTo(pt.x, pt.y);
  }
  return p..close();
}

/// Disegna la forma di un blocco (riempimento, bordo, eventuale alone).
void paintBlockShape(
  Canvas canvas,
  Size size,
  Shape shape, {
  required Color fill,
  required Color stroke,
  double strokeWidth = 1.6,
  Color? halo,
}) {
  final path = shapePath(shape, size);
  if (halo != null) {
    canvas.drawPath(
      path,
      Paint()
        ..color = halo.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeJoin = StrokeJoin.round,
    );
  }
  canvas.drawPath(path, Paint()..color = fill);
  canvas.drawPath(
    path,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round,
  );
  if (shape == Shape.declare) {
    // simbolo "memoria interna": doppia linea a sinistra e in alto
    final thin = Paint()
      ..color = stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(8, 0), Offset(8, size.height), thin);
    canvas.drawLine(const Offset(0, 8), Offset(size.width, 8), thin);
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.stroke, this.strokeWidth, this.fill, this.halo);

  final Shape shape;
  final Color stroke;
  final double strokeWidth;
  final Color fill;
  final Color? halo;

  @override
  void paint(Canvas canvas, Size size) => paintBlockShape(
    canvas,
    size,
    shape,
    fill: fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
    halo: halo,
  );

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.fill != fill ||
      old.halo != halo;
}

/// Un blocco del diagramma: forma + testo.
class BlockWidget extends StatelessWidget {
  const BlockWidget({
    super.key,
    required this.box,
    this.selected = false,
    this.hasError = false,
    this.active = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final LayoutBox box;
  final bool selected;
  final bool hasError;

  /// Blocco in esecuzione.
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dc = DiagramColors.of(context);
    final colors = dc.shape(box.shape);
    final stroke = hasError
        ? dc.error
        : active
        ? dc.active
        : selected
        ? dc.selection
        : colors.stroke;
    final halo = active
        ? dc.active
        : selected
        ? dc.selection
        : null;
    return Semantics(
      button: onTap != null,
      label: box.label,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        child: CustomPaint(
          painter: _ShapePainter(
            box.shape,
            stroke,
            selected || hasError || active ? 2.6 : 1.6,
            colors.fill,
            halo,
          ),
          child: Center(
            child: Text.rich(
              arrowSpan(box.label, dc.blockText(box.shape)),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}
