// L'informativa sulla privacy afferma che l'app non usa la rete e non contiene
// servizi di terze parti: questi test lo verificano sul codice, così
// l'informativa non può diventare falsa senza che la CI se ne accorga.
import 'dart:io';

import 'package:db_flow/app_info.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/ui/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  test('nessun codice di rete nell\'app', () {
    final network = RegExp(
      r'HttpClient|package:http/|WebSocket|Socket\.connect|RawSocket|package:dio|'
      r'package:web_socket|InternetAddress|package:url_launcher',
    );
    for (final f in _dartFiles('lib')) {
      expect(network.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('nessuna dipendenza di rete o di terze parti nel pubspec', () {
    final deps = File('pubspec.yaml').readAsStringSync().split('dev_dependencies:').first;
    for (final banned in ['http:', 'dio:', 'url_launcher', 'firebase', 'sentry', 'analytics']) {
      expect(deps.contains(banned), isFalse, reason: banned);
    }
  });

  test('nessuna affermazione vietata nei testi dell\'app', () {
    final banned = RegExp(
      r'open source|open-source|conforme (al )?GDPR|GDPR compliant',
      caseSensitive: false,
    );
    for (final f in _dartFiles('lib')) {
      expect(banned.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  testWidgets('l\'informativa si apre e contiene i punti essenziali', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
    final text = tr
        .privacySections(appName, appAuthor, appLicense, appContact)
        .expand((s) => s.$2)
        .join(' ');
    for (final must in [
      'non raccoglie, non trasmette e non vende dati personali',
      'Non serve un account',
      'non invia nulla in rete',
      'Nessun sistema di analisi',
      'solo quando scegli tu',
      'Disinstallando',
      'info@davidebertolino.it',
    ]) {
      expect(text, contains(must));
    }
    expect(find.textContaining('Ultimo aggiornamento'), findsOneWidget);
    expect(find.text('In breve'), findsOneWidget);
  });

  test("il contatto c'è nell'informativa in tutte le lingue", () {
    for (final l in AppLanguage.values) {
      final text = trFor(l)
          .privacySections(appName, appAuthor, appLicense, appContact)
          .expand((s) => s.$2)
          .join(' ');
      expect(text, contains('info@davidebertolino.it'), reason: l.name);
    }
  });
}
