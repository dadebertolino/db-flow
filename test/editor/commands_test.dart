import 'package:db_flow/editor/commands.dart';
import 'package:db_flow/editor/history.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/slot.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:flutter_test/flutter_test.dart';

Program sample() => Program(
  name: 'p',
  body: [
    Declare(id: 'd', name: 'n', type: VarType.integer),
    If(
      id: 'if',
      cond: ExprSource('n > 0'),
      then: [Output(id: 'o1', value: ExprSource('"pos"'))],
    ),
    Output(id: 'o2', value: ExprSource('n')),
  ],
);

List<String> ids(Program p) => walk(p.body).map((s) => s.id).toList();

void main() {
  test('inserimento nel corpo principale e in un ramo', () {
    var p = insertAt(sample(), const Slot.root(0), Comment(id: 'c', text: 'x'));
    expect(ids(p), ['c', 'd', 'if', 'o1', 'o2']);
    p = insertAt(p, const Slot('if', Branch.otherwise, 0), Comment(id: 'c2', text: 'y'));
    expect((findBlock(p, 'if')! as If).otherwise.single.id, 'c2');
    p = insertAt(p, const Slot('if', Branch.then, 1), Comment(id: 'c3', text: 'z'));
    expect((findBlock(p, 'if')! as If).then.map((s) => s.id), ['o1', 'c3']);
  });

  test('il programma originale non cambia', () {
    final p = sample();
    insertAt(p, const Slot.root(0), Comment(text: 'x'));
    removeBlock(p, 'if');
    expect(ids(p), ['d', 'if', 'o1', 'o2']);
  });

  test('eliminazione con tutto il contenuto', () {
    expect(ids(removeBlock(sample(), 'if')), ['d', 'o2']);
    expect(ids(removeBlock(sample(), 'o1')), ['d', 'if', 'o2']);
  });

  test('sostituzione di un contenitore mantiene i rami che porta con sé', () {
    final old = findBlock(sample(), 'if')! as If;
    final p = replaceBlock(
      sample(),
      'if',
      If(id: 'if', cond: ExprSource('n < 0'), then: old.then, otherwise: old.otherwise),
    );
    final updated = findBlock(p, 'if')! as If;
    expect(updated.cond.text, 'n < 0');
    expect(updated.then.single.id, 'o1');
  });

  test('duplica: copia profonda subito dopo, con id nuovi', () {
    final p = duplicateBlock(sample(), 'if');
    expect(p.body, hasLength(4));
    final copy = p.body[2] as If;
    expect(copy.id, isNot('if'));
    expect(copy.then.single.id, isNot('o1'));
    expect(ids(p).toSet(), hasLength(ids(p).length));
    expect(encodeProgram(p), contains('pos'));
  });

  test('sposta su e giù, senza uscire dalla lista', () {
    expect(moveBlock(sample(), 'o2', -1).body.map((s) => s.id), ['d', 'o2', 'if']);
    expect(moveBlock(sample(), 'd', 1).body.map((s) => s.id), ['if', 'd', 'o2']);
    expect(moveBlock(sample(), 'd', -1).body.map((s) => s.id), ['d', 'if', 'o2']);
    expect(ids(moveBlock(sample(), 'o1', 1)), ['d', 'if', 'o1', 'o2']);
  });

  test('locate', () {
    final loc = locate(sample(), 'o1')!;
    expect(loc.slot, const Slot('if', Branch.then, 0));
    expect(loc.length, 1);
    expect(locate(sample(), 'nessuno'), isNull);
  });

  test('variabili dichiarate', () {
    expect(declaredVariables(sample()), ['n']);
  });

  test('ogni tipo di blocco si crea vuoto', () {
    for (final k in BlockKind.values) {
      expect(k.create(), isA<Stmt>(), reason: k.label);
    }
  });

  group('undo/redo', () {
    test('annulla e ripeti', () {
      final h = History(sample());
      final a = removeBlock(h.current, 'o2');
      h.push(a);
      expect(h.canUndo, isTrue);
      expect(ids(h.undo()), ['d', 'if', 'o1', 'o2']);
      expect(h.canRedo, isTrue);
      expect(identical(h.redo(), a), isTrue);
    });

    test('una nuova modifica cancella il "ripeti"', () {
      final h = History(sample());
      h.push(removeBlock(h.current, 'o2'));
      h.undo();
      h.push(removeBlock(h.current, 'd'));
      expect(h.canRedo, isFalse);
    });

    test('massimo 100 passi', () {
      final h = History(Program(name: '0'));
      for (var i = 1; i <= 150; i++) {
        h.push(Program(name: '$i'));
      }
      var n = 0;
      while (h.canUndo) {
        h.undo();
        n++;
      }
      expect(n, 100);
      expect(h.current.name, '50');
    });
  });
}
