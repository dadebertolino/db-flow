import 'dart:io';

import 'package:db_flow/app.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => setLanguage(AppLanguage.it));

  test('lingua dalle preferenze del dispositivo, inglese se nessuna è supportata', () {
    expect(
      resolveLocale([const Locale('pt', 'BR'), const Locale('de')], supportedLocales),
      const Locale('de'),
    );
    expect(resolveLocale([const Locale('fr', 'CA')], supportedLocales), const Locale('fr'));
    expect(resolveLocale([const Locale('ja')], supportedLocales), const Locale('en'));
    expect(resolveLocale(null, supportedLocales), const Locale('en'));
    expect(supportedLocales.map((l) => l.languageCode), ['it', 'en', 'fr', 'de', 'es']);
  });

  for (final lang in AppLanguage.values) {
    testWidgets('l\'app si apre in ${lang.nativeName}', (tester) async {
      final tmp = Directory.systemTemp.createTempSync('dbflow_locale');
      addTearDown(() => tmp.deleteSync(recursive: true));
      await tester.pumpWidget(
        DbFlowApp(
          storage: FlowStorage(baseDir: () async => tmp),
          locale: Locale(lang.name),
          splashDuration: Duration.zero,
        ),
      );
      await tester.pump();
      expect(tr.language, lang);
      expect(find.text(trFor(lang).newDiagram), findsOneWidget);
      expect(find.byTooltip(trFor(lang).info), findsOneWidget);
    });
  }
}
