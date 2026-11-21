// Testi della scheda App Store (store/app-store.md): limiti di Apple e
// standard privacy (niente «open source», «GDPR», né un pubblico di minori).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Campi di una lingua: titolo della sezione `###` → testo del blocco `text`.
Map<String, Map<String, String>> parseStoreTexts(String md) {
  final result = <String, Map<String, String>>{};
  Map<String, String>? lang;
  String? field;
  final block = StringBuffer();
  var inBlock = false;
  for (final line in md.split('\n')) {
    if (inBlock) {
      if (line == '```') {
        inBlock = false;
        if (lang != null && field != null) lang[field] = block.toString().trimRight();
        block.clear();
      } else {
        block.writeln(line);
      }
    } else if (line.startsWith('## ')) {
      final code = RegExp(r'^## ([a-z]{2}) — ').firstMatch(line)?.group(1);
      lang = code == null ? null : result.putIfAbsent(code, () => {});
      field = null;
    } else if (line.startsWith('### ')) {
      field = line.substring(4).trim();
    } else if (line == '```text') {
      inBlock = true;
    }
  }
  return result;
}

/// Nomi dei campi, nell'ordine: nome, sottotitolo, promozionale, parole chiave, descrizione.
const _fields = {
  'it': ['Nome', 'Sottotitolo', 'Testo promozionale', 'Parole chiave', 'Descrizione'],
  'en': ['Name', 'Subtitle', 'Promotional text', 'Keywords', 'Description'],
  'fr': ['Nom', 'Sous-titre', 'Texte promotionnel', 'Mots-clés', 'Description'],
  'de': ['Name', 'Untertitel', 'Werbetext', 'Schlüsselwörter', 'Beschreibung'],
  'es': ['Nombre', 'Subtítulo', 'Texto promocional', 'Palabras clave', 'Descripción'],
};

const _limits = [30, 30, 170, 100, 4000];

/// Parole vietate dallo standard privacy (§3, §5) in ogni lingua.
final _forbidden = RegExp(
  r'open.?source|gdpr|rgpd|dsgvo|bambin|ragazz|\bkids?\b|child|enfant|kinder|\bniñ|infantil|jugendlich',
  caseSensitive: false,
);

void main() {
  final md = File('store/app-store.md').readAsStringSync();
  final texts = parseStoreTexts(md);

  test('ci sono tutte e cinque le lingue con tutti i campi', () {
    expect(texts.keys.toSet(), _fields.keys.toSet());
    for (final MapEntry(key: lang, value: names) in _fields.entries) {
      for (final n in names) {
        expect(texts[lang]![n], isNotEmpty, reason: '$lang: $n');
      }
    }
  });

  for (final MapEntry(key: lang, value: names) in _fields.entries) {
    group(lang, () {
      String field(int i) => texts[lang]![names[i]]!;

      test('limiti di lunghezza di App Store Connect', () {
        for (var i = 0; i < names.length; i++) {
          expect(
            field(i).runes.length,
            lessThanOrEqualTo(_limits[i]),
            reason: '${names[i]}: ${field(i).runes.length} caratteri',
          );
        }
      });

      test('parole chiave: virgole senza spazi, nessun doppione né parola del nome', () {
        final keywords = field(3);
        expect(keywords, isNot(contains(', ')));
        final words = keywords.toLowerCase().split(',');
        expect(words.toSet().length, words.length, reason: 'doppioni');
        final inName = '${field(0)} ${field(1)}'.toLowerCase().split(RegExp(r'\s+')).toSet();
        expect(words.where(inName.contains), isEmpty);
      });

      test('frame adulto e nessun claim vietato', () {
        for (var i = 0; i < names.length; i++) {
          expect(_forbidden.hasMatch(field(i)), isFalse, reason: names[i]);
        }
      });

      test('la descrizione dichiara la privacy e il codice verificabile', () {
        final d = field(4).toLowerCase();
        expect(d, contains('source-available'));
        expect(d, contains('polyform noncommercial'));
      });
    });
  }

  test('note per la revisione in inglese, senza claim vietati', () {
    final notes = RegExp(
      r'### Note per la revisione.*?```text\n(.*?)```',
      dotAll: true,
    ).firstMatch(md)!.group(1)!;
    expect(notes, contains('No sign-in'));
    expect(_forbidden.hasMatch(notes), isFalse);
    expect(notes.length, lessThanOrEqualTo(4000));
  });
}
