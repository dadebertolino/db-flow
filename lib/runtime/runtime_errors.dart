/// Errore durante l'esecuzione. Messaggio in italiano, per lo studente.
final class RuntimeError implements Exception {
  const RuntimeError(this.message, [this.blockId]);

  final String message;

  /// Blocco in cui si è verificato l'errore (assegnato dall'interprete).
  final String? blockId;

  RuntimeError at(String id) => blockId == null ? RuntimeError(message, id) : this;

  @override
  String toString() => message;
}
