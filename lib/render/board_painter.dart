import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../arduino/board.dart';
import '../i18n/tr.dart';

/// Colore di un pin configurato, per modo.
Color pinModeColor(PinMode m) => switch (m) {
  PinMode.output => const Color(0xFF00897B),
  PinMode.input => const Color(0xFFE08A00),
  PinMode.inputPullup => const Color(0xFFC2185B),
  PinMode.analogInput => const Color(0xFF7E57C2),
};

/// Icona del componente collegato a un pin.
IconData componentIcon(Component c) => switch (c) {
  Component.led => Icons.lightbulb_outline,
  Component.button => Icons.radio_button_checked,
  Component.potentiometer => Icons.tune,
  Component.other => Icons.settings_input_component,
};

/// Spazio (mm) intorno alla scheda: stretto sui lati senza richiami, largo
/// dove escono linee, icone e nomi dei pin.
const _side = 8.0;
const _callout = 22.0;

/// Margini del disegno di [d], in millimetri.
({double left, double top, double right, double bottom}) boardMargins(BoardDrawing d) => (
  left: d.hasLeftCallouts ? _callout : _side,
  top: _callout,
  right: d.hasRightCallouts ? _callout : _side,
  bottom: _callout,
);

/// Disegno semplificato della scheda con i pin configurati. Le misure sono in
/// millimetri ([BoardDrawing]); il disegno si adatta alla larghezza disponibile.
class BoardPainter extends CustomPainter {
  BoardPainter(this.config, {this.highlight, this.fontFamily});

  final ArduinoConfig config;

  /// Font dei testi (`null` = quello di sistema).
  final String? fontFamily;

  /// Pin da evidenziare (es. appena toccato).
  final String? highlight;

  BoardDrawing get d => config.board.drawing!;

  /// Rapporto larghezza/altezza dell'area disegnata.
  static double aspectRatio(BoardDrawing d) {
    final m = boardMargins(d);
    return (d.width + m.left + m.right) / (d.height + m.top + m.bottom);
  }

  /// Scala (pixel per mm) per un disegno largo [width].
  static double scaleFor(BoardDrawing d, double width) {
    final m = boardMargins(d);
    return width / (d.width + m.left + m.right);
  }

  /// Posizione nel widget (largo [width]) del punto [mm] della scheda.
  static Offset toLocal(BoardDrawing d, double width, ({double x, double y}) mm) {
    final m = boardMargins(d), s = scaleFor(d, width);
    return Offset((mm.x + m.left) * s, (mm.y + m.top) * s);
  }

  /// Pin sotto il punto [local] (coordinate del widget), oppure `null`: vale
  /// il pin più vicino, oppure la striscia del suo richiamo.
  static String? pinAt(ArduinoConfig cfg, Size size, Offset local) {
    final d = cfg.board.drawing!;
    final m = boardMargins(d), s = scaleFor(d, size.width);
    final x = local.dx / s - m.left, y = local.dy / s - m.top;
    String? best;
    var bestDist = 1.8; // mm
    for (final pin in cfg.board.physicalPins) {
      final c = d.pinCenter(pin);
      if (c == null) continue;
      final dist = math.sqrt(math.pow(x - c.x, 2) + math.pow(y - c.y, 2));
      if (dist < bestDist) {
        best = pin;
        bestDist = dist;
      }
    }
    if (best != null) return best;
    const half = HeaderStrip.pitch / 2;
    for (final pin in cfg.board.physicalPins) {
      final c = d.pinCenter(pin);
      if (c == null) continue;
      final hit = switch (c.side) {
        Side.top => (x - c.x).abs() < half && y < c.y && y > -m.top,
        Side.bottom => (x - c.x).abs() < half && y > c.y && y < d.height + m.bottom,
        Side.left => (y - c.y).abs() < half && x < c.x && x > c.x - _callout,
        Side.right => (y - c.y).abs() < half && x > c.x && x < d.width + m.right,
      };
      if (hit) return pin;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = boardMargins(d);
    canvas.save();
    canvas.scale(scaleFor(d, size.width));
    canvas.translate(m.left, m.top);
    _board(canvas);
    _pins(canvas);
    canvas.restore();
  }

  static Paint _fill(int c) => Paint()..color = Color(c);

  TextPainter _layout(String text, double size, Color color, FontWeight weight) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1,
        fontFamily: fontFamily,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// Testo in [at]: centrato, allineato a sinistra o, con [alignRight], a destra.
  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    double size = 1.5,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w600,
    double angle = 0,
    bool center = false,
    bool alignRight = false,
  }) {
    final tp = _layout(text, size, color, weight);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final dx = center ? -tp.width / 2 : (alignRight ? -tp.width : 0.0);
    tp.paint(canvas, Offset(dx, -tp.height / 2));
    canvas.restore();
  }

  void _board(Canvas canvas) {
    final board = config.board;
    // circuito stampato
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, d.width, d.height, const Radius.circular(2)),
      _fill(0xFF0F7C8C),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, d.width, d.height, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFF0A5A66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3,
    );
    // fori di fissaggio
    for (final h in d.holes) {
      canvas.drawCircle(Offset(h.x, h.y), 1.6, _fill(0xFFE0E0E0));
      canvas.drawCircle(Offset(h.x, h.y), 1.0, _fill(0xFFFAFAFA));
    }
    // USB e alimentazione
    Rect r(MmRect m) => Rect.fromLTWH(m.x, m.y, m.w, m.h);
    if (d.usb case final usb?) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r(usb), const Radius.circular(0.6)),
        _fill(0xFFB0BEC5),
      );
      canvas.drawRect(r(usb).deflate(math.min(1.4, usb.h / 4)), _fill(0xFF90A4AE));
    }
    if (d.jack case final jack?) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r(jack), const Radius.circular(0.8)),
        _fill(0xFF212121),
      );
      canvas.drawCircle(r(jack).center, 1.6, _fill(0xFF424242));
    }
    // microcontrollore
    final chip = r(d.chip);
    final leg = _fill(0xFFB0BEC5);
    for (var x = chip.left + 1.0; x < chip.right - 0.5; x += 2.54) {
      canvas.drawRect(Rect.fromLTWH(x, chip.top - 0.8, 0.6, 0.8), leg);
      canvas.drawRect(Rect.fromLTWH(x, chip.bottom, 0.6, 0.8), leg);
    }
    canvas.drawRect(chip, _fill(0xFF263238));
    canvas.drawCircle(Offset(chip.left + 1.4, chip.top + 1.4), 0.6, _fill(0xFF455A64));
    // la scritta si riduce per stare nel chip delle schede piccole
    final full = _layout(tr.microcontroller, 1.4, Colors.white, FontWeight.w600).width;
    _text(
      canvas,
      tr.microcontroller,
      chip.center,
      size: math.min(1.4, 1.4 * (chip.width - 1) / full),
      color: const Color(0xFF90A4AE),
      center: true,
    );
    // titoli
    if (d.title case final t?) {
      _text(canvas, board.name, Offset(t.x, t.y), size: t.size, weight: FontWeight.w800);
    }
    if (d.digitalTitle case final p?) {
      _text(canvas, 'DIGITAL (PWM ~)', Offset(p.x, p.y), size: 1.5, center: true);
    }
    if (d.analogTitle case final p?) {
      _text(canvas, 'ANALOG IN', Offset(p.x, p.y), size: 1.5, center: true);
    }
    // LED "L" collegato al pin del LED integrato
    final builtin = config.pins.where((p) => p.pin == board.ledBuiltin).firstOrNull;
    final lit = builtin?.mode == PinMode.output;
    final led = Rect.fromCenter(center: Offset(d.ledL.x, d.ledL.y), width: 1.6, height: 0.9);
    if (lit) canvas.drawCircle(led.center, 2.2, _fill(0x66FFD54F));
    canvas.drawRect(led, _fill(lit ? 0xFFFFC107 : 0xFFFFF8E1));
    _text(canvas, 'L', Offset(d.ledL.x + 1.6, d.ledL.y), size: 1.4);
    // connettori
    final configured = {for (final p in config.pins) board.physical(p.pin)};
    for (final h in d.headers) {
      final n = h.labels.length;
      const half = HeaderStrip.pitch / 2;
      final last = h.pin(n - 1);
      canvas.drawRect(
        Rect.fromLTRB(h.x - half, h.y - half, last.x + half, last.y + half),
        _fill(0xFF1B1B1B),
      );
      for (var i = 0; i < n; i++) {
        final p = h.pin(i);
        final c = Offset(p.x, p.y);
        canvas.drawRect(Rect.fromCenter(center: c, width: 1.0, height: 1.0), _fill(0xFF5F5F5F));
        final label = h.labels[i];
        if (label.isEmpty) continue;
        final pwmLabel = board.pwmPins.contains(label) ? '~$label' : label;
        // pin con due nomi (Micro): «~9/A9»
        final text = switch (board.analogNameOf(label)) {
          final a? => '$pwmLabel/$a',
          null => pwmLabel,
        };
        switch (h.side) {
          case Side.top || Side.bottom:
            // etichetta sul circuito, in verticale come sulle schede vere
            final w = _layout(text, 1.35, Colors.white, FontWeight.w600).width;
            final y = h.side == Side.top ? p.y + 1.8 + w : p.y - 1.8;
            _text(canvas, text, Offset(c.dx, y), size: 1.35, angle: -math.pi / 2);
          case Side.left || Side.right:
            // file verticali: etichetta orizzontale dal lato del richiamo,
            // tranne quando il pin è configurato (il richiamo riporta il numero)
            if (configured.contains(label)) continue;
            // dentro la scheda: a destra se c'è spazio (file sul lato destro),
            // altrimenti verso l'interno
            final w = _layout(text, 1.35, Colors.white, FontWeight.w600).width;
            final right = h.side == Side.right ? p.x + 1.6 + w <= d.width + 0.3 : h.x < d.width / 2;
            _text(
              canvas,
              text,
              Offset(p.x + (right ? 1.6 : -1.6), p.y),
              size: 1.35,
              alignRight: !right,
            );
        }
      }
    }
  }

  void _pins(Canvas canvas) {
    for (final p in config.pins) {
      final c = d.pinCenter(config.board.physical(p.pin));
      if (c == null) continue;
      final color = pinModeColor(p.mode);
      final center = Offset(c.x, c.y);
      final hl = p.pin == highlight;
      // linea verso l'esterno: fino al bordo per le file sui lati, corta per
      // quelle in mezzo alla scheda (colonna interna della Mega)
      final end = switch (c.side) {
        Side.top => Offset(c.x, -1.5),
        Side.bottom => Offset(c.x, d.height + 1.5),
        Side.right => Offset(math.max(c.x + 3, d.width + 1.5), c.y),
        Side.left => Offset(c.x < d.width / 2 ? -1.5 : c.x - 3.5, c.y),
      };
      final dir = switch (c.side) {
        Side.top => const Offset(0, -1),
        Side.bottom => const Offset(0, 1),
        Side.left => const Offset(-1, 0),
        Side.right => const Offset(1, 0),
      };
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = color
          ..strokeWidth = 0.35,
      );
      canvas.drawCircle(center, hl ? 1.5 : 1.15, _fill(0xFFFFFFFF));
      canvas.drawCircle(center, hl ? 1.2 : 0.9, Paint()..color = color);
      // icona del componente all'estremità della linea, poi il nome
      final iconCenter = end + dir * 1.8;
      canvas.drawCircle(iconCenter, 1.8, _fill(0xFFFFFFFF));
      canvas.drawCircle(
        iconCenter,
        1.8,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3,
      );
      final icon = componentIcon(p.component);
      final ip = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 2.6,
            color: color,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ip.paint(canvas, iconCenter - Offset(ip.width / 2, ip.height / 2));
      final short = p.name.length > 11 ? '${p.name.substring(0, 10)}…' : p.name;
      final namePos = iconCenter + dir * 2.4;
      switch (c.side) {
        case Side.top || Side.bottom:
          _text(
            canvas,
            short,
            namePos,
            size: 2.0,
            color: color,
            weight: FontWeight.w700,
            angle: c.side == Side.top ? -math.pi / 2 : math.pi / 2,
          );
        case Side.left || Side.right:
          // nome orizzontale con il numero del pin, su sfondo bianco perché
          // può cadere sopra il circuito
          final label = '$short (${p.pin})';
          final tp = _layout(label, 2.0, color, FontWeight.w700);
          final right = c.side == Side.right;
          final box = Rect.fromLTWH(
            right ? namePos.dx - 0.4 : namePos.dx - tp.width - 0.4,
            namePos.dy - tp.height / 2 - 0.3,
            tp.width + 0.8,
            tp.height + 0.6,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(box, const Radius.circular(0.6)),
            _fill(0xEEFFFFFF),
          );
          _text(
            canvas,
            label,
            namePos,
            size: 2.0,
            color: color,
            weight: FontWeight.w700,
            alignRight: !right,
          );
      }
    }
    final board = config.board;
    if (highlight != null && !config.pins.any((p) => board.samePin(p.pin, highlight!))) {
      final c = d.pinCenter(board.physical(highlight!));
      if (c != null) {
        canvas.drawCircle(
          Offset(c.x, c.y),
          1.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => old.config != config || old.highlight != highlight;
}

/// Scheda disegnata e interattiva: toccando un pin si chiama [onPinTap].
class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.config, this.onPinTap});

  final ArduinoConfig config;
  final ValueChanged<String>? onPinTap;

  @override
  Widget build(BuildContext context) {
    final d = config.board.drawing;
    if (d == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: BoardPainter.aspectRatio(d),
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              onTapUp: onPinTap == null
                  ? null
                  : (e) {
                      final pin = BoardPainter.pinAt(config, c.biggest, e.localPosition);
                      if (pin != null) onPinTap!(pin);
                    },
              child: Semantics(
                label: tr.boardSemantics(config.board.name),
                child: CustomPaint(painter: BoardPainter(config), size: c.biggest),
              ),
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final m in PinMode.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 5, backgroundColor: pinModeColor(m)),
                  const SizedBox(width: 4),
                  Text(m.label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
