/// Errore in un'espressione, con posizione nel testo sorgente.
final class ExprError implements Exception {
  const ExprError(this.message, this.pos, [this.length = 1]);

  /// Messaggio in italiano, pronto per l'utente.
  final String message;

  /// Offset (0-based) del primo carattere coinvolto.
  final int pos;

  /// Numero di caratteri coinvolti (per sottolineare l'errore).
  final int length;

  /// Colonna 1-based, come la vede l'utente.
  int get column => pos + 1;

  @override
  String toString() => 'Colonna $column: $message';
}
