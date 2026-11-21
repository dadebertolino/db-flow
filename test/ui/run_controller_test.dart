import 'dart:io';

import 'package:db_flow/layout/layout_engine.dart';
import 'package:db_flow/model/serialization.dart';
import 'package:db_flow/ui/run_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

RunController massimo() =>
    RunController(decodeProgram(File('assets/examples/massimo.flow').readAsStringSync()));

void main() {
  test('stato iniziale: evidenzia Inizio', () {
    final r = massimo();
    expect(r.status, RunStatus.ready);
    expect(r.activeId, startId);
  });

  test('passo-passo con input, variabile modificata e fine', () {
    final r = massimo();
    r.step();
    expect(r.activeId, 'm1');
    expect(r.changedVar, 'a');
    r
      ..step()
      ..step()
      ..step();
    expect(r.status, RunStatus.waitingInput);
    expect(r.waitingFor!.variable, 'a');
    r.step(); // ignorato mentre aspetta
    expect(r.activeId, 'm4');
    expect(r.submitInput('tre'), contains('intero'));
    expect(r.status, RunStatus.waitingInput);
    expect(r.submitInput('3'), isNull);
    expect(r.status, RunStatus.paused);
    expect(r.changedVar, 'a');
    r.step();
    r.submitInput('8');
    r.step();
    expect(r.activeId, 'm6');
    expect(r.lastCondition, isFalse);
    r.runAll();
    expect(r.status, RunStatus.finished);
    expect(r.activeId, endId);
    expect(r.console.map((l) => l.text), contains('Il massimo è 8'));
  });

  test('"fino alla fine" riprende da solo dopo ogni input', () {
    final r = massimo()..runAll();
    expect(r.status, RunStatus.waitingInput);
    r.submitInput('5');
    expect(r.status, RunStatus.waitingInput);
    r.submitInput('2');
    expect(r.status, RunStatus.finished);
    expect(r.console.where((l) => l.kind == ConsoleKind.output).single.text, 'Il massimo è 5');
  });

  test('esecuzione automatica con la velocità scelta', () {
    fakeAsync((async) {
      final r = massimo()
        ..setSpeed(0.5)
        ..play();
      expect(r.status, RunStatus.playing);
      async.elapse(const Duration(milliseconds: 1100));
      expect(r.steps, 2);
      async.elapse(const Duration(seconds: 2));
      expect(r.status, RunStatus.waitingInput);
      r.submitInput('1');
      expect(r.status, RunStatus.playing);
      r.pause();
      final steps = r.steps;
      async.elapse(const Duration(seconds: 3));
      expect(r.steps, steps);
      r.dispose();
    });
  });

  test('ricomincia azzera console e variabili', () {
    final r = massimo()..runAll();
    r.submitInput('1');
    r.reset();
    expect(r.console, isEmpty);
    expect(r.variables, isEmpty);
    expect(r.status, RunStatus.ready);
  });
}
