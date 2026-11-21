import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Preferenze dell'app (solo il tema), salvate in un piccolo file JSON nella
/// cartella di supporto dell'app. Nessun dato lascia il dispositivo.
class AppSettings extends ChangeNotifier {
  /// File interno dell'app: sta nella cartella di supporto, non in Documenti
  /// (che su iPhone e iPad è visibile nell'app File, accanto ai diagrammi).
  AppSettings({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  ThemeMode _themeMode = ThemeMode.system;

  /// Tema scelto: come il dispositivo, chiaro o scuro.
  ThemeMode get themeMode => _themeMode;

  Future<File> _file() async {
    final dir = await _baseDir();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}impostazioni.json');
  }

  /// Legge le preferenze; se il file manca o è illeggibile restano quelle predefinite.
  Future<void> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) return;
      final mode = ThemeMode.values.where((m) => m.name == json['theme']).firstOrNull;
      if (mode != null && mode != _themeMode) {
        _themeMode = mode;
        notifyListeners();
      }
    } on Object {
      // preferenze predefinite
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode({'theme': mode.name}), flush: true);
      await tmp.rename(file.path);
    } on Object {
      // la scelta resta valida per questa sessione
    }
  }
}
