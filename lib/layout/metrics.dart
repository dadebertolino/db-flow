/// Dimensioni dei blocchi e spaziature del diagramma. Dart puro.
library;

/// Larghezza in pixel logici di una riga di testo.
typedef MeasureText = double Function(String text);

/// Stima usata nei test e come ripiego: 8 px per carattere.
double estimateTextWidth(String text) => text.length * 8.0;

final class Metrics {
  const Metrics();

  /// Tratto verticale tra due blocchi (con il "+" a metà).
  final double gap = 48;

  final double blockHeight = 44;
  final double paddingX = 18;
  final double minBlockWidth = 110;

  /// Inclinazione del parallelogramma (I/O).
  final double skew = 14;

  final double diamondHeight = 64;
  final double minDiamondWidth = 130;

  final double hexHeight = 48;
  final double hexInset = 16;

  final double terminalWidth = 100;
  final double terminalHeight = 40;

  /// Distanza minima tra l'asse di un ramo e il rombo / l'altro ramo.
  final double branchSeparation = 36;

  /// Margine orizzontale delle linee di ritorno dei cicli.
  final double loopMargin = 40;

  /// Tratto di raccordo prima del rombo/esagono dei cicli e dopo il loro corpo.
  final double loopJoin = 16;

  /// Margine attorno all'intero diagramma.
  final double margin = 32;

  /// Raggio della zona attiva del "+".
  final double insertRadius = 12;
}
