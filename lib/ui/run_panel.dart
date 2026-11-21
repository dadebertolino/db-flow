import 'package:flutter/material.dart';

import '../i18n/tr.dart';
import '../render/theme.dart';
import 'run_controller.dart';
import 'sim_circuit.dart';

/// Pannello di esecuzione: comandi, velocità, variabili, console e input.
class RunPanel extends StatefulWidget {
  const RunPanel({super.key, required this.run, required this.compact});

  final RunController run;

  /// Telefono: variabili e console in schede; tablet: una sopra l'altra.
  final bool compact;

  @override
  State<RunPanel> createState() => _RunPanelState();
}

class _RunPanelState extends State<RunPanel> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: run.isArduino ? 3 : 2, vsync: this);

  /// Schede sul telefono: (Circuito,) Variabili, Console.
  int get _varTab => run.isArduino ? 1 : 0;
  int get _consoleTab => run.isArduino ? 2 : 1;
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _consoleScroll = ScrollController();
  String? _inputError;
  int _seenLines = 0;
  bool _wasWaiting = false;

  RunController get run => widget.run;

  @override
  void initState() {
    super.initState();
    run.addListener(_onRun);
  }

  @override
  void didUpdateWidget(RunPanel old) {
    super.didUpdateWidget(old);
    if (old.run != run) {
      old.run.removeListener(_onRun);
      run.addListener(_onRun);
    }
  }

  void _onRun() {
    final waiting = run.status == RunStatus.waitingInput;
    if (waiting && !_wasWaiting) {
      _input.clear();
      _inputError = null;
      if (widget.compact) _tabs.animateTo(_consoleTab);
      WidgetsBinding.instance.addPostFrameCallback((_) => _inputFocus.requestFocus());
    }
    _wasWaiting = waiting;
    if (run.consoleCount != _seenLines) {
      _seenLines = run.consoleCount;
      // Arduino scrive di continuo sulla seriale: si resta sul circuito,
      // tranne quando qualcosa va storto
      final show = run.isArduino
          ? run.status == RunStatus.failed
          : run.console.isNotEmpty && run.status != RunStatus.playing;
      if (widget.compact && show) {
        _tabs.animateTo(_consoleTab);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_consoleScroll.hasClients) {
          _consoleScroll.jumpTo(_consoleScroll.position.maxScrollExtent);
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    run.removeListener(_onRun);
    _tabs.dispose();
    _input.dispose();
    _inputFocus.dispose();
    _consoleScroll.dispose();
    super.dispose();
  }

  void _send() {
    final err = run.submitInput(_input.text);
    setState(() => _inputError = err);
    if (err == null) {
      _input.clear();
      // Sul telefono si torna alle variabili per vedere il valore appena letto.
      if (widget.compact && run.status != RunStatus.waitingInput && !run.isOver) {
        _tabs.animateTo(_varTab);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[
      _controls(),
      _statusLine(),
      if (run.status == RunStatus.waitingInput) _inputRow(),
      const Divider(height: 1),
    ];
    if (widget.compact) {
      children.addAll([
        TabBar(
          controller: _tabs,
          tabs: [
            if (run.isArduino) Tab(text: tr.circuit, height: 36),
            Tab(text: tr.variables, height: 36),
            Tab(text: tr.console, height: 36),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              if (run.isArduino) SimCircuit(run: run),
              _variables(),
              _console(),
            ],
          ),
        ),
      ]);
    } else {
      children.addAll([
        if (run.isArduino) ...[
          _sectionTitle(tr.circuit),
          Expanded(flex: 3, child: SimCircuit(run: run)),
          const Divider(height: 1),
        ],
        _sectionTitle(tr.variables),
        Expanded(flex: 2, child: _variables()),
        const Divider(height: 1),
        _sectionTitle(tr.console),
        Expanded(flex: 3, child: _console()),
      ]);
    }
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        left: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Text(t, style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _controls() {
    final playing = run.status == RunStatus.playing;
    final waiting = run.status == RunStatus.waitingInput;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: tr.restart,
                icon: const Icon(Icons.replay),
                onPressed: run.status == RunStatus.ready ? null : run.reset,
              ),
              IconButton.filled(
                tooltip: playing ? tr.pause : tr.run,
                iconSize: 30,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: waiting ? null : (playing ? run.pause : run.play),
              ),
              IconButton.filledTonal(
                tooltip: tr.oneStep,
                icon: const Icon(Icons.skip_next),
                onPressed: waiting || run.isOver ? null : run.step,
              ),
              IconButton(
                tooltip: run.isArduino ? tr.toLoopEnd : tr.toEnd,
                icon: const Icon(Icons.fast_forward),
                onPressed: waiting ? null : run.runAll,
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.speed, size: 18),
              Expanded(
                child: Slider(
                  value: 2.1 - run.speed,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  label: '${run.speed.toStringAsFixed(1)} s',
                  onChanged: (v) => run.setSpeed(double.parse((2.1 - v).toStringAsFixed(1))),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${run.speed.toStringAsFixed(1)} s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusLine() {
    final dc = DiagramColors.of(context);
    // Arduino: il programma non finisce, conta il giro di loop() e il tempo
    final arduinoState = run.isArduino
        ? '${run.loops == 0 ? 'setup()' : tr.simLoop(run.loops)} · millis() = ${run.board!.millis()}'
        : null;
    final (text, color, icon) = switch (run.status) {
      RunStatus.ready => (tr.statusReady, null, Icons.flag_outlined),
      RunStatus.paused => (
        arduinoState ?? tr.statusPaused(run.steps),
        null,
        Icons.pause_circle_outline,
      ),
      RunStatus.playing => (
        arduinoState ?? tr.statusRunning(run.steps),
        dc.active,
        Icons.directions_run,
      ),
      RunStatus.waitingInput => (
        tr.statusWaiting(run.waitingFor?.variable ?? '', run.waitingFor?.type.label ?? ''),
        dc.selection,
        Icons.keyboard,
      ),
      RunStatus.finished => (tr.statusFinished(run.steps), dc.active, Icons.check_circle_outline),
      RunStatus.failed => (tr.statusFailed, dc.error, Icons.error_outline),
    };
    final cond = run.lastCondition;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
          if (cond != null && run.status != RunStatus.finished)
            Chip(
              label: Text(tr.condition(cond)),
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(color: cond ? dc.active : dc.error, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _inputRow() {
    final w = run.waitingFor!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              focusNode: _inputFocus,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.send,
              keyboardType: switch (w.type.name) {
                'integer' => const TextInputType.numberWithOptions(signed: true),
                'real' => const TextInputType.numberWithOptions(signed: true, decimal: true),
                _ => TextInputType.text,
              },
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                labelText: '${w.variable} (${w.type.label})',
                errorText: _inputError,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _send, child: Text(tr.send)),
        ],
      ),
    );
  }

  Widget _variables() {
    final vars = run.variables.toList();
    if (vars.isEmpty) {
      return Center(child: Text(tr.noVariablesYet));
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final v in vars)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: v.name == run.changedVar ? const Color(0x55FFD54F) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(v.name, style: monoStyle.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(flex: 2, child: Text(v.type.label, style: theme.textTheme.bodySmall)),
                Expanded(
                  flex: 4,
                  child: Text(
                    v.value == null
                        ? '—'
                        : v.value!.type.name == 'string'
                        ? '"${v.value!.display}"'
                        : v.value!.display,
                    style: monoStyle.copyWith(color: v.value == null ? theme.disabledColor : null),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _console() {
    if (run.console.isEmpty) {
      return Center(child: Text(tr.consoleEmpty));
    }
    return Container(
      color: const Color(0xFF1E1E1E),
      child: ListView.builder(
        controller: _consoleScroll,
        padding: const EdgeInsets.all(10),
        itemCount: run.console.length,
        itemBuilder: (_, i) {
          final l = run.console[i];
          final color = switch (l.kind) {
            ConsoleKind.output => const Color(0xFFEDEDED),
            ConsoleKind.input => const Color(0xFF8AB4F8),
            ConsoleKind.error => const Color(0xFFFF8A80),
            ConsoleKind.info => const Color(0xFF9CCC65),
          };
          return SelectableText.rich(
            arrowSpan(
              l.kind == ConsoleKind.input ? '> ${l.text}' : l.text,
              monoStyle.copyWith(color: color),
            ),
          );
        },
      ),
    );
  }
}
