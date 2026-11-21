// Rigenera la pagina dell'informativa per il sito (vedi privacy_page.dart):
//
//   flutter test tool/privacy/render_privacy_page_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'privacy_page.dart';

void main() {
  test('genera la pagina dell\'informativa', () {
    File(privacyPagePath).writeAsStringSync(renderPrivacyPage());
  });
}
