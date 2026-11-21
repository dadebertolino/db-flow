/// Assegnazione dei pin con scambi e spostamenti automatici. Dart puro.
library;

import 'board.dart';

/// Esito della scelta di un pin. Se [error] non è `null` la scelta non è
/// possibile e [pins] è la configurazione invariata.
final class PinPlan {
  const PinPlan(this.pins, {this.displaced, this.displacedTo, this.swapped = false, this.error});

  /// Configurazione risultante.
  final List<PinConfig> pins;

  /// Pin che occupava quello scelto e che viene spostato (o scambiato).
  final PinConfig? displaced;

  /// Dove finisce [displaced].
  final String? displacedTo;

  /// `true` se [displaced] prende il posto lasciato libero dal pin modificato.
  final bool swapped;

  /// Motivo per cui la scelta non è possibile (nome del pin coinvolto).
  final PinPlanError? error;

  bool get ok => error == null;
}

enum PinPlanError {
  /// Il pin occupante non può andare sul pin lasciato libero.
  cannotSwap,

  /// Per il pin occupante non c'è un altro pin libero adatto.
  cannotMove,
}

/// Primo pin libero adatto a [p] (componente e modo), escludendo [taken] e i
/// pin della seriale. Con [needsPwm] solo pin PWM; altrimenti, se [p] era su
/// un pin PWM, preferisce un altro PWM.
String? freePinFor(Board board, PinConfig p, Set<String> taken, {bool needsPwm = false}) {
  final candidates = [
    for (final pin in board.allPins)
      if (!taken.contains(board.physical(pin)) &&
          !board.serialPins.contains(pin) &&
          p.component.fits(board, pin, p.mode) &&
          (!needsPwm || board.pwmPins.contains(pin)))
        pin,
  ];
  if (board.pwmPins.contains(p.pin)) {
    final pwm = candidates.where(board.pwmPins.contains);
    if (pwm.isNotEmpty) return pwm.first;
  }
  return candidates.firstOrNull;
}

/// Calcola la nuova configurazione quando [chosen] (nuovo pin, oppure la
/// modifica di [existing]) va su un pin forse già occupato:
/// - modifica di un pin esistente → l'occupante si scambia con lui;
/// - pin nuovo → l'occupante va sul primo pin libero adatto.
///
/// [pwmNames]: pin usati con `analogWrite` (vedi `pwmPinNames`), che possono
/// finire solo su un pin PWM.
PinPlan planPin(
  ArduinoConfig cfg,
  PinConfig? existing,
  PinConfig chosen, {
  Set<String> pwmNames = const {},
}) {
  final board = cfg.board;
  final others = [
    for (final p in cfg.pins)
      if (!identical(p, existing)) p,
  ];
  final occupant = others.where((p) => board.samePin(p.pin, chosen.pin)).firstOrNull;

  List<PinConfig> place(PinConfig? displaced, String? to) => [
    for (final p in cfg.pins)
      if (identical(p, existing))
        chosen
      else if (identical(p, displaced))
        p.copyWith(pin: to)
      else
        p,
    if (existing == null) chosen,
  ];

  if (occupant == null) return PinPlan(place(null, null));

  if (existing != null) {
    if (!occupant.component.fits(board, existing.pin, occupant.mode) ||
        (pwmNames.contains(occupant.name) && !board.pwmPins.contains(existing.pin))) {
      return PinPlan(cfg.pins, displaced: occupant, error: PinPlanError.cannotSwap);
    }
    return PinPlan(
      place(occupant, existing.pin),
      displaced: occupant,
      displacedTo: existing.pin,
      swapped: true,
    );
  }

  final taken = {for (final p in cfg.pins) board.physical(p.pin), board.physical(chosen.pin)};
  final to = freePinFor(board, occupant, taken, needsPwm: pwmNames.contains(occupant.name));
  if (to == null) return PinPlan(cfg.pins, displaced: occupant, error: PinPlanError.cannotMove);
  return PinPlan(place(occupant, to), displaced: occupant, displacedTo: to);
}
