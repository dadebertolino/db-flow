import 'package:flutter/foundation.dart';

import '../arduino/board.dart';
import '../i18n/tr.dart';
import '../model/exercise.dart';
import '../model/program.dart';
import '../model/slot.dart';
import '../model/stmt.dart';
import '../model/validator.dart';
import 'commands.dart';
import 'history.dart';

/// Stato dell'editor: programma corrente (con undo/redo), selezione, problemi.
class EditorState extends ChangeNotifier {
  EditorState(Program program) : _history = History(program);

  final History _history;
  String? _selectedId;

  Program get program => _history.current;
  String? get selectedId => _selectedId;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  Program? _issuesFor;
  AppLanguage? _issuesLanguage;
  Map<String, List<Issue>> _issues = const {};

  /// Problemi per blocco, ricalcolati solo quando cambia il programma.
  Map<String, List<Issue>> get issues {
    if (!identical(_issuesFor, program) || _issuesLanguage != tr.language) {
      _issues = issuesByBlock(validate(program));
      _issuesFor = program;
      _issuesLanguage = tr.language;
    }
    return _issues;
  }

  Stmt? get selected => _selectedId == null ? null : findBlock(program, _selectedId!);

  void select(String? id) {
    if (id == _selectedId) return;
    _selectedId = id;
    notifyListeners();
  }

  void _apply(Program next, {String? select}) {
    _history.push(next);
    if (select != null) _selectedId = select;
    if (_selectedId != null && findBlock(program, _selectedId!) == null) _selectedId = null;
    notifyListeners();
  }

  void insert(Slot slot, Stmt stmt) => _apply(insertAt(program, slot, stmt), select: stmt.id);

  void replace(String id, Stmt stmt) => _apply(replaceBlock(program, id, stmt), select: stmt.id);

  void delete(String id) => _apply(removeBlock(program, id));

  void duplicate(String id) => _apply(duplicateBlock(program, id));

  void move(String id, int delta) => _apply(moveBlock(program, id, delta));

  void rename(String name) => _apply(program.copyWith(name: name));

  /// Nuova configurazione dei pin (diagrammi Arduino).
  void setArduino(ArduinoConfig cfg) => _apply(program.copyWith(arduino: cfg));

  /// Nuovo esercizio (o nessuno). Non registra nulla se non cambia.
  void setExercise(Exercise? e) {
    if (e == program.exercise) return;
    _apply(program.withExercise(e));
  }

  void undo() {
    if (!canUndo) return;
    _history.undo();
    _apply(program); // aggiorna selezione e listener senza registrare
  }

  void redo() {
    if (!canRedo) return;
    _history.redo();
    _apply(program);
  }
}
