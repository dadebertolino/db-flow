/// Layout automatico: AST → forme, frecce e punti di inserimento in coordinate
/// assolute. Nessuna posizione viene salvata: il layout si ricalcola dall'AST.
/// Dart puro.
///
/// Due passate: [_Engine._ext] misura ogni blocco (estensione a sinistra e a
/// destra dell'asse verticale, altezza); [_Engine._place] lo posiziona.
library;

import 'dart:math' as math;

import '../i18n/tr.dart';
import '../model/program.dart';
import '../model/slot.dart';
import '../model/stmt.dart';
import 'labels.dart';
import 'metrics.dart';

enum Shape {
  /// Ovale (inizio/fine).
  terminal,

  /// Rettangolo (assegnazione).
  process,

  /// Rettangolo con doppio bordo (dichiarazione).
  declare,

  /// Parallelogramma (input/output).
  io,

  /// Rombo (se, mentre, ripeti-mentre).
  decision,

  /// Esagono (per).
  loop,

  /// Nota (commento).
  comment,

  /// Rettangolo Arduino (delay).
  hardware,

  /// Parallelogramma Arduino: ingresso/uscita su un pin (digitalRead/Write, analogRead/Write).
  pinIo,
}

const startId = '#inizio';
const endId = '#fine';

/// Intestazione di `loop()` nei diagrammi Arduino.
const loopId = '#loop';

final class Pt {
  const Pt(this.x, this.y);
  final double x;
  final double y;

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

final class LayoutBox {
  const LayoutBox(this.id, this.shape, this.x, this.y, this.w, this.h, this.label);

  /// Id del blocco, oppure [startId] / [endId].
  final String id;
  final Shape shape;
  final double x;
  final double y;
  final double w;
  final double h;
  final String label;

  double get right => x + w;
  double get bottom => y + h;
  Pt get center => Pt(x + w / 2, y + h / 2);
}

/// Spezzata; [arrow] → punta di freccia sull'ultimo punto.
final class LayoutEdge {
  LayoutEdge(List<Pt> points, {this.arrow = false}) : points = List.unmodifiable(points);
  final List<Pt> points;
  final bool arrow;
}

/// Etichetta di un'uscita ("vero"/"falso"), centrata in [at].
final class LayoutLabel {
  const LayoutLabel(this.at, this.text);
  final Pt at;
  final String text;
}

/// Punto "+" su una freccia: inserendo lì si crea un blocco in [slot].
final class LayoutInsert {
  const LayoutInsert(this.at, this.slot);
  final Pt at;
  final Slot slot;
}

final class DiagramLayout {
  DiagramLayout({
    required this.width,
    required this.height,
    required this.boxes,
    required this.edges,
    required this.labels,
    required this.inserts,
    required this.dots,
  });

  final double width;
  final double height;
  final List<LayoutBox> boxes;
  final List<LayoutEdge> edges;
  final List<LayoutLabel> labels;
  final List<LayoutInsert> inserts;

  /// Punti di ricongiungimento.
  final List<Pt> dots;

  late final Map<String, LayoutBox> _byId = {for (final b in boxes) b.id: b};
  LayoutBox? boxById(String id) => _byId[id];
}

DiagramLayout layoutProgram(
  Program program, {
  MeasureText measure = estimateTextWidth,
  Metrics metrics = const Metrics(),
}) => _Engine(measure, metrics)._program(program);

/// Estensione di un frammento: [l] e [r] dall'asse, [h] altezza; [w] larghezza
/// della forma principale (blocco, rombo, esagono).
final class _Ext {
  const _Ext(this.l, this.r, this.h, [this.w = 0]);
  final double l;
  final double r;
  final double h;
  final double w;
}

final class _Engine {
  _Engine(this.measure, this.m);

  final MeasureText measure;
  final Metrics m;
  final _cache = Map<Stmt, _Ext>.identity();

  final boxes = <LayoutBox>[];
  final edges = <LayoutEdge>[];
  final labels = <LayoutLabel>[];
  final inserts = <LayoutInsert>[];
  final dots = <Pt>[];

  /// Distanza minima tra il vertice del rombo e l'asse di un ramo (spazio per l'etichetta).
  static const _labelRoom = 44.0;

  // ------------------------------------------------------------ misura

  double _shapeWidth(Stmt s) {
    final tw = measure(blockLabel(s));
    return switch (s) {
      Declare() ||
      Assign() ||
      Comment() ||
      Delay() => math.max(m.minBlockWidth, tw + 2 * m.paddingX),
      Input() ||
      Output() ||
      DigitalWrite() ||
      AnalogWrite() ||
      DigitalRead() ||
      AnalogRead() => math.max(m.minBlockWidth, tw + 2 * m.paddingX + 2 * m.skew),
      If() || While() || DoWhile() => math.max(m.minDiamondWidth, (tw + 24) * 1.5),
      For() => math.max(m.minBlockWidth, tw + 2 * m.paddingX + 2 * m.hexInset),
    };
  }

  _Ext _seqExt(List<Stmt> list) {
    var l = m.insertRadius + 2, r = m.insertRadius + 2, h = m.gap * (list.length + 1);
    for (final s in list) {
      final e = _ext(s);
      l = math.max(l, e.l);
      r = math.max(r, e.r);
      h += e.h;
    }
    return _Ext(l, r, h);
  }

  _Ext _ext(Stmt s) => _cache[s] ??= _computeExt(s);

  _Ext _computeExt(Stmt s) {
    final w = _shapeWidth(s);
    switch (s) {
      case Declare() ||
          Assign() ||
          Input() ||
          Output() ||
          Comment() ||
          DigitalWrite() ||
          AnalogWrite() ||
          DigitalRead() ||
          AnalogRead() ||
          Delay():
        return _Ext(w / 2, w / 2, m.blockHeight, w);
      case If():
        final (lA, rA, le, re) = _ifAxes(s, w);
        return _Ext(
          math.max(w / 2, lA + le.l),
          math.max(w / 2, rA + re.r),
          m.diamondHeight / 2 + math.max(math.max(le.h, re.h), m.diamondHeight / 2 + 8),
          w,
        );
      case While(:final body) || For(:final body):
        final b = _seqExt(body);
        final sh = s is For ? m.hexHeight : m.diamondHeight;
        final (xl, xr) = _loopSides(w, b);
        return _Ext(xl, xr, 4 * m.loopJoin + sh + b.h, w);
      case DoWhile(:final body):
        final b = _seqExt(body);
        final (xl, _) = _loopSides(w, b);
        return _Ext(xl, math.max(w / 2, b.r), m.loopJoin + b.h + m.diamondHeight, w);
    }
  }

  /// Assi dei rami di un "se": distanza dell'asse sinistro (altrimenti) e destro (allora).
  (double, double, _Ext, _Ext) _ifAxes(If s, double w) {
    final le = _seqExt(s.otherwise);
    final re = _seqExt(s.then);
    final minAxis = w / 2 + _labelRoom;
    final lA = math.max(minAxis, le.r + m.branchSeparation / 2);
    final rA = math.max(minAxis, re.l + m.branchSeparation / 2);
    return (lA, rA, le, re);
  }

  (double, double) _loopSides(double w, _Ext body) =>
      (math.max(w / 2, body.l) + m.loopMargin, math.max(w / 2, body.r) + m.loopMargin);

  // ------------------------------------------------------------ posizionamento

  DiagramLayout _program(Program p) {
    if (p.isArduino) return _arduino(p);
    final seq = _seqExt(p.body);
    final tw = m.terminalWidth;
    final ax = m.margin + math.max(tw / 2, seq.l);
    var y = m.margin;
    boxes.add(
      LayoutBox(startId, Shape.terminal, ax - tw / 2, y, tw, m.terminalHeight, tr.flowStart),
    );
    y += m.terminalHeight;
    y = _placeSeq(p.body, ax, y, null, Branch.body, lastArrow: true);
    boxes.add(LayoutBox(endId, Shape.terminal, ax - tw / 2, y, tw, m.terminalHeight, tr.flowEnd));
    return DiagramLayout(
      width: ax + math.max(tw / 2, seq.r) + m.margin,
      height: y + m.terminalHeight + m.margin,
      boxes: boxes,
      edges: edges,
      labels: labels,
      inserts: inserts,
      dots: dots,
    );
  }

  /// Sketch Arduino: `setup()` → blocchi di setup → `loop()` → corpo, che
  /// ritorna all'inizio del loop (nessun blocco Fine: il loop non termina).
  DiagramLayout _arduino(Program p) {
    final setup = _seqExt(p.setup);
    final body = _seqExt(p.body);
    final tw = m.terminalWidth, th = m.terminalHeight, j = m.loopJoin;
    final xl = math.max(tw / 2, body.l) + m.loopMargin;
    final left = math.max(math.max(tw / 2, setup.l), xl + 4);
    final right = math.max(tw / 2, math.max(setup.r, body.r));
    final ax = m.margin + left;
    var y = m.margin;
    boxes.add(LayoutBox(startId, Shape.terminal, ax - tw / 2, y, tw, th, 'setup()'));
    y += th;
    y = _placeSeq(p.setup, ax, y, setupListId, Branch.body, lastArrow: true);
    boxes.add(LayoutBox(loopId, Shape.terminal, ax - tw / 2, y, tw, th, 'loop()'));
    y += th;
    final yJoin = y + j;
    edges.add(LayoutEdge([Pt(ax, y), Pt(ax, yJoin)]));
    dots.add(Pt(ax, yJoin));
    final yb = _placeSeq(p.body, ax, yJoin, null, Branch.body, lastArrow: false);
    edges.add(
      LayoutEdge([
        Pt(ax, yb),
        Pt(ax, yb + j),
        Pt(ax - xl, yb + j),
        Pt(ax - xl, yJoin),
        Pt(ax, yJoin),
      ], arrow: true),
    );
    labels.add(LayoutLabel(Pt(ax - xl / 2, yb + j + 12), tr.flowRepeat));
    return DiagramLayout(
      width: ax + right + m.margin,
      height: yb + j + 24 + m.margin,
      boxes: boxes,
      edges: edges,
      labels: labels,
      inserts: inserts,
      dots: dots,
    );
  }

  /// Posiziona una sequenza con l'asse in [ax] a partire da [y]; restituisce la y finale.
  double _placeSeq(
    List<Stmt> list,
    double ax,
    double y,
    String? parentId,
    Branch branch, {
    required bool lastArrow,
  }) {
    for (var i = 0; i <= list.length; i++) {
      edges.add(LayoutEdge([Pt(ax, y), Pt(ax, y + m.gap)], arrow: i < list.length || lastArrow));
      inserts.add(LayoutInsert(Pt(ax, y + m.gap / 2), Slot(parentId, branch, i)));
      y += m.gap;
      if (i < list.length) {
        _place(list[i], ax, y);
        y += _ext(list[i]).h;
      }
    }
    return y;
  }

  void _place(Stmt s, double ax, double y) {
    final e = _ext(s);
    final w = e.w;
    final label = blockLabel(s);
    LayoutBox box(Shape shape, double top, double h) =>
        LayoutBox(s.id, shape, ax - w / 2, top, w, h, label);

    switch (s) {
      case Declare():
        boxes.add(box(Shape.declare, y, m.blockHeight));
      case Assign():
        boxes.add(box(Shape.process, y, m.blockHeight));
      case Input() || Output():
        boxes.add(box(Shape.io, y, m.blockHeight));
      case Comment():
        boxes.add(box(Shape.comment, y, m.blockHeight));
      case Delay():
        boxes.add(box(Shape.hardware, y, m.blockHeight));
      case DigitalWrite() || AnalogWrite() || DigitalRead() || AnalogRead():
        boxes.add(box(Shape.pinIo, y, m.blockHeight));

      case If(:final then, :final otherwise):
        final (lA, rA, _, _) = _ifAxes(s, w);
        final hd = m.diamondHeight;
        final cy = y + hd / 2;
        final bottom = y + e.h;
        boxes.add(box(Shape.decision, y, hd));
        // ramo "allora" a destra
        edges.add(LayoutEdge([Pt(ax + w / 2, cy), Pt(ax + rA, cy)]));
        final yt = _placeSeq(then, ax + rA, cy, s.id, Branch.then, lastArrow: false);
        edges.add(LayoutEdge([Pt(ax + rA, yt), Pt(ax + rA, bottom), Pt(ax, bottom)]));
        // ramo "altrimenti" a sinistra
        edges.add(LayoutEdge([Pt(ax - w / 2, cy), Pt(ax - lA, cy)]));
        final yo = _placeSeq(otherwise, ax - lA, cy, s.id, Branch.otherwise, lastArrow: false);
        edges.add(LayoutEdge([Pt(ax - lA, yo), Pt(ax - lA, bottom), Pt(ax, bottom)]));
        dots.add(Pt(ax, bottom));
        labels.add(LayoutLabel(Pt(ax + (w / 2 + rA) / 2, cy - 10), tr.edgeTrue));
        labels.add(LayoutLabel(Pt(ax - (w / 2 + lA) / 2, cy - 10), tr.edgeFalse));

      case While(:final body) || For(:final body):
        final j = m.loopJoin;
        final isFor = s is For;
        final sh = isFor ? m.hexHeight : m.diamondHeight;
        final b = _seqExt(body);
        final (xl, xr) = _loopSides(w, b);
        final yJoin = y + j;
        final yShape = y + 2 * j;
        final cy = yShape + sh / 2;
        edges.add(LayoutEdge([Pt(ax, y), Pt(ax, yShape)], arrow: true));
        boxes.add(box(isFor ? Shape.loop : Shape.decision, yShape, sh));
        final yb = _placeSeq(body, ax, yShape + sh, s.id, Branch.body, lastArrow: false);
        // ritorno a sinistra
        edges.add(
          LayoutEdge([
            Pt(ax, yb),
            Pt(ax, yb + j),
            Pt(ax - xl, yb + j),
            Pt(ax - xl, yJoin),
            Pt(ax, yJoin),
          ], arrow: true),
        );
        dots.add(Pt(ax, yJoin));
        // uscita a destra
        final yExit = yb + 2 * j;
        edges.add(
          LayoutEdge([Pt(ax + w / 2, cy), Pt(ax + xr, cy), Pt(ax + xr, yExit), Pt(ax, yExit)]),
        );
        if (!isFor) {
          labels.add(LayoutLabel(Pt(ax + 30, yShape + sh + 12), tr.edgeTrue));
          labels.add(LayoutLabel(Pt(ax + (w / 2 + xr) / 2, cy - 10), tr.edgeFalse));
        }

      case DoWhile(:final body):
        final j = m.loopJoin;
        final hd = m.diamondHeight;
        final b = _seqExt(body);
        final (xl, _) = _loopSides(w, b);
        final yJoin = y + j;
        edges.add(LayoutEdge([Pt(ax, y), Pt(ax, yJoin)]));
        dots.add(Pt(ax, yJoin));
        final yd = _placeSeq(body, ax, yJoin, s.id, Branch.body, lastArrow: true);
        boxes.add(box(Shape.decision, yd, hd));
        final cy = yd + hd / 2;
        edges.add(
          LayoutEdge([
            Pt(ax - w / 2, cy),
            Pt(ax - xl, cy),
            Pt(ax - xl, yJoin),
            Pt(ax, yJoin),
          ], arrow: true),
        );
        labels.add(LayoutLabel(Pt(ax - (w / 2 + xl) / 2, cy - 10), tr.edgeTrue));
        labels.add(LayoutLabel(Pt(ax + 30, yd + hd + 12), tr.edgeFalse));
    }
  }
}
