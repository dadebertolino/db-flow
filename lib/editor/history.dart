/// Undo/redo a snapshot di programmi immutabili. Dart puro.
library;

import '../model/program.dart';

final class History {
  History(this._current, {this.limit = 100});

  final int limit;
  Program _current;
  final _undo = <Program>[];
  final _redo = <Program>[];

  Program get current => _current;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Registra un nuovo stato. Cancella il "ripeti".
  void push(Program next) {
    if (identical(next, _current)) return;
    _undo.add(_current);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
    _current = next;
  }

  Program undo() {
    if (_undo.isEmpty) return _current;
    _redo.add(_current);
    return _current = _undo.removeLast();
  }

  Program redo() {
    if (_redo.isEmpty) return _current;
    _undo.add(_current);
    return _current = _redo.removeLast();
  }
}
