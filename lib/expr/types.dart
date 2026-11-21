/// Tipi e valori del linguaggio delle espressioni. Dart puro.
library;

import '../i18n/tr.dart';

/// Tipo di una variabile o di un'espressione.
enum VarType {
  integer,
  real,
  string,
  boolean;

  /// Nome nella lingua corrente, mostrato all'utente.
  String get label => switch (this) {
    integer => tr.typeInteger,
    real => tr.typeReal,
    string => tr.typeString,
    boolean => tr.typeBoolean,
  };

  bool get isNumeric => this == integer || this == real;

  /// Converte il nome usato nel file `.flow`; `null` se sconosciuto.
  static VarType? fromName(String name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// Indica se un valore di tipo [source] può essere assegnato a una variabile
/// di tipo [target]. Unica conversione implicita: intero → reale.
bool isAssignable(VarType target, VarType source) =>
    target == source || (target == VarType.real && source == VarType.integer);

/// Valore a runtime.
sealed class Value {
  const Value();

  VarType get type;

  /// Rappresentazione mostrata all'utente (console, tabella variabili).
  String get display;

  @override
  String toString() => display;
}

final class IntV extends Value {
  const IntV(this.value);
  final int value;

  @override
  VarType get type => VarType.integer;

  @override
  String get display => '$value';

  @override
  bool operator ==(Object other) => other is IntV && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class RealV extends Value {
  const RealV(this.value);
  final double value;

  @override
  VarType get type => VarType.real;

  /// I reali interi si mostrano con un decimale (`3.0`) per distinguerli dagli interi.
  @override
  String get display {
    if (value.isNaN) return tr.realUndefined;
    if (value.isInfinite) return value > 0 ? tr.realInfinite : '-${tr.realInfinite}';
    return value == value.truncateToDouble() && value.abs() < 1e15
        ? value.toStringAsFixed(1)
        : '$value';
  }

  @override
  bool operator ==(Object other) => other is RealV && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class StrV extends Value {
  const StrV(this.value);
  final String value;

  @override
  VarType get type => VarType.string;

  @override
  String get display => value;

  @override
  bool operator ==(Object other) => other is StrV && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class BoolV extends Value {
  const BoolV(this.value);
  final bool value;

  @override
  VarType get type => VarType.boolean;

  @override
  String get display => value ? tr.trueWord : tr.falseWord;

  @override
  bool operator ==(Object other) => other is BoolV && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
