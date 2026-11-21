/// Export SVG generato direttamente dal layout (nessuna dipendenza). Dart puro.
library;

import '../layout/layout_engine.dart';
import '../layout/palette.dart';

String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _n(double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

String diagramSvg(DiagramLayout l, {String? title}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="${_n(l.width)}" height="${_n(l.height)}" '
      'viewBox="0 0 ${_n(l.width)} ${_n(l.height)}" '
      'font-family="Helvetica, Arial, sans-serif">',
    );
  if (title != null) b.writeln('  <title>${_esc(title)}</title>');
  final edge = _hex(edgeColorValue);
  b
    ..writeln(
      '  <defs><marker id="freccia" viewBox="0 0 10 10" refX="10" refY="5" '
      'markerWidth="9" markerHeight="9" markerUnits="userSpaceOnUse" orient="auto">'
      '<path d="M0,0 L10,5 L0,10 z" fill="$edge"/></marker></defs>',
    )
    ..writeln('  <rect width="100%" height="100%" fill="#ffffff"/>');

  for (final e in l.edges) {
    final pts = e.points.map((p) => '${_n(p.x)},${_n(p.y)}').join(' ');
    b.writeln(
      '  <polyline points="$pts" fill="none" stroke="$edge" stroke-width="1.6" '
      'stroke-linejoin="round"${e.arrow ? ' marker-end="url(#freccia)"' : ''}/>',
    );
  }
  for (final d in l.dots) {
    b.writeln('  <circle cx="${_n(d.x)}" cy="${_n(d.y)}" r="3.5" fill="$edge"/>');
  }
  for (final t in l.labels) {
    b.writeln(
      '  <text x="${_n(t.at.x)}" y="${_n(t.at.y)}" font-size="12" font-weight="600" fill="$edge" '
      'text-anchor="middle" dominant-baseline="central">${_esc(t.text)}</text>',
    );
  }
  for (final box in l.boxes) {
    final c = shapeColorValues(box.shape);
    final style = 'fill="${_hex(c.fill)}" stroke="${_hex(c.stroke)}" stroke-width="1.6"';
    final poly = shapePolygon(box.shape, box.w, box.h);
    if (poly == null) {
      final r = _n(shapeCornerRadius(box.shape, box.h));
      b.writeln(
        '  <rect x="${_n(box.x)}" y="${_n(box.y)}" width="${_n(box.w)}" height="${_n(box.h)}" '
        'rx="$r" $style/>',
      );
    } else {
      final pts = poly.map((p) => '${_n(box.x + p.x)},${_n(box.y + p.y)}').join(' ');
      b.writeln('  <polygon points="$pts" $style stroke-linejoin="round"/>');
    }
    if (box.shape == Shape.declare) {
      final s = _hex(c.stroke);
      b
        ..writeln(
          '  <line x1="${_n(box.x + 8)}" y1="${_n(box.y)}" x2="${_n(box.x + 8)}" '
          'y2="${_n(box.bottom)}" stroke="$s" stroke-width="1.2"/>',
        )
        ..writeln(
          '  <line x1="${_n(box.x)}" y1="${_n(box.y + 8)}" x2="${_n(box.right)}" '
          'y2="${_n(box.y + 8)}" stroke="$s" stroke-width="1.2"/>',
        );
    }
    final italic = box.shape == Shape.comment ? ' font-style="italic" fill="#616161"' : '';
    b.writeln(
      '  <text x="${_n(box.center.x)}" y="${_n(box.center.y)}" font-size="14" font-weight="500" '
      'text-anchor="middle" dominant-baseline="central"$italic>${_esc(box.label)}</text>',
    );
  }
  b.writeln('</svg>');
  return b.toString();
}
