import 'dart:io';

import 'package:db_flow/i18n/tr.dart';
import 'package:db_flow/io/share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finestra "scegli cartella" simulata.
class FakePicker extends FilePickerPlatform {
  FakePicker(this.dir);
  final String? dir;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => dir;
}

void main() {
  setUp(() => setLanguage(AppLanguage.it));

  test('nome valido per l\'Arduino IDE', () {
    expect(sketchName('Semaforo'), 'Semaforo');
    expect(sketchName('LED che lampeggia'), 'LED_che_lampeggia');
    expect(sketchName('Città: più luce!'), 'Citta_piu_luce');
    expect(sketchName('  _prova-1.2 '), 'prova-1.2');
    expect(sketchName('???'), 'sketch');
    expect(sketchName('x' * 80).length, 63);
  });

  test('su computer crea la cartella con lo stesso nome dello sketch', () async {
    final tmp = Directory.systemTemp.createTempSync('dbflow_sketch');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final old = FilePickerPlatform.instance;
    addTearDown(() => FilePickerPlatform.instance = old);
    FilePickerPlatform.instance = FakePicker(tmp.path);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final path = await saveArduinoSketch('void setup() {}\nvoid loop() {}\n', 'Luce notturna');
    final sep = Platform.pathSeparator;
    expect(path, '${tmp.path}${sep}Luce_notturna${sep}Luce_notturna.ino');
    expect(File(path!).readAsStringSync(), contains('void loop()'));

    // annullando la scelta della cartella non si salva nulla
    FilePickerPlatform.instance = FakePicker(null);
    expect(await saveArduinoSketch('x', 'Altro'), isNull);
  });
}
