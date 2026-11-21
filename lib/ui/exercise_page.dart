import 'package:flutter/material.dart';

import '../i18n/tr.dart';
import '../model/exercise.dart';
import '../model/program.dart';
import '../render/theme.dart';
import '../runtime/exercise_check.dart';

/// Righe di un campo di testo, senza le righe vuote finali.
List<String> _lines(String text) {
  final l = text.split('\n');
  while (l.isNotEmpty && l.last.trim().isEmpty) {
    l.removeLast();
  }
  return l;
}

String _problem(CaseOutcome o, String? error) => switch (o) {
  CaseOutcome.passed => '',
  CaseOutcome.wrongOutput => tr.outcomeWrongOutput,
  CaseOutcome.missingInput => tr.outcomeMissingInput,
  CaseOutcome.unusedInput => tr.outcomeUnusedInput,
  CaseOutcome.badInput => tr.outcomeBadInput(error ?? ''),
  CaseOutcome.error => tr.outcomeError(error ?? ''),
};

Widget _sectionTitle(BuildContext context, String t) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
  child: Text(
    t,
    style: Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.primary),
  ),
);

/// Righe monospazio dentro un riquadro; [empty] se non ce ne sono.
class _MonoBox extends StatelessWidget {
  const _MonoBox(this.lines, {required this.empty});
  final List<String> lines;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        lines.isEmpty ? empty : lines.join('\n'),
        style: monoStyle.copyWith(color: lines.isEmpty ? Theme.of(context).disabledColor : null),
      ),
    );
  }
}

// ================================================================ consegna

/// Consegna e casi di prova. Il docente li modifica; un esercizio ricevuto
/// ([Exercise.locked]) si legge soltanto e non mostra i casi nascosti.
///
/// All'uscita chiama [onDone] con l'esercizio aggiornato.
class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.program,
    required this.exercise,
    required this.onDone,
    this.onRemove,
  });

  /// Diagramma corrente: serve a calcolare l'output atteso.
  final Program program;
  final Exercise exercise;
  final ValueChanged<Exercise> onDone;
  final VoidCallback? onRemove;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _CaseFields {
  _CaseFields(TestCase c)
    : inputs = TextEditingController(text: c.inputs.join('\n')),
      expected = TextEditingController(text: c.expected.join('\n')),
      hidden = c.hidden;

  final TextEditingController inputs;
  final TextEditingController expected;
  bool hidden;
  String? problem;

  TestCase get value =>
      TestCase(inputs: _lines(inputs.text), expected: _lines(expected.text), hidden: hidden);

  void dispose() {
    inputs.dispose();
    expected.dispose();
  }
}

class _ExercisePageState extends State<ExercisePage> {
  late final _text = TextEditingController(text: widget.exercise.text);
  late final _cases = [for (final c in widget.exercise.cases) _CaseFields(c)];
  bool _removed = false;

  bool get _locked => widget.exercise.locked;

  Exercise get _value =>
      widget.exercise.copyWith(text: _text.text.trim(), cases: [for (final c in _cases) c.value]);

  @override
  void dispose() {
    _text.dispose();
    for (final c in _cases) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill() {
    var filled = 0;
    setState(() {
      for (final c in _cases) {
        final r = runWithInputs(widget.program, c.value.inputs);
        if (r.outcome == CaseOutcome.passed) {
          c.expected.text = r.output.join('\n');
          c.problem = null;
          filled++;
        } else {
          c.problem = _problem(r.outcome, r.error);
        }
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tr.filledCases(filled))));
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.removeExercise),
        content: Text(tr.removeExerciseBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr.remove)),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      _removed = true;
      widget.onRemove?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_removed && !_locked) widget.onDone(_value);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.exercise),
          actions: [
            if (!_locked && widget.onRemove != null)
              IconButton(
                tooltip: tr.removeExercise,
                icon: const Icon(Icons.delete_outline),
                onPressed: _remove,
              ),
          ],
        ),
        body: _locked ? _readOnly(context) : _editor(context),
      ),
    );
  }

  Widget _readOnly(BuildContext context) {
    final e = widget.exercise;
    final visible = e.visibleCases;
    final hidden = e.cases.length - visible.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _sectionTitle(context, tr.exerciseText),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SelectableText(e.text.isEmpty ? '—' : e.text),
        ),
        _sectionTitle(context, tr.testCases),
        for (var i = 0; i < visible.length; i++)
          _CaseView(title: tr.testCase(i + 1), testCase: visible[i]),
        if (hidden > 0)
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text(tr.hiddenCasesCount(hidden)),
          ),
        if (e.cases.isEmpty) ListTile(title: Text(tr.noCases)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr.exerciseLocked, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editor(BuildContext context) {
    final error = DiagramColors.of(context).error;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _sectionTitle(context, tr.exerciseText),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _text,
            minLines: 3,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: tr.exerciseTextHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _sectionTitle(context, tr.testCases),
        if (_cases.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(tr.noCases)),
        for (var i = 0; i < _cases.length; i++)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr.testCase(i + 1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: tr.removeCase,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _cases.removeAt(i).dispose()),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _linesField(_cases[i].inputs, tr.caseInputs, tr.caseInputsHint),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _linesField(
                            _cases[i].expected,
                            tr.caseExpected,
                            tr.caseExpectedHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_cases[i].problem case final p?)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Text(p, style: TextStyle(color: error)),
                    ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(right: 4),
                    dense: true,
                    title: Text(tr.caseHidden),
                    value: _cases[i].hidden,
                    onChanged: (v) => setState(() => _cases[i].hidden = v),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => setState(() => _cases.add(_CaseFields(TestCase()))),
                icon: const Icon(Icons.add),
                label: Text(tr.addCase),
              ),
              if (_cases.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _fill,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(tr.fillFromDiagram),
                ),
            ],
          ),
        ),
        if (_cases.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(tr.fillFromDiagramHelp, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget _linesField(TextEditingController c, String label, String hint) => TextField(
    controller: c,
    minLines: 2,
    maxLines: 8,
    style: monoStyle,
    decoration: InputDecoration(
      labelText: label,
      helperText: hint,
      helperMaxLines: 3,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );
}

/// Caso di prova in sola lettura: dati in ingresso e output atteso.
class _CaseView extends StatelessWidget {
  const _CaseView({required this.title, required this.testCase});
  final String title;
  final TestCase testCase;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(tr.caseInputs, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          _MonoBox(testCase.inputs, empty: tr.noInputs),
          const SizedBox(height: 8),
          Text(tr.caseExpected, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          _MonoBox(testCase.expected, empty: tr.noOutput),
        ],
      ),
    ),
  );
}

// ================================================================ risultati

/// Esito della verifica: per ogni caso, superato o no; per i casi visibili
/// anche dati, output atteso e ottenuto.
class ExerciseResultsPage extends StatelessWidget {
  const ExerciseResultsPage({super.key, required this.results});

  final List<CaseResult> results;

  @override
  Widget build(BuildContext context) {
    final dc = DiagramColors.of(context);
    final ok = results.where((r) => r.passed).length;
    final all = ok == results.length;
    var visibleIndex = 0;
    return Scaffold(
      appBar: AppBar(title: Text(tr.verifyResults)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: Icon(
              all ? Icons.emoji_events_outlined : Icons.rule,
              size: 36,
              color: all ? dc.active : dc.warning,
            ),
            title: Text(
              all ? tr.verifyAllPassed : tr.verifyPassed(ok, results.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          for (final r in results)
            if (r.testCase.hidden)
              _resultTile(context, dc, tr.hiddenCase, r, details: false)
            else
              _resultTile(context, dc, tr.testCase(++visibleIndex), r, details: true),
        ],
      ),
    );
  }

  Widget _resultTile(
    BuildContext context,
    DiagramColors dc,
    String title,
    CaseResult r, {
    required bool details,
  }) {
    final status = Row(
      children: [
        Icon(
          r.passed ? Icons.check_circle : Icons.cancel,
          color: r.passed ? dc.active : dc.error,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text(
          r.passed ? tr.casePassed : tr.caseFailed,
          style: TextStyle(color: r.passed ? dc.active : dc.error),
        ),
      ],
    );
    final label = Theme.of(context).textTheme.labelMedium;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            status,
            if (details) ...[
              const SizedBox(height: 10),
              Text(tr.caseInputs, style: label),
              const SizedBox(height: 2),
              _MonoBox(r.testCase.inputs, empty: tr.noInputs),
              if (!r.passed) ...[
                const SizedBox(height: 8),
                Text(tr.caseExpected, style: label),
                const SizedBox(height: 2),
                _MonoBox(r.testCase.expected, empty: tr.noOutput),
              ],
              const SizedBox(height: 8),
              Text(tr.caseActual, style: label),
              const SizedBox(height: 2),
              _MonoBox(r.output, empty: tr.noOutput),
              if (!r.passed) ...[
                const SizedBox(height: 8),
                Text(_problem(r.outcome, r.error), style: TextStyle(color: dc.error)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================ riquadro nell'editor

/// Consegna in cima all'editor, con il pulsante "Verifica".
class ExerciseBanner extends StatelessWidget {
  const ExerciseBanner({
    super.key,
    required this.exercise,
    required this.onOpen,
    required this.onVerify,
    this.lastResult,
  });

  final Exercise exercise;
  final VoidCallback onOpen;
  final VoidCallback onVerify;

  /// Ultima verifica sul diagramma attuale: (superati, totale).
  final (int, int)? lastResult;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dc = DiagramColors.of(context);
    final last = lastResult;
    return Material(
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            children: [
              Icon(Icons.assignment_outlined, color: scheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  hint: tr.showTask,
                  child: Text(
                    exercise.text.isEmpty ? tr.exercise : exercise.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ),
              if (last != null) ...[
                const SizedBox(width: 8),
                Icon(
                  last.$1 == last.$2 ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: last.$1 == last.$2 ? dc.active : dc.error,
                ),
                const SizedBox(width: 2),
                Text('${last.$1}/${last.$2}', style: TextStyle(color: scheme.onSecondaryContainer)),
              ],
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onVerify,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(tr.verify),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
