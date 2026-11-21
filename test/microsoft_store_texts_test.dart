// Testi della scheda Microsoft Store (store/microsoft-store.md): limiti di
// Partner Center e standard privacy (niente «open source», «GDPR», né un
// pubblico di minori).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'store_texts_test.dart' show parseStoreTexts;

/// Nomi dei campi, nell'ordine: descrizione, funzionalità, termini di ricerca.
const _fields = {
  'it': ['Descrizione', 'Funzionalità del prodotto', 'Termini di ricerca'],
  'en': ['Description', 'Product features', 'Search terms'],
  'fr': ['Description', 'Fonctionnalités du produit', 'Termes de recherche'],
  'de': ['Beschreibung', 'Produktfunktionen', 'Suchbegriffe'],
  'es': ['Descripción', 'Características del producto', 'Términos de búsqueda'],
};

/// Parole vietate dallo standard privacy in ogni lingua.
final _forbidden = RegExp(
  r'open.?source|gdpr|rgpd|dsgvo|bambin|ragazz|\bkids?\b|child|enfant|kinder|\bniñ|infantil|jugendlich',
  caseSensitive: false,
);

void main() {
  final md = File('store/microsoft-store.md').readAsStringSync();
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

      test('descrizione entro 10.000 caratteri, con privacy e Windows', () {
        final d = field(0);
        expect(d.runes.length, lessThanOrEqualTo(10000));
        expect(d.toLowerCase(), contains('source-available'));
        expect(d.toLowerCase(), contains('polyform noncommercial'));
        expect(d, contains('Windows'));
      });

      test('funzionalità: al massimo 20 righe da 200 caratteri', () {
        final lines = field(1).split('\n').where((l) => l.trim().isNotEmpty).toList();
        expect(lines.length, inInclusiveRange(1, 20));
        for (final l in lines) {
          expect(l.runes.length, lessThanOrEqualTo(200), reason: l);
        }
      });

      test('termini di ricerca: al massimo 7, da 30 caratteri, 21 parole in tutto', () {
        final terms = field(2).split(',').map((t) => t.trim()).toList();
        expect(terms.length, lessThanOrEqualTo(7));
        expect(terms.toSet().length, terms.length, reason: 'doppioni');
        for (final t in terms) {
          expect(t.runes.length, inInclusiveRange(1, 30), reason: t);
        }
        final words = terms.expand((t) => t.split(RegExp(r'\s+'))).length;
        expect(words, lessThanOrEqualTo(21));
      });

      test('frame adulto e nessun claim vietato', () {
        for (var i = 0; i < names.length; i++) {
          expect(_forbidden.hasMatch(field(i)), isFalse, reason: names[i]);
        }
      });
    });
  }

  test("l'identità coincide con msix_config di pubspec.yaml", () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final value in ['DavideBertolino.DBFlow', 'CN=D690F6A5-53AB-468E-9581-1266A41A362B']) {
      expect(md, contains(value));
      expect(pubspec, contains(value));
    }
  });

  test('note per la certificazione in inglese, senza claim vietati', () {
    final notes = RegExp(
      r'### Note per la certificazione.*?```text\n(.*?)```',
      dotAll: true,
    ).firstMatch(md)!.group(1)!;
    expect(notes, contains('No sign-in'));
    expect(_forbidden.hasMatch(notes), isFalse);
  });
}
