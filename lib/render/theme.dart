import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../layout/layout_engine.dart';
import '../layout/metrics.dart';
import '../layout/palette.dart';

const _seed = Color(0xFF1F5FAD);

/// Font con il solo glifo «←» (assets/fonts, generato da
/// tool/fonts/make_arrow_font.py). Roboto, su Android, non ha la freccia e il
/// ripiego di sistema la disegna minuscola; come semplice ripiego
/// (fontFamilyFallback) non basta, perché Android sceglie comunque il proprio.
const arrowFont = 'DBFlowArrow';

/// [text] come [TextSpan] con [style]; su Android ogni «←» usa [arrowFont].
/// Su iOS e macOS il font di sistema ha già una buona freccia.
TextSpan arrowSpan(String text, [TextStyle? style]) {
  if (defaultTargetPlatform != TargetPlatform.android || !text.contains('←')) {
    return TextSpan(text: text, style: style);
  }
  final parts = text.split('←');
  return TextSpan(
    style: style,
    children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0)
          const TextSpan(
            text: '←',
            style: TextStyle(fontFamily: arrowFont),
          ),
        if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
      ],
    ],
  );
}

/// Tema dell'app, chiaro o scuro, con i colori del diagramma.
ThemeData appTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  useMaterial3: true,
  extensions: [brightness == Brightness.dark ? DiagramColors.dark : DiagramColors.light],
);

/// Colori del diagramma e degli stati (esecuzione, selezione, errore).
///
/// Gli export (PNG, SVG, PDF) usano sempre [DiagramColors.light]: si stampano.
@immutable
class DiagramColors extends ThemeExtension<DiagramColors> {
  const DiagramColors._({
    required this.isDark,
    required this.background,
    required this.edge,
    required this.text,
    required this.commentText,
    required this.active,
    required this.selection,
    required this.error,
    required this.warning,
    required this.insertFill,
  });

  static const light = DiagramColors._(
    isDark: false,
    background: Color(0xFFFAFAFA),
    edge: Color(edgeColorValue),
    text: Color(0xFF1B1B1B),
    commentText: Color(0xFF616161),
    active: Color(activeColorValue),
    selection: Color(0xFF1565C0),
    error: Color(errorColorValue),
    warning: Color(0xFF8A5300),
    insertFill: Colors.white,
  );

  static const dark = DiagramColors._(
    isDark: true,
    background: Color(0xFF15181C),
    edge: Color(0xFFB0BEC5),
    text: Color(0xFFECECEC),
    commentText: Color(0xFFB0B0B0),
    active: Color(0xFF66D08A),
    selection: Color(0xFF82B1FF),
    error: Color(0xFFFF7A70),
    warning: Color(0xFFFFB74D),
    insertFill: Color(0xFF263040),
  );

  final bool isDark;

  /// Sfondo dell'area di disegno.
  final Color background;
  final Color edge;
  final Color text;
  final Color commentText;

  /// Blocco in esecuzione, condizione vera.
  final Color active;
  final Color selection;
  final Color error;

  /// Avvisi e suggerimenti (non errori).
  final Color warning;

  /// Sfondo dei pulsanti "+".
  final Color insertFill;

  static DiagramColors of(BuildContext context) =>
      Theme.of(context).extension<DiagramColors>() ?? light;

  /// Riempimento e bordo per tipo di blocco.
  ({Color fill, Color stroke}) shape(Shape s) {
    final c = isDark ? shapeColorValuesDark(s) : shapeColorValues(s);
    return (fill: Color(c.fill), stroke: Color(c.stroke));
  }

  TextStyle blockText(Shape shape) => shape == Shape.comment
      ? blockTextStyle.copyWith(fontStyle: FontStyle.italic, color: commentText)
      : blockTextStyle.copyWith(color: text);

  TextStyle get edgeLabel => edgeLabelStyle.copyWith(color: edge);

  @override
  DiagramColors copyWith() => this;

  @override
  DiagramColors lerp(DiagramColors? other, double t) => other == null || t < 0.5 ? this : other;
}

/// Stile del testo nei blocchi (usato anche per misurarli: il colore non conta).
const blockTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Color(0xFF1B1B1B),
  height: 1.2,
);

const edgeLabelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

const monoStyle = TextStyle(
  fontFamily: 'Menlo',
  // «monospace» prima di Courier: su Android «Courier New» è un alias di
  // Cutive Mono, un font da macchina da scrivere.
  fontFamilyFallback: ['Consolas', 'monospace', 'Courier New', 'Courier'],
  fontSize: 13.5,
  height: 1.35,
);

/// Misura il testo con lo stesso stile usato nei blocchi (con cache).
MeasureText flutterMeasure([TextStyle style = blockTextStyle]) {
  final cache = <String, double>{};
  return (text) => cache[text] ??= (TextPainter(
    text: arrowSpan(text, style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout()).width;
}
