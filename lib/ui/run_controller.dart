import 'dart:async';

import 'package:flutter/foundation.dart';

import '../i18n/tr.dart';
import '../layout/layout_engine.dart' show endId, loopId, startId;
import '../model/program.dart';
import '../runtime/environment.dart';
import '../runtime/interpreter.dart';
import '../runtime/sim_board.dart';

enum RunStatus { ready, paused, playing, waitingInput, finished, failed }

enum ConsoleKind { output, input, error, info }

final class ConsoleLine {
  const ConsoleLine(this.text, this.kind);
  final String text;
  final ConsoleKind kind;
}

/// Stato di un'esecuzione: interprete, blocco corrente, console, velocità.
class RunController extends ChangeNotifier {
  RunController(this.program) {
    reset();
  }

  final Program program;
  late Interpreter _it;
  Timer? _timer;

  RunStatus status = RunStatus.ready;

  /// Blocco evidenziato ([startId] prima di partire, [endId] alla fine).
  String? activeId;

  /// Variabile modificata nell'ultimo passo.
  String? changedVar;

  /// Esito dell'ultima condizione valutata (per il blocco attivo).
  bool? lastCondition;

  final console = <ConsoleLine>[];

  /// Righe scritte in tutto (la console tiene solo le ultime [maxConsoleLines]).
  int consoleCount = 0;
  static const maxConsoleLines = 500;

  void _log(String text, ConsoleKind kind) {
    console.add(ConsoleLine(text, kind));
    consoleCount++;
    if (console.length > maxConsoleLines) console.removeRange(0, console.length - maxConsoleLines);
  }

  /// Secondi tra un passo e l'altro in modalità "Esegui" (0.1–2).
  double speed = 0.6;

  Iterable<Variable> get variables => _it.env.all;
  int get steps => _it.steps;
  InputRequest? get waitingFor => _it.waitingFor;
  bool get isOver => status == RunStatus.finished || status == RunStatus.failed;

  /// Scheda simulata (diagrammi Arduino), altrimenti `null`.
  SimBoard? get board => _it.board;
  bool get isArduino => program.isArduino;

  /// Arduino: giro di `loop()` in corso (0 durante `setup()`).
  int get loops => _it.loops;

  /// Arduino: attesa (ms) dell'ultimo blocco `delay`, per i tempi reali.
  int _lastDelay = 0;

  // ------------------------------------------------------------ comandi sulla scheda

  void setPressed(String pin, bool pressed) {
    board?.setPressed(pin, pressed);
    notifyListeners();
  }

  void setHighInput(String pin, bool high) {
    board?.setHighInput(pin, high);
    notifyListeners();
  }

  void setAnalog(String pin, int value) {
    board?.setAnalog(pin, value);
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    _resume = _Resume.none;
    // la scheda (pulsanti, potenziometri) resta com'era: si riparte dal programma
    final previous = _started ? _it.board : null;
    _started = true;
    _it = Interpreter(program, board: previous?.restarted());
    status = RunStatus.ready;
    activeId = startId;
    changedVar = null;
    lastCondition = null;
    console.clear();
    consoleCount = 0;
    notifyListeners();
  }

  /// Un solo passo.
  void step() {
    if (isOver || status == RunStatus.waitingInput) return;
    _stopTimer();
    status = RunStatus.paused;
    _resume = _Resume.none;
    _advance();
    notifyListeners();
  }

  /// Esecuzione automatica a velocità [speed].
  void play() {
    if (isOver) reset();
    if (status == RunStatus.waitingInput) return;
    status = RunStatus.playing;
    _resume = _Resume.play;
    _schedule();
    notifyListeners();
  }

  void pause() {
    if (status != RunStatus.playing) return;
    _stopTimer();
    status = RunStatus.paused;
    _resume = _Resume.none;
    notifyListeners();
  }

  /// Esegue fino a una richiesta di input o alla fine; per Arduino, fino alla
  /// fine del giro di `loop()` in corso (loop() non finisce mai).
  void runAll() {
    if (isOver) reset();
    _stopTimer();
    if (status == RunStatus.waitingInput) return;
    status = RunStatus.paused;
    _resume = _Resume.all;
    var first = true;
    while (!isOver && status != RunStatus.waitingInput) {
      final ev = _advance();
      if (isArduino && ev is LoopStart && !first) break;
      first = false;
    }
    notifyListeners();
  }

  void setSpeed(double s) {
    speed = s;
    if (status == RunStatus.playing) _schedule();
    notifyListeners();
  }

  /// Come riprendere dopo un input: fermo, automatico o fino alla fine.
  _Resume _resume = _Resume.none;

  /// Invia il testo scritto dall'utente. Restituisce un messaggio d'errore se
  /// il valore non è valido (l'esecuzione resta in attesa).
  String? submitInput(String text) {
    final w = _it.waitingFor;
    if (w == null) return null;
    final parsed = parseInput(text, w.type);
    if (parsed.error != null) return parsed.error;
    _it.provideInput(parsed.value!);
    _log('${w.variable} ← ${parsed.value!.display}', ConsoleKind.input);
    changedVar = w.variable;
    status = RunStatus.paused;
    switch (_resume) {
      case _Resume.play:
        status = RunStatus.playing;
        _schedule();
      case _Resume.all:
        runAll();
      case _Resume.none:
        break;
    }
    notifyListeners();
    return null;
  }

  bool _started = false;

  RunEvent _advance() {
    final ev = _it.next();
    changedVar = null;
    lastCondition = null;
    _lastDelay = 0;
    switch (ev) {
      case LoopStart():
        activeId = loopId;
      case StepEvent(
        :final blockId,
        :final output,
        :final changed,
        :final condition,
        :final delayMs,
      ):
        activeId = blockId;
        changedVar = changed;
        lastCondition = condition;
        _lastDelay = delayMs ?? 0;
        if (output != null) _log(output, ConsoleKind.output);
      case InputRequest(:final blockId):
        activeId = blockId;
        _stopTimer();
        status = RunStatus.waitingInput;
      case Finished():
        activeId = endId;
        _stopTimer();
        status = RunStatus.finished;
        _log(tr.runFinished(_it.steps), ConsoleKind.info);
      case Failed(:final blockId, :final message):
        activeId = blockId;
        _stopTimer();
        status = RunStatus.failed;
        _log(tr.runErrorLine(message), ConsoleKind.error);
    }
    return ev;
  }

  /// Prossimo passo dopo [speed] secondi; dopo un `delay`, almeno quanto il
  /// delay (così un LED lampeggia con il ritmo del programma).
  void _schedule() {
    _timer?.cancel();
    final ms = (speed * 1000).round();
    _timer = Timer(Duration(milliseconds: _lastDelay > ms ? _lastDelay : ms), () {
      if (status != RunStatus.playing) {
        _stopTimer();
        return;
      }
      _advance();
      if (status == RunStatus.playing) _schedule();
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

enum _Resume { none, play, all }
