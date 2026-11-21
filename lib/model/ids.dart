import 'dart:math';

final _rng = Random();
const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Nuovo id di blocco: 8 caratteri casuali, unico in pratica all'interno di un
/// programma (l'unicità viene comunque garantita al caricamento del file).
String newId() => String.fromCharCodes(
  List.generate(8, (_) => _alphabet.codeUnitAt(_rng.nextInt(_alphabet.length))),
);
