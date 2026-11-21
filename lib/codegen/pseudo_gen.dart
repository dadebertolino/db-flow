/// Pseudocodice nella lingua corrente (parole chiave secondo l'uso scolastico). Dart puro.
library;

import '../i18n/tr.dart';
import '../layout/labels.dart';
import '../model/stmt.dart';
import 'generator.dart';

final class PseudoGenerator extends BaseGenerator {
  PseudoGenerator(super.program);

  final _w = CodeWriter('    ');

  @override
  String generate() {
    if (program.arduino case final cfg?) {
      _w.line(tr.pSketch(program.name, cfg.board.name));
      for (final p in cfg.pins) {
        _w.line(tr.pPin(p.name, p.pin, p.mode.label));
      }
      _w.line(tr.pSetup);
      _w.indented(() => _block(program.setup));
      _w.line(tr.pEndSetup);
      _w.line(tr.pLoop);
      _w.indented(() => _block(program.body));
      _w.line(tr.pEndLoop);
      return _w.toString();
    }
    _w.line(tr.pAlgorithm(program.name));
    _w.line(tr.pBegin);
    _w.indented(() => _block(program.body));
    _w.line(tr.pEnd);
    return _w.toString();
  }

  void _block(List<Stmt> list) {
    for (final s in list) {
      _stmt(s);
    }
  }

  static String _t(String s) => s.trim().isEmpty ? '?' : s.trim();

  void _stmt(Stmt s) {
    switch (s) {
      case Declare(:final name, :final type):
        _w.line(tr.pDeclare(_t(name), type.label));
      case Assign(:final target, :final value):
        _w.line('${_t(target)} ← ${_t(value.text)}');
      case Input(:final variable):
        _w.line(tr.pRead(_t(variable)));
      case Output(:final value):
        _w.line(tr.pWrite(_t(value.text)));
      case If(:final cond, :final then, :final otherwise):
        _w.line(tr.pIf(_t(cond.text)));
        _w.indented(() => _block(then));
        if (otherwise.isNotEmpty) {
          _w.line(tr.pElse);
          _w.indented(() => _block(otherwise));
        }
        _w.line(tr.pEndIf);
      case While(:final cond, :final body):
        _w.line(tr.pWhile(_t(cond.text)));
        _w.indented(() => _block(body));
        _w.line(tr.pEndWhile);
      case DoWhile(:final cond, :final body):
        _w.line(tr.pRepeat);
        _w.indented(() => _block(body));
        _w.line(tr.pRepeatWhile(_t(cond.text)));
      case For(:final variable, :final from, :final to, :final step, :final body):
        _w.line(
          tr.pFor(
            _t(variable),
            _t(from.text),
            _t(to.text),
            step.text.trim() == '1' ? null : _t(step.text),
          ),
        );
        _w.indented(() => _block(body));
        _w.line(tr.pEndFor);
      case DigitalWrite() || AnalogWrite() || DigitalRead() || AnalogRead() || Delay():
        _w.line(blockLabel(s));
      case Comment(:final text):
        for (final l in text.split('\n')) {
          _w.line('// $l');
        }
    }
  }
}
