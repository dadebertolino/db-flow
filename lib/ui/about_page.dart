import 'package:flutter/material.dart';

import '../app_info.dart';
import '../expr/functions.dart';
import '../i18n/tr.dart';
import '../layout/layout_engine.dart';
import '../render/block_widget.dart';
import '../render/theme.dart';
import 'privacy_page.dart';

/// Schermata «Informazioni»: app, privacy, mini-guida, licenze.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget section(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        t,
        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
      ),
    );
    Widget para(String t) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(t));

    return Scaffold(
      appBar: AppBar(title: Text(tr.info)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset('assets/icon/icon.png', width: 96, height: 96),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(appName, style: theme.textTheme.headlineSmall)),
          Center(child: Text(tr.version(appVersion), style: theme.textTheme.bodySmall)),
          const SizedBox(height: 8),
          para(tr.aboutDescription),
          para(tr.madeBy(appAuthor)),

          section(tr.privacy),
          for (final (icon, text) in [
            (Icons.person_off_outlined, tr.noAccount),
            (Icons.block, tr.noAds),
            (Icons.visibility_off_outlined, tr.noDataCollection),
            (Icons.phone_iphone, tr.dataStaysOnDevice),
          ])
            ListTile(dense: true, leading: Icon(icon), title: Text(text)),
          para(tr.privacySummary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(tr.privacyPolicy),
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const PrivacyPage())),
            ),
          ),

          section(tr.guideBlocks),
          for (final (shape, (title, text)) in [
            for (var i = 0; i < _guideShapes.length; i++) (_guideShapes[i], tr.guideBlockItems[i]),
          ])
            ListTile(
              leading: SizedBox(
                width: 56,
                height: 30,
                child: CustomPaint(painter: _ShapeIcon(shape, DiagramColors.of(context))),
              ),
              title: Text(title),
              subtitle: Text(text),
            ),

          section(tr.guideExpressions),
          _table(context, tr.guideExpressionItems),
          para(tr.availableFunctions),
          _table(context, [for (final f in builtinFunctions.values) (f.signature, f.description)]),

          section(tr.license),
          para(tr.licenseText(appLicense)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.description_outlined),
              label: Text(tr.componentLicenses),
              onPressed: () => showLicensePage(
                context: context,
                applicationName: appName,
                applicationVersion: appVersion,
                applicationLegalese: '© $appAuthor — $appLicense',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _table(BuildContext context, List<(String, String)> rows) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final (a, b) in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 16, 6),
                child: Text(a, style: monoStyle.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(b),
            ],
          ),
      ],
    ),
  );
}

/// Forme della guida, nell'ordine di [Tr.guideBlockItems].
const _guideShapes = [
  Shape.terminal,
  Shape.declare,
  Shape.process,
  Shape.io,
  Shape.decision,
  Shape.loop,
  Shape.pinIo,
  Shape.hardware,
];

class _ShapeIcon extends CustomPainter {
  _ShapeIcon(this.shape, this.colors);
  final Shape shape;
  final DiagramColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors.shape(shape);
    paintBlockShape(canvas, size, shape, fill: c.fill, stroke: c.stroke, strokeWidth: 1.4);
  }

  @override
  bool shouldRepaint(_ShapeIcon old) => old.shape != shape || old.colors != colors;
}
