import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../codegen/generator.dart';
import '../i18n/tr.dart';
import '../io/share.dart';
import '../model/program.dart';
import '../model/validator.dart';
import '../render/theme.dart';

/// Codice generato dal diagramma, in tre linguaggi.
class CodePage extends StatelessWidget {
  const CodePage({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    final hasIssues = validate(program).isNotEmpty;
    final error = DiagramColors.of(context).error;
    return DefaultTabController(
      length: CodeLanguage.forProgram(program).length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.code),
          bottom: TabBar(
            tabs: [for (final l in CodeLanguage.forProgram(program)) Tab(text: l.label)],
          ),
        ),
        body: Column(
          children: [
            if (hasIssues)
              Material(
                color: error.withValues(alpha: 0.08),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.warning_amber, color: error),
                  title: Text(tr.codeHasErrors),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final l in CodeLanguage.forProgram(program))
                    _CodeView(program: program, language: l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeView extends StatelessWidget {
  const _CodeView({required this.program, required this.language});

  final Program program;
  final CodeLanguage language;

  @override
  Widget build(BuildContext context) {
    final code = generateCode(program, language);
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText.rich(arrowSpan(code, monoStyle)),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Row(
              children: [
                FloatingActionButton.small(
                  heroTag: 'copy-${language.name}',
                  tooltip: tr.copy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(tr.codeCopied)));
                    }
                  },
                  child: const Icon(Icons.copy),
                ),
                const SizedBox(width: 12),
                Builder(
                  builder: (btn) => FloatingActionButton.small(
                    heroTag: 'share-${language.name}',
                    tooltip: isDesktop ? tr.saveAs : tr.share,
                    onPressed: () async {
                      if (language != CodeLanguage.arduino) {
                        return shareBytes(
                          utf8.encode(code),
                          fileName: '${safeFileName(program.name)}.${language.extension}',
                          mimeType: 'text/plain',
                          origin: shareOrigin(btn),
                        );
                      }
                      final path = await saveArduinoSketch(
                        code,
                        program.name,
                        origin: shareOrigin(btn),
                      );
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(tr.sketchSaved(path))));
                      }
                    },
                    child: Icon(isDesktop ? Icons.save_alt : Icons.ios_share),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
