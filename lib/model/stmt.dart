/// AST delle istruzioni (blocchi del diagramma). Dart puro, immutabile.
library;

import '../expr/types.dart';
import 'expr.dart';
import 'ids.dart';

export '../expr/types.dart' show VarType;

/// Blocco del diagramma. [id] è stabile: serve per selezione, evidenziazione
/// durante l'esecuzione e animazioni.
sealed class Stmt {
  Stmt({String? id}) : id = id ?? newId();
  final String id;
}

final class Declare extends Stmt {
  Declare({super.id, required this.name, required this.type});
  final String name;
  final VarType type;
}

final class Assign extends Stmt {
  Assign({super.id, required this.target, required this.value});
  final String target;
  final ExprSource value;
}

final class Input extends Stmt {
  Input({super.id, required this.variable});
  final String variable;
}

final class Output extends Stmt {
  Output({super.id, required this.value});
  final ExprSource value;
}

final class If extends Stmt {
  If({super.id, required this.cond, List<Stmt> then = const [], List<Stmt> otherwise = const []})
    : then = List.unmodifiable(then),
      otherwise = List.unmodifiable(otherwise);
  final ExprSource cond;
  final List<Stmt> then;
  final List<Stmt> otherwise;
}

final class While extends Stmt {
  While({super.id, required this.cond, List<Stmt> body = const []})
    : body = List.unmodifiable(body);
  final ExprSource cond;
  final List<Stmt> body;
}

final class DoWhile extends Stmt {
  DoWhile({super.id, List<Stmt> body = const [], required this.cond})
    : body = List.unmodifiable(body);
  final List<Stmt> body;
  final ExprSource cond;
}

/// Ciclo con contatore: `v` va da [from] a [to] (inclusi) con passo [step].
/// Con passo positivo continua finché `v <= to`, con passo negativo finché `v >= to`.
final class For extends Stmt {
  For({
    super.id,
    required this.variable,
    required this.from,
    required this.to,
    ExprSource? step,
    List<Stmt> body = const [],
  }) : step = step ?? ExprSource('1'),
       body = List.unmodifiable(body);
  final String variable;
  final ExprSource from;
  final ExprSource to;
  final ExprSource step;
  final List<Stmt> body;
}

final class Comment extends Stmt {
  Comment({super.id, required this.text});
  final String text;
}

// ---------------------------------------------------------------- Arduino

/// `digitalWrite(pin, value)`: [pin] è un'espressione (di solito il nome di un
/// pin configurato, es. `LED`), [value] di solito `HIGH` o `LOW`.
final class DigitalWrite extends Stmt {
  DigitalWrite({super.id, required this.pin, required this.value});
  final ExprSource pin;
  final ExprSource value;
}

/// `analogWrite(pin, value)`: uscita PWM, [value] da 0 a 255.
final class AnalogWrite extends Stmt {
  AnalogWrite({super.id, required this.pin, required this.value});
  final ExprSource pin;
  final ExprSource value;
}

/// `delay(ms)`: attesa in millisecondi.
final class Delay extends Stmt {
  Delay({super.id, required this.ms});
  final ExprSource ms;
}

/// `variable ← digitalRead(pin)`: ingresso digitale (HIGH/LOW) in una variabile intera.
final class DigitalRead extends Stmt {
  DigitalRead({super.id, required this.variable, required this.pin});
  final String variable;
  final ExprSource pin;
}

/// `variable ← analogRead(pin)`: ingresso analogico (0–1023) in una variabile intera.
final class AnalogRead extends Stmt {
  AnalogRead({super.id, required this.variable, required this.pin});
  final String variable;
  final ExprSource pin;
}
