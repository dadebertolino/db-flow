import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/program.dart';
import '../model/serialization.dart';

/// Diagramma salvato sul dispositivo.
final class StoredFlow {
  const StoredFlow(
    this.file,
    this.name,
    this.modified, {
    this.damaged = false,
    this.isExercise = false,
  });
  final File file;
  final String name;
  final DateTime modified;
  final bool damaged;

  /// Il diagramma contiene un esercizio (consegna e casi di prova).
  final bool isExercise;
}

/// File `.flow` nella cartella documenti dell'app. Nessun dato lascia il dispositivo.
class FlowStorage {
  FlowStorage({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDir;

  Future<Directory> _dir() async {
    final base = await _baseDir();
    final dir = Directory('${base.path}${Platform.pathSeparator}diagrammi');
    await dir.create(recursive: true);
    return dir;
  }

  /// Diagrammi salvati, dal più recente.
  Future<List<StoredFlow>> list() async {
    final dir = await _dir();
    final result = <StoredFlow>[];
    await for (final e in dir.list()) {
      if (e is! File || !e.path.endsWith('.flow')) continue;
      final modified = await e.lastModified();
      try {
        final p = decodeProgram(await e.readAsString());
        result.add(StoredFlow(e, p.name, modified, isExercise: p.exercise != null));
      } on Object {
        result.add(StoredFlow(e, e.uri.pathSegments.last, modified, damaged: true));
      }
    }
    result.sort((a, b) => b.modified.compareTo(a.modified));
    return result;
  }

  Future<File> create(Program p) async {
    final dir = await _dir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}.flow',
    );
    await save(file, p);
    return file;
  }

  /// Scrittura atomica: file temporaneo e poi rinomina.
  Future<void> save(File file, Program p) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(encodeProgram(p), flush: true);
    await tmp.rename(file.path);
  }

  Future<Program> load(File file) async => decodeProgram(await file.readAsString());

  Future<void> delete(File file) async {
    if (await file.exists()) await file.delete();
  }
}
