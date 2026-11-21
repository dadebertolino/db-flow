import 'dart:io';

import 'package:flutter/services.dart';

/// File `.flow` aperti dall'esterno: toccando un allegato in Mail, da File,
/// AirDrop, Finder o con doppio clic su Windows. Il codice nativo legge il file
/// e passa il testo; qui non c'è nessun accesso alla rete.
class IncomingFiles {
  IncomingFiles({this.launchArgs = const []});

  static const _channel = MethodChannel('dbflow/files');

  /// Argomenti di avvio (Windows e Linux: percorso del file aperto con doppio clic).
  final List<String> launchArgs;

  /// Inizia ad ascoltare i file in arrivo e consegna subito quelli ricevuti
  /// prima che l'app fosse pronta. [onFile] riceve il testo del file.
  Future<void> listen(void Function(String text) onFile) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) onFile(call.arguments as String);
    });
    for (final path in launchArgs.where((a) => a.toLowerCase().endsWith('.flow'))) {
      try {
        onFile(await File(path).readAsString());
      } on Object {
        // file sparito o illeggibile: si ignora
      }
    }
    try {
      final pending = await _channel.invokeListMethod<String>('pending');
      for (final text in pending ?? const <String>[]) {
        onFile(text);
      }
    } on MissingPluginException {
      // piattaforma senza codice nativo (test, Linux)
    }
  }

  void dispose() => _channel.setMethodCallHandler(null);
}
