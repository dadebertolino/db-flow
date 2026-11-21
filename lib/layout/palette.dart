/// Colori e geometria delle forme, condivisi da canvas, PNG e SVG. Dart puro.
library;

import 'layout_engine.dart';
import 'metrics.dart';

/// Colori ARGB per tipo di blocco: riempimento chiaro e bordo saturo.
({int fill, int stroke}) shapeColorValues(Shape s) => switch (s) {
  Shape.terminal => (fill: 0xFFDDF3E4, stroke: 0xFF2E7D4F),
  Shape.process => (fill: 0xFFE3EEFB, stroke: 0xFF1F5FAD),
  Shape.declare => (fill: 0xFFEEE8F8, stroke: 0xFF6A4BB0),
  Shape.io => (fill: 0xFFFFF1D6, stroke: 0xFFB36B00),
  Shape.decision => (fill: 0xFFFDE4E1, stroke: 0xFFB03A2E),
  Shape.loop => (fill: 0xFFDFF3F2, stroke: 0xFF13807F),
  Shape.comment => (fill: 0xFFF4F4F4, stroke: 0xFF9E9E9E),
  Shape.hardware => (fill: 0xFFDDF1F2, stroke: 0xFF00777C),
  Shape.pinIo => (fill: 0xFFDDF1F2, stroke: 0xFF00777C),
};

/// Variante per il tema scuro: riempimento scuro e bordo chiaro, stessa tinta.
({int fill, int stroke}) shapeColorValuesDark(Shape s) => switch (s) {
  Shape.terminal => (fill: 0xFF1D3828, stroke: 0xFF6FCF97),
  Shape.process => (fill: 0xFF1A2D47, stroke: 0xFF7FB2F0),
  Shape.declare => (fill: 0xFF2A2444, stroke: 0xFFB39DDB),
  Shape.io => (fill: 0xFF3B2C10, stroke: 0xFFFFB74D),
  Shape.decision => (fill: 0xFF40211D, stroke: 0xFFEF8A80),
  Shape.loop => (fill: 0xFF133635, stroke: 0xFF4DD0C8),
  Shape.comment => (fill: 0xFF2A2A2A, stroke: 0xFF8A8A8A),
  Shape.hardware => (fill: 0xFF113537, stroke: 0xFF4DC3C9),
  Shape.pinIo => (fill: 0xFF113537, stroke: 0xFF4DC3C9),
};

const edgeColorValue = 0xFF455A64;
const errorColorValue = 0xFFD32F2F;
const activeColorValue = 0xFF2E9D4F;

/// Vertici del poligono della forma (in coordinate locali `0..w`, `0..h`);
/// `null` per le forme arrotondate (inizio/fine e commento).
List<Pt>? shapePolygon(Shape shape, double w, double h, {double? skew, double? hexInset}) {
  const m = Metrics();
  final sk = skew ?? m.skew;
  final i = hexInset ?? m.hexInset;
  return switch (shape) {
    Shape.process || Shape.declare || Shape.hardware => [Pt(0, 0), Pt(w, 0), Pt(w, h), Pt(0, h)],
    Shape.io || Shape.pinIo => [Pt(sk, 0), Pt(w, 0), Pt(w - sk, h), Pt(0, h)],
    Shape.decision => [Pt(w / 2, 0), Pt(w, h / 2), Pt(w / 2, h), Pt(0, h / 2)],
    Shape.loop => [Pt(i, 0), Pt(w - i, 0), Pt(w, h / 2), Pt(w - i, h), Pt(i, h), Pt(0, h / 2)],
    Shape.terminal || Shape.comment => null,
  };
}

/// Raggio degli angoli per le forme arrotondate.
double shapeCornerRadius(Shape shape, double h) => shape == Shape.terminal ? h / 2 : 6;
