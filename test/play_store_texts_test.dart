// Testi della scheda Google Play (store/play-store.md): limiti di Google e
// standard privacy (niente «open source», «GDPR», né un pubblico di minori).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'store_texts_test.dart' show parseStoreTexts;

/// Nomi dei campi, nell'ordine: nome, breve descrizione, descrizione completa.
const _fields = {
  'it': ["Nome dell'app", 'Breve descrizione', 'Descrizione completa'],
  'en': ['App name', 'Short description', 'Full description'],
  'fr': ["Nom de l'application", 'Brève description', 'Description complète'],
  'de': ['App-Name', 'Kurzbeschreibung', 'Vollständige Beschreibung'],
  'es': ['Nombre de la aplicación', 'Descripción breve', 'Descripción completa'],
};

const _limits = [30, 80, 4000];

/// Parole vietate dallo standard privacy in ogni lingua, più i nomi dei
/// dispositivi Apple (la scheda è per Android).
final _forbidden = RegExp(
  r'open.?source|gdpr|rgpd|dsgvo|bambin|ragazz|\bkids?\b|child|enfant|kinder|\bniñ|infantil|jugendlich'
  r'|iphone|ipad|\bmac\b',
  caseSensitive: false,
);

void main() {
  final texts = parseStoreTexts(File('store/play-store.md').readAsStringSync());

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

      test('limiti di lunghezza di Google Play', () {
        for (var i = 0; i < names.length; i++) {
          expect(
            field(i).runes.length,
            lessThanOrEqualTo(_limits[i]),
            reason: '${names[i]}: ${field(i).runes.length} caratteri',
          );
        }
      });

      test('il nome inizia con DB Flow, senza emoji né claim', () {
        expect(field(0), startsWith('DB Flow'));
        expect(
          field(0),
          isNot(matches(RegExp(r'gratis|free|gratuit|kostenlos|#1|best', caseSensitive: false))),
        );
      });

      test('frame adulto, nessun claim vietato, solo Android', () {
        for (var i = 0; i < names.length; i++) {
          expect(_forbidden.hasMatch(field(i)), isFalse, reason: names[i]);
        }
      });

      test('la descrizione dichiara la privacy e il codice verificabile', () {
        final d = field(2).toLowerCase();
        expect(d, contains('source-available'));
        expect(d, contains('polyform noncommercial'));
        expect(d, contains('android'));
      });
    });
  }
}
