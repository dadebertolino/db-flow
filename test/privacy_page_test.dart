import 'dart:io';

import 'package:db_flow/app_info.dart';
import 'package:db_flow/i18n/tr.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/privacy/privacy_page.dart';

void main() {
  test('la pagina dell\'informativa per il sito è allineata ai testi dell\'app', () {
    expect(
      File(privacyPagePath).readAsStringSync(),
      renderPrivacyPage(),
      reason: 'rigenerarla con: flutter test tool/privacy/render_privacy_page_test.dart',
    );
  });

  test('la pagina rispetta le regole del sito e dello standard privacy', () {
    final html = renderPrivacyPage();
    expect(html, startsWith('<!-- wp:html -->'));
    expect(html.trim(), endsWith('<!-- /wp:html -->'));
    for (final banned in ['<html', '<head', '<body', '<main', 'fonts.googleapis', 'open source']) {
      expect(html.toLowerCase(), isNot(contains(banned)), reason: banned);
    }
    expect(html, contains(appContact));
    for (final l in AppLanguage.values) {
      expect(html, contains('id="${l.name}" lang="${l.name}"'));
      expect(html, contains(trFor(l).privacyUpdated));
    }
    // ogni regola CSS è limitata alla pagina (.db-pro) tranne le variabili
    final css = RegExp(r'<style>(.*)</style>', dotAll: true).firstMatch(html)!.group(1)!;
    final selectors = RegExp(r'([^{}]+)\{').allMatches(css).map((m) => m.group(1)!.trim());
    for (final sel in selectors) {
      if (sel == ':root' || sel.startsWith('@media')) continue;
      for (final part in sel.split(',')) {
        expect(part.trim(), startsWith('.db-pro'), reason: part);
      }
    }
  });
}
