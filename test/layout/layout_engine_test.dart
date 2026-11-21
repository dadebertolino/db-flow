import 'dart:io';

import 'package:db_flow/layout/layout_engine.dart';
import 'package:db_flow/model/expr.dart';
import 'package:db_flow/model/program.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/model/stmt.dart';
import 'package:flutter_test/flutter_test.dart';

bool _overlap(LayoutBox a, LayoutBox b) =>
    a.x < b.right && b.x < a.right && a.y < b.bottom && b.y < a.bottom;

/// Numero di "+" attesi: ogni lista di n blocchi ha n+1 punti di inserimento.
int _expectedInserts(List<Stmt> list) =>
    list.length +
    1 +
    list.fold(
      0,
      (n, s) =>
          n +
          switch (s) {
            If(:final then, :final otherwise) =>
              _expectedInserts(then) + _expectedInserts(otherwise),
            While(:final body) ||
            DoWhile(:final body) ||
            For(:final body) => _expectedInserts(body),
            _ => 0,
          },
    );

void checkLayout(Program p) {
  final l = layoutProgram(p);
  final ids = p.allStmts.map((s) => s.id).toSet();
  expect(
    l.boxes.map((b) => b.id).toSet(),
    p.isArduino ? {...ids, startId, loopId} : {...ids, startId, endId},
  );
  expect(
    l.inserts,
    hasLength(_expectedInserts(p.body) + (p.isArduino ? _expectedInserts(p.setup) : 0)),
  );
  for (final b in l.boxes) {
    expect(b.x, greaterThanOrEqualTo(0), reason: b.label);
    expect(b.right, lessThanOrEqualTo(l.width), reason: b.label);
    expect(b.bottom, lessThanOrEqualTo(l.height), reason: b.label);
  }
  for (var i = 0; i < l.boxes.length; i++) {
    for (var j = i + 1; j < l.boxes.length; j++) {
      expect(
        _overlap(l.boxes[i], l.boxes[j]),
        isFalse,
        reason: '"${l.boxes[i].label}" si sovrappone a "${l.boxes[j].label}"',
      );
    }
  }
  for (final e in l.edges) {
    for (final pt in e.points) {
      expect(pt.x, inInclusiveRange(0, l.width));
      expect(pt.y, inInclusiveRange(0, l.height));
    }
  }
  // Nessun "+" dentro un blocco.
  for (final ins in l.inserts) {
    for (final b in l.boxes) {
      final inside = ins.at.x > b.x && ins.at.x < b.right && ins.at.y > b.y && ins.at.y < b.bottom;
      expect(inside, isFalse, reason: '"+" dentro "${b.label}"');
    }
  }
}

void main() {
  for (final f in Directory('assets/examples').listSync().whereType<File>()) {
    test('layout valido: ${f.uri.pathSegments.last}', () {
      checkLayout(decodeProgram(f.readAsStringSync()));
    });
  }

  test('programma vuoto: inizio, fine e un solo "+"', () {
    final l = layoutProgram(Program(name: 'x'));
    expect(l.boxes.map((b) => b.id), [startId, endId]);
    expect(l.inserts.single.slot.index, 0);
  });

  test('blocchi in sequenza sono centrati sullo stesso asse', () {
    final p = Program(
      name: 'x',
      body: [
        Declare(name: 'a', type: VarType.integer),
        Output(value: ExprSource('"un testo piuttosto lungo da scrivere" & a')),
      ],
    );
    final l = layoutProgram(p);
    final centers = l.boxes.map((b) => b.center.x).toSet();
    expect(centers, hasLength(1));
  });

  test('se annidati e cicli con rami vuoti e pieni', () {
    ExprSource e(String s) => ExprSource(s);
    checkLayout(
      Program(
        name: 'annidati',
        body: [
          If(
            cond: e('a > 0'),
            then: [
              While(
                cond: e('a > 0'),
                body: [
                  If(
                    cond: e('a % 2 == 0'),
                    then: [Output(value: e('"pari"'))],
                  ),
                  Assign(target: 'a', value: e('a - 1')),
                ],
              ),
            ],
            otherwise: [
              DoWhile(
                body: [
                  For(
                    variable: 'i',
                    from: e('1'),
                    to: e('10'),
                    body: [Output(value: e('i'))],
                  ),
                ],
                cond: e('falso'),
              ),
            ],
          ),
          While(cond: e('vero')),
          DoWhile(cond: e('vero')),
          For(variable: 'i', from: e('1'), to: e('2')),
        ],
      ),
    );
  });
}
