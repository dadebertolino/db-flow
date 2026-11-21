import 'package:flutter/material.dart';

import 'app.dart';
import 'io/incoming.dart';

/// [args]: su Windows contiene il percorso del file `.flow` aperto con doppio clic.
void main(List<String> args) => runApp(DbFlowApp(incoming: IncomingFiles(launchArgs: args)));
