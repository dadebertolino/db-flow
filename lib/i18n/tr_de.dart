// Texte auf Deutsch (Fachbegriffe des Schulfachs Informatik).
import '../expr/types.dart';
import 'tr.dart';

class TrDe extends Tr {
  const TrDe();

  @override
  AppLanguage get language => AppLanguage.de;

  String _t(VarType t) => switch (t) {
    VarType.integer => typeInteger,
    VarType.real => typeReal,
    VarType.string => typeString,
    VarType.boolean => typeBoolean,
  };

  String _steps(int n) => n == 1 ? '1 Schritt' : '$n Schritte';

  // ================================================================ tipi e valori
  @override
  String get typeInteger => 'Ganzzahl';
  @override
  String get typeReal => 'Kommazahl';
  @override
  String get typeString => 'Zeichenkette';
  @override
  String get typeBoolean => 'Wahrheitswert';
  @override
  String aType(VarType t) => switch (t) {
    VarType.boolean => 'ein ${_t(t)}',
    _ => 'eine ${_t(t)}',
  };
  @override
  String get trueWord => 'wahr';
  @override
  String get falseWord => 'falsch';
  @override
  String get realUndefined => 'nicht definiert';
  @override
  String get realInfinite => 'unendlich';

  // ================================================================ lexer
  @override
  String get lexIncompleteNumber =>
      'unvollständige Zahl: nach dem Punkt fehlen die Nachkommastellen';
  @override
  String get lexNameStartsWithDigit => 'ein Name darf nicht mit einer Ziffer beginnen';
  @override
  String get lexNumberTooLarge => 'Zahl zu groß';
  @override
  String lexAccentedLetter(String ch) =>
      "Buchstabe '$ch' ist in Namen nicht erlaubt: schreibe ohne Umlaute und Akzente (ä → ae)";
  @override
  String get lexUnclosedString => 'Zeichenkette nicht geschlossen: das Anführungszeichen " fehlt';
  @override
  String get lexUseOr => "für 'oder' verwende 'or' (oder '||')";
  @override
  String get lexUseDoubleEquals =>
      "zum Vergleichen verwende '=='; ein einzelnes '=' ist hier nicht erlaubt";
  @override
  String get lexUseNotEquals => "für 'ungleich' verwende '!='";
  @override
  String get lexUseDoubleQuotes => 'Zeichenketten stehen in doppelten Anführungszeichen: "Text"';
  @override
  String lexInvalidChar(String ch) => "ungültiges Zeichen: '$ch'";
  @override
  String get idEmpty => 'der Name ist leer';
  @override
  String get idHasSpaces =>
      'ein Name darf keine Leerzeichen enthalten (verwende _ statt Leerzeichen)';
  @override
  String get idInvalidChars => 'verwende nur Buchstaben ohne Umlaute/Akzente, Ziffern und _';
  @override
  String idIsFunction(String name) => "'$name' ist der Name einer Funktion";
  @override
  String idReserved(String name) => "'$name' ist ein reserviertes Wort";

  // ================================================================ parser
  @override
  String get parseEmpty => 'leerer Ausdruck';
  @override
  String get parseChainedComparison =>
      'verkettete Vergleiche sind nicht erlaubt: schreibe z. B. a < b and b < c';
  @override
  String get parseMissingCloseParen => "die Klammer ')' fehlt, die diese '(' schließt";
  @override
  String get parseIncomplete => 'unvollständiger Ausdruck: am Ende fehlt ein Wert';
  @override
  String get parseMissingValueBeforeClose => "vor ')' fehlt ein Wert";
  @override
  String get parseUnexpectedComma =>
      'unerwartetes Komma: für Dezimalzahlen verwende den Punkt (3.14)';
  @override
  String parseMissingValueBefore(String token) => "vor '$token' fehlt ein Wert";
  @override
  String parseUnknownFunction(String name) => "unbekannte Funktion '$name'";
  @override
  String parseArity(String fn, int arity, int given) => switch (arity) {
    0 =>
      '$fn braucht leere Klammern: $fn(), du hast '
          '${given == 1 ? '1 Argument' : '$given Argumente'} geschrieben',
    1 => '$fn braucht 1 Argument, du hast $given geschrieben',
    _ => '$fn braucht $arity Argumente, du hast $given geschrieben',
  };
  @override
  String get parseUnmatchedClose => "Klammer ')' ohne passende '('";
  @override
  String parseMissingOperatorBefore(String token) => "vor '$token' fehlt ein Operator";
  @override
  String parseUnexpected(String token) => "'$token' ist hier unerwartet";

  // ================================================================ controllo dei tipi
  @override
  String typeUndeclared(String name) => "Variable '$name' ist nicht deklariert";
  @override
  String typeUndeclaredLowercase(String name, String lower) =>
      "Variable '$name' ist nicht deklariert: schreibe '$lower' klein";
  @override
  String typeNegNumber(VarType t) =>
      "das Vorzeichen '-' gilt nur für Zahlen, hier steht aber ${aType(t)}";
  @override
  String typeNotBoolean(VarType t) =>
      "'not' gilt nur für Wahrheitswerte, hier steht aber ${aType(t)}; "
      'setze bei Bedarf Klammern: not (a > b)';
  @override
  String typePair(VarType a, VarType b) => '${_t(a)} und ${_t(b)}';
  @override
  String typeArith(String sym, VarType a, VarType b) =>
      "'$sym' geht nur zwischen Zahlen, nicht zwischen ${typePair(a, b)}";
  @override
  String typePlusText(VarType a, VarType b) =>
      "'+' verbindet nicht ${typePair(a, b)}: um Text zusammenzusetzen, verwende '&'";
  @override
  String typeModInts(VarType a, VarType b) =>
      "'%' (Rest) geht nur zwischen Ganzzahlen, nicht zwischen ${typePair(a, b)}";
  @override
  String typeCannotCompare(VarType a, VarType b) =>
      '${typePair(a, b)} können nicht verglichen werden';
  @override
  String typeCompareNumStr(String sym, VarType a, VarType b) =>
      "'$sym' geht nur zwischen Zahlen oder zwischen Zeichenketten, "
      'nicht zwischen ${typePair(a, b)}';
  @override
  String typeLogical(String sym, VarType a, VarType b) =>
      "'$sym' geht nur zwischen Bedingungen (Wahrheitswerten), nicht zwischen ${typePair(a, b)}";
  @override
  String typeArduinoOnly(String fn) => "'$fn' gibt es nur in Arduino-Diagrammen";
  @override
  String fnNeedsNumber(String fn, VarType t) =>
      '$fn braucht eine Zahl, hier steht aber ${aType(t)}';
  @override
  String fnNeedsString(String fn, VarType t) =>
      '$fn braucht eine Zeichenkette, hier steht aber ${aType(t)}';
  @override
  String fnNeedsInteger(String fn, VarType t) =>
      '$fn braucht eine Ganzzahl, hier steht aber ${aType(t)}';
  @override
  String fnNeedsPin(String fn, VarType t) =>
      '$fn braucht einen Pin (Ganzzahl), hier steht aber ${aType(t)}';
  @override
  String functionSignature(String fn) => switch (fn) {
    'abs' || 'sqrt' || 'int' || 'round' => '$fn(Zahl)',
    'len' => 'len(Text)',
    'random' => 'random(n)',
    'digitalRead' || 'analogRead' => '$fn(Pin)',
    _ => '$fn()',
  };
  @override
  String functionDescription(String fn) => switch (fn) {
    'abs' => 'Betrag',
    'sqrt' => 'Quadratwurzel (Ergebnis: Kommazahl)',
    'int' => 'ganzzahliger Anteil, schneidet die Nachkommastellen ab: int(3.9) = 3, int(-3.9) = -3',
    'round' => 'rundet auf die nächste Ganzzahl (bei .5 wird betragsmäßig aufgerundet)',
    'len' => 'Anzahl der Zeichen im Text',
    'random' => 'zufällige Ganzzahl von 0 bis n-1',
    'digitalRead' => 'liest einen Digitaleingang: HIGH (1) oder LOW (0)',
    'analogRead' => 'liest einen Analogeingang: von 0 bis 1023',
    'millis' => 'Millisekunden seit dem Einschalten',
    _ => fn,
  };

  // ================================================================ validazione
  @override
  String get valChooseVariable => 'wähle eine Variable';
  @override
  String valConstant(String name) => "'$name' ist eine Konstante: ihr Wert kann sich nicht ändern";
  @override
  String valUndeclared(String name) => "Variable '$name' ist nicht deklariert";
  @override
  String valConditionBoolean(VarType t) =>
      'die Bedingung muss wahr oder falsch sein (Wahrheitswert), ist aber ${aType(t)}';
  @override
  String valNameIsPin(String name) => "'$name' ist schon der Name eines Pins oder einer Konstante";
  @override
  String valAlreadyDeclared(String name) => "die Variable '$name' ist schon deklariert";
  @override
  String valCounterInteger(String name) =>
      "der Zähler '$name' muss eine Variable vom Typ Ganzzahl sein";
  @override
  String get whatFrom => 'der Startwert';
  @override
  String get whatTo => 'der Endwert';
  @override
  String get whatStep => 'die Schrittweite';
  @override
  String valMustBeInteger(String what, VarType t) =>
      '$what muss eine Ganzzahl sein, ist aber ${aType(t)}';
  @override
  String get valStepZero => 'die Schrittweite darf nicht 0 sein';
  @override
  String valHighLow(VarType t) => 'der Wert muss HIGH oder LOW sein, ist aber ${aType(t)}';
  @override
  String valPwmInteger(VarType t) =>
      'der Wert muss eine Ganzzahl von 0 bis 255 sein, ist aber ${aType(t)}';
  @override
  String valPwmRange(int max, int value) =>
      'der Wert für analogWrite geht von 0 bis $max, ist aber $value';
  @override
  String valReadIntoInteger(String name) =>
      "'$name' muss eine Variable vom Typ Ganzzahl sein, um den Messwert aufzunehmen";
  @override
  String valDelayInteger(VarType t) =>
      'die Wartezeit muss eine Ganzzahl (Millisekunden) sein, ist aber ${aType(t)}';
  @override
  String get valDelayNegative => 'die Wartezeit darf nicht negativ sein';
  @override
  String get valArduinoOnlyBlock => 'diesen Block gibt es nur in Arduino-Diagrammen';
  @override
  String get valChoosePin => 'wähle einen Pin';
  @override
  String valPinNotConfigured(String name) =>
      "Pin '$name' ist nicht konfiguriert: füge ihn unter »$pinsAndBoard« hinzu";
  @override
  String valPinMustBeInt(VarType t) =>
      'der Pin muss eine Ganzzahl oder ein Pin-Name sein, ist aber ${aType(t)}';
  @override
  String valPinNamed(String name, String pin) => "'$name' (Pin $pin)";
  @override
  String valPinNumber(String pin) => 'Pin $pin';
  @override
  String valPinNotOnBoard(String pin, String board) => 'Pin $pin gibt es auf dem $board nicht';
  @override
  String valPinNotConfiguredLabel(String label) =>
      '$label ist nicht konfiguriert: füge ihn unter »$pinsAndBoard« mit einem Namen hinzu '
      '(z. B. LED)';
  @override
  String valPinNotOutput(String label, String mode) =>
      '$label ist als $mode konfiguriert: zum Schreiben muss der Pin ein Ausgang sein';
  @override
  String valNoPwm(String label, String board, String pins) =>
      '$label unterstützt kein analogWrite (PWM): verwende auf dem $board einen der Pins $pins';
  @override
  String valPinIsOutput(String label) =>
      '$label ist ein Ausgang: konfiguriere den Pin als Eingang, um ihn zu lesen';
  @override
  String valAnalogReadPins(String pins) => 'analogRead funktioniert nur an den Pins $pins';
  @override
  String valAnalogAlias(String label, String digital) =>
      '$label funktioniert nur mit analogRead(): Als digitaler Pin ist es Pin $digital.';
  @override
  String valAnalogOnly(String label) =>
      '$label ist nur ein analoger Eingang: lies ihn mit analogRead().';
  @override
  String valAnalogReadMode(String label) =>
      '$label muss als Analogeingang konfiguriert sein, um analogRead zu verwenden';
  @override
  String valPinNameError(String name, String error) => "Pin-Name '$name': $error";
  @override
  String valPinNameTwice(String name) => "der Name '$name' wird für zwei Pins verwendet";
  @override
  String valPinNotExists(String name, String pin, String board) =>
      '$name: Pin $pin gibt es auf dem $board nicht';
  @override
  String valPinTwice(String pin) => 'Pin $pin ist zweimal konfiguriert';
  @override
  String valPinModeInvalid(String name, String pin, String mode) =>
      '$name: Pin $pin kann nicht als $mode verwendet werden';
  @override
  String valSerialPins(String name, List<String> pins) =>
      '$name: die Pins ${pins.join(' und ')} werden für die serielle Schnittstelle '
      '(Eingabe/Ausgabe) gebraucht: wähle einen anderen Pin';
  @override
  String valAssignRealToInt(String target) =>
      "'$target' ist eine Ganzzahl, der Wert aber eine Kommazahl: verwende int(...) oder "
      "round(...) oder deklariere '$target' als Kommazahl";
  @override
  String valAssignType(VarType value, String target, VarType targetType) =>
      "'$target' ist vom Typ ${_t(targetType)}: ${aType(value)} kann nicht zugewiesen werden";

  // ================================================================ file .flow
  @override
  String get fileDamaged => 'die Datei ist beschädigt oder kein DB-Flow-Diagramm';
  @override
  String get fileNotFlow => 'die Datei ist kein DB-Flow-Diagramm';
  @override
  String get fileBadVersion => 'Dateiversion fehlt oder ist ungültig';
  @override
  String get fileTooNew =>
      'die Datei wurde mit einer neueren Version der App erstellt: aktualisiere DB Flow';
  @override
  String fileFieldMissing(String key) => "Feld '$key' fehlt oder ist ungültig";
  @override
  String fileFieldInvalid(String key) => "Feld '$key' ist ungültig";
  @override
  String get fileBadBlock => 'ungültiger Block';
  @override
  String fileUnknownBlock(String t) => "unbekannter Blocktyp: '$t'";
  @override
  String fileUnknownType(String name) => "unbekannter Typ: '$name'";
  @override
  String get untitled => 'Unbenannt';

  // ================================================================ esecuzione
  @override
  String runUndeclared(String name) => "die Variable '$name' wurde nicht deklariert";
  @override
  String runNoValue(String name) =>
      "die Variable '$name' hat noch keinen Wert: weise ihr einen Wert zu oder lies sie ein, "
      'bevor du sie verwendest';
  @override
  String runAssignType(VarType value, String name, VarType varType) =>
      "'$name' ist vom Typ ${_t(varType)}: ${aType(value)} kann nicht zugewiesen werden";
  @override
  String get inputNeedInteger => 'gib eine Ganzzahl ein, z. B. 42';
  @override
  String get inputNeedNumber => 'gib eine Zahl ein, z. B. 3.5';
  @override
  String get inputNeedBoolean => 'gib wahr oder falsch ein';
  @override
  String runTypeInvalid(String what) => 'ungültiger Typ: $what';
  @override
  String get runNeedNumber => 'hier wird eine Zahl gebraucht';
  @override
  String get runNeedBoolean => 'hier wird ein Wahrheitswert gebraucht';
  @override
  String runOpNotApplicable(String op, VarType t) =>
      "'$op' ist hier nicht anwendbar: der Wert ist ${aType(t)}";
  @override
  String get runDivZero => 'Division durch null';
  @override
  String get runModInts => "'%' geht nur zwischen Ganzzahlen";
  @override
  String get runModZero => 'Rest einer Division durch null';
  @override
  String runSqrtNegative(String value) => 'Quadratwurzel aus einer negativen Zahl ($value)';
  @override
  String runNotFinite(String fn) => '$fn: der Wert ist keine endliche Zahl';
  @override
  String get runLenString => 'len braucht eine Zeichenkette';
  @override
  String get runRandomInt => 'random braucht eine Ganzzahl';
  @override
  String runRandomPositive(int n) => 'random(n) braucht ein n größer als 0, aber n = $n';
  @override
  String runNotSimulated(String fn) => "'$fn' ist in der Simulation noch nicht verfügbar";
  @override
  String runTooManySteps(int n) =>
      'mehr als $n Schritte: vielleicht enthält das Programm eine Endlosschleife '
      '(wird die Bedingung nie falsch?)';
  @override
  String runConditionValue(String value) =>
      'die Bedingung muss wahr oder falsch sein, hat aber den Wert $value';
  @override
  String runMustBeInteger(String what, String value) =>
      '$what muss eine Ganzzahl sein, hat aber den Wert $value';
  @override
  String get runStepZero => 'die Schrittweite der Schleife darf nicht 0 sein';
  @override
  String get runArduinoNotSimulated =>
      'Arduino-Blöcke werden noch nicht simuliert: erzeuge den Sketch';
  @override
  String runCounterInteger(String name) => "der Zähler '$name' muss eine Ganzzahl bleiben";
  @override
  String runInvalidExpr(String text) => "ungültiger Ausdruck: '$text'";
  @override
  String get runInputMissing => 'Eingabe fehlt';
  @override
  String runFinished(int steps) => 'Programm beendet (${_steps(steps)})';
  @override
  String runErrorLine(String message) => 'Fehler: $message';

  // ================================================================ diagramma
  @override
  String get flowStart => 'Start';
  @override
  String get flowEnd => 'Ende';
  @override
  String get edgeTrue => 'wahr';
  @override
  String get edgeFalse => 'falsch';
  @override
  String get flowRepeat => 'wiederholen';
  @override
  String labelRead(String variable) => 'Eingabe $variable';
  @override
  String labelWrite(String text) => 'Ausgabe $text';
  @override
  String labelFor(String variable, String from, String to, String? step) =>
      '$variable von $from bis $to${step == null ? '' : ', Schritt $step'}';
  @override
  String get kindAlgorithm => 'Algorithmus';
  @override
  String get kindArduino => 'Arduino';
  @override
  String get pinModeOutput => 'Ausgang';
  @override
  String get pinModeInput => 'Eingang';
  @override
  String get pinModeInputPullup => 'Eingang mit Pull-up';
  @override
  String get pinModeAnalogInput => 'Analogeingang';

  // ================================================================ codice generato
  @override
  String get codeGenerated => 'Code erzeugt mit DB Flow';
  @override
  String codeGeneratedFor(String board) => 'Code erzeugt mit DB Flow für $board';
  @override
  String get codeConnections => 'Anschlüsse:';
  @override
  String codeInvalidExpr(String text) => 'FEHLER: ungültiger Ausdruck: $text';
  @override
  String codeArduinoOnly(String label) => '$label: nur auf Arduino verfügbar';
  @override
  String inputPrompt(String variable) => 'Gib $variable ein: ';
  @override
  String get codeAnswerVar => 'antwort';
  @override
  String get codeConcatUnsupported =>
      'Textverkettung: verwende einen Ausgabe-Block oder eine Zuweisung';
  @override
  String get codeLanguagePseudo => 'Pseudocode';
  @override
  String pAlgorithm(String name) => 'ALGORITHMUS $name';
  @override
  String get pBegin => 'BEGINN';
  @override
  String get pEnd => 'ENDE';
  @override
  String pDeclare(String name, String type) => 'VARIABLE $name : ${type.toUpperCase()}';
  @override
  String pRead(String variable) => 'EINGABE $variable';
  @override
  String pWrite(String text) => 'AUSGABE $text';
  @override
  String pIf(String cond) => 'WENN $cond DANN';
  @override
  String get pElse => 'SONST';
  @override
  String get pEndIf => 'ENDE WENN';
  @override
  String pWhile(String cond) => 'SOLANGE $cond TUE';
  @override
  String get pEndWhile => 'ENDE SOLANGE';
  @override
  String get pRepeat => 'WIEDERHOLE';
  @override
  String pRepeatWhile(String cond) => 'SOLANGE $cond';
  @override
  String pFor(String variable, String from, String to, String? step) =>
      'FÜR $variable VON $from BIS $to${step == null ? '' : ' SCHRITT $step'} TUE';
  @override
  String get pEndFor => 'ENDE FÜR';
  @override
  String pSketch(String name, String board) => 'SKETCH $name ($board)';
  @override
  String pPin(String name, String pin, String mode) => 'PIN $name = $pin ($mode)';
  @override
  String get pSetup => 'SETUP';
  @override
  String get pEndSetup => 'ENDE SETUP';
  @override
  String get pLoop => 'LOOP (endlos wiederholen)';
  @override
  String get pEndLoop => 'ENDE LOOP';

  // ================================================================ interfaccia: comuni
  @override
  String get cancel => 'Abbrechen';
  @override
  String get undo => 'Rückgängig';
  @override
  String get redo => 'Wiederholen';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Löschen';
  @override
  String get share => 'Teilen';
  @override
  String get saveAs => 'Speichern unter…';
  @override
  String get saveFlowFile => '.flow-Datei speichern…';
  @override
  String get saveExercise => 'Als Aufgabe speichern…';
  @override
  String get more => 'Mehr';
  @override
  String get name => 'Name';
  @override
  String get create => 'Erstellen';
  @override
  String get insert => 'Einfügen';
  @override
  String get save => 'Speichern';
  @override
  String get add => 'Hinzufügen';
  @override
  String get edit => 'Bearbeiten';
  @override
  String get run => 'Ausführen';
  @override
  String get pin => 'Pin';
  @override
  String get pinsAndBoard => 'Pins und Board';
  @override
  String get code => 'Code';
  @override
  String get info => 'Info';
  @override
  String get theme => 'Design';
  @override
  String get themeSystem => 'Wie das Gerät';
  @override
  String get themeLight => 'Hell';
  @override
  String get themeDark => 'Dunkel';

  // ================================================================ home
  @override
  String get newDiagram => 'Neues Diagramm';
  @override
  String get myDiagrams => 'Meine Diagramme';
  @override
  String get noDiagrams => 'Keine Diagramme';
  @override
  String get noDiagramsHint => 'Erstelle ein neues oder starte mit einem Beispiel.';
  @override
  String get damagedFile => 'Beschädigte Datei';
  @override
  String modified(String date) => 'Geändert: $date';
  @override
  String get examples => 'Beispiele';
  @override
  String get examplesArduino => 'Arduino-Beispiele';
  @override
  String get opensCopy => 'Öffnet eine bearbeitbare Kopie';
  @override
  String get openFlowFile => '.flow-Datei öffnen';
  @override
  String openFailed(String message) => 'Öffnen nicht möglich: $message';
  @override
  String importFailed(String message) => 'Datei kann nicht geöffnet werden: $message';
  @override
  String get importNotFlow => 'Datei kann nicht geöffnet werden: kein DB-Flow-Diagramm';
  @override
  String shareFailed(String error) => 'Teilen fehlgeschlagen: $error';
  @override
  String get deleteTitle => 'Diagramm löschen?';
  @override
  String deleteBody(String name) => '„$name“ wird von diesem Gerät gelöscht.';
  @override
  String get hintNameArduino => 'z. B. Ampel';
  @override
  String get hintNameAlgorithm => 'z. B. Summe zweier Zahlen';
  @override
  String get newArduinoHint =>
      'Das Diagramm hat einen setup()- und einen loop()-Teil. '
      'Lege die Anschlüsse über die Schaltfläche »$pin« fest.';

  // ================================================================ editor
  @override
  String saveFailed(String error) => 'Speichern fehlgeschlagen: $error';
  @override
  String get blockDeleted => 'Block gelöscht';
  @override
  String get blockDeletedWithContent => 'Block mit Inhalt gelöscht';
  @override
  String get diagramName => 'Name des Diagramms';
  @override
  String fixBeforeRun(int count) => count == 1
      ? 'Korrigiere zuerst den rot markierten Block, dann kannst du das Programm ausführen.'
      : 'Korrigiere zuerst die $count rot markierten Probleme.';
  @override
  String operationFailed(String error) => 'Vorgang fehlgeschlagen: $error';
  @override
  String get insertBlock => 'Block einfügen';
  @override
  String pinIssues(int count) => count == 1
      ? '$pinsAndBoard: 1 Problem zu beheben'
      : '$pinsAndBoard: $count Probleme zu beheben';
  @override
  String blockIssues(int count) => count == 1
      ? '1 Problem: tippe auf den roten Block, um es zu sehen'
      : '$count Probleme: tippe auf die roten Blöcke, um sie zu sehen';
  @override
  String get backToEdit => 'Zurück zum Bearbeiten';
  @override
  String get centerDiagram => 'Diagramm zentrieren';
  @override
  String get shareFlowFile => '.flow-Datei teilen';
  @override
  String get exportPng => 'Als PNG-Bild exportieren';
  @override
  String get exportSvg => 'Als SVG exportieren';
  @override
  String get exportPdf => 'Als PDF exportieren';
  @override
  String get duplicate => 'Duplizieren';
  @override
  String get moveUp => 'Nach oben';
  @override
  String get moveDown => 'Nach unten';
  @override
  String get arduinoSketch => 'Arduino-Sketch';
  @override
  String get chooseSketchFolder => 'Wähle, wo der Sketch-Ordner erstellt wird';
  @override
  String get arduinoSketchFile => 'Arduino-Sketch (.ino)';
  @override
  String get arduinoSketchHelp => 'Mit der Arduino IDE öffnen und auf die Platine hochladen';
  @override
  String sketchSaved(String path) => 'Sketch gespeichert in $path';
  @override
  String wiringLine(String name, String pin, String mode) => '$name: Pin $pin, $mode';
  @override
  String get pdfWiring => 'Anschlüsse';
  @override
  String get pdfCode => 'Code';
  @override
  String get defaultFileName => 'diagramm';
  @override
  String get blockDeclare => 'Variable deklarieren';
  @override
  String get blockAssign => 'Zuweisung';
  @override
  String get blockInput => 'Eingabe (input)';
  @override
  String get blockOutput => 'Ausgabe (output)';
  @override
  String get blockIf => 'Wenn … dann … sonst';
  @override
  String get blockWhile => 'Solange (while)';
  @override
  String get blockDoWhile => 'Wiederhole … solange (do-while)';
  @override
  String get blockFor => 'Zählschleife (for)';
  @override
  String get blockComment => 'Kommentar';
  @override
  String get blockDigitalRead => 'digitalRead (Digitaleingang)';
  @override
  String get blockAnalogRead => 'analogRead (Analogeingang)';
  @override
  String get blockDigitalWrite => 'digitalWrite (Digitalausgang)';
  @override
  String get blockAnalogWrite => 'analogWrite (PWM-Ausgang)';
  @override
  String get blockDelay => 'delay (warten)';
  @override
  String get fieldVarToModify => 'Zu ändernde Variable';
  @override
  String get fieldNewValue => 'Neuer Wert';
  @override
  String get hintNewValue => 'z. B. a + 1';
  @override
  String get fieldVarToRead => 'Variable für die Eingabe';
  @override
  String get fieldWhatToWrite => 'Was ausgegeben wird';
  @override
  String get hintWrite => 'z. B. "Ergebnis: " & r';
  @override
  String get fieldCondition => 'Bedingung';
  @override
  String get hintCondition => 'z. B. a > b';
  @override
  String get fieldCounter => 'Zähler (Ganzzahl-Variable)';
  @override
  String get fieldFrom => 'Von';
  @override
  String get fieldTo => 'Bis (einschließlich)';
  @override
  String get fieldStep => 'Schrittweite';
  @override
  String get hintFrom => 'z. B. 1';
  @override
  String get hintTo => 'z. B. n';
  @override
  String get fieldCommentText => 'Kommentartext';
  @override
  String get fieldValue => 'Wert';
  @override
  String get hintHighLow => 'HIGH oder LOW';
  @override
  String get fieldPwmValue => 'Wert (0–255)';
  @override
  String get hintPwm => 'z. B. 128';
  @override
  String get fieldDelayMs => 'Wartezeit in Millisekunden';
  @override
  String get hintDelay => 'z. B. 500 (halbe Sekunde)';
  @override
  String get fieldReadTarget => 'Variable für den Messwert';
  @override
  String get readsDigital => 'Liest HIGH (1) oder LOW (0).';
  @override
  String get readsAnalog => 'Liest einen Wert von 0 (0 V) bis 1023 (5 V).';
  @override
  String varExists(String name) => "es gibt schon eine Variable '$name'";
  @override
  String get fieldVarName => 'Name der Variable';
  @override
  String get hintVarName => 'z. B. summe';
  @override
  String get fieldType => 'Typ';
  @override
  String get noIntegerVariables =>
      'Keine Variable vom Typ Ganzzahl: füge zuerst einen Block »$blockDeclare« hinzu.';
  @override
  String get noVariables => 'Keine Variablen: füge zuerst einen Block »$blockDeclare« hinzu.';
  @override
  String notDeclared(String name) => '$name (nicht deklariert)';
  @override
  String get noInputPins => 'Kein Eingang konfiguriert';
  @override
  String get noAnalogPins => 'Kein Analogeingang konfiguriert';
  @override
  String get noOutputPins => 'Kein Ausgang konfiguriert';
  @override
  String get addFromPins => ': füge ihn unter »$pinsAndBoard« hinzu (Schaltfläche Pin oben).';
  @override
  String get noPwmTag => ' · kein PWM';
  @override
  String pwmOn(String board, String pins) => 'PWM auf $board: $pins';
  @override
  String column(int column, String message) => 'Spalte $column: $message';

  // ================================================================ esecuzione (pannello)
  @override
  String get variables => 'Variablen';
  @override
  String get console => 'Konsole';
  @override
  String get restart => 'Neu starten';
  @override
  String get pause => 'Pause';
  @override
  String get oneStep => 'Ein Schritt';
  @override
  String get toEnd => 'Bis zum Ende';
  @override
  String get statusReady => 'Bereit: drücke ▶ oder ⏭';
  @override
  String statusPaused(int steps) => 'Pausiert · Schritt $steps';
  @override
  String statusRunning(int steps) => 'Läuft · Schritt $steps';
  @override
  String statusWaiting(String variable, String type) => 'Gib einen Wert für $variable ein ($type)';
  @override
  String statusFinished(int steps) =>
      steps == 1 ? 'Beendet nach 1 Schritt' : 'Beendet nach $steps Schritten';
  @override
  String get statusFailed => 'Fehler bei der Ausführung';
  @override
  String condition(bool value) => 'Bedingung: ${value ? 'wahr' : 'falsch'}';
  @override
  String get send => 'Senden';
  @override
  String get noVariablesYet => 'Noch keine Variablen deklariert';
  @override
  String get consoleEmpty => 'Hier erscheint die Ausgabe des Programms';

  // ================================================================ codice
  @override
  String get codeHasErrors => 'Das Diagramm enthält Fehler: der Code funktioniert eventuell nicht.';
  @override
  String get copy => 'Kopieren';
  @override
  String get codeCopied => 'Code kopiert';

  // ================================================================ pin e scheda
  @override
  String get addPin => 'Pin hinzufügen';
  @override
  String get board => 'Board';
  @override
  String get serialBaud => 'Seriell (Baud)';
  @override
  String get toFix => 'Zu korrigieren';
  @override
  String get usedNotConfigured => 'Im Diagramm verwendet, aber nicht konfiguriert';
  @override
  String suggestionTitle(String name, String mode, String? pin) =>
      '$name → $mode${pin == null ? '' : ' (Pin $pin)'}';
  @override
  String usedIn(String where) => 'in: $where';
  @override
  String get wiring => 'Anschlüsse';
  @override
  String get tapPinHint => 'Tippe in der Abbildung auf einen Pin, um ihn zu konfigurieren.';
  @override
  String get configuredPins => 'Konfigurierte Pins';
  @override
  String get noPins => 'Keine Pins';
  @override
  String get noPinsHint =>
      'Gib jedem Anschluss einen Namen (z. B. LED an Pin 13): in den Blöcken verwendest du '
      'dann den Namen.';
  @override
  String get pwmTag => 'PWM';
  @override
  String get onBoardLed => 'LED auf dem Board';
  @override
  String removePin(String name) => '$name entfernen';
  @override
  String get generatedSetup => 'Erzeugtes setup()';
  @override
  String get setupNote =>
      'pinMode und Serial.begin werden automatisch aktualisiert. Blöcke, die du im '
      'setup()-Teil des Diagramms hinzufügst, werden direkt danach ausgeführt.';
  @override
  String get pinNameExists => 'es gibt schon einen Pin mit diesem Namen';
  @override
  String get variableNameExists => 'es gibt schon eine Variable mit diesem Namen';
  @override
  String get analogTag => 'analog';
  @override
  String get serialTag => 'seriell';
  @override
  String pinOption(String pin, List<String> tags) =>
      tags.isEmpty ? 'Pin $pin' : 'Pin $pin  ·  ${tags.join(', ')}';
  @override
  String get newPin => 'Neuer Pin';
  @override
  String get editPin => 'Pin bearbeiten';
  @override
  String get hintPinName => 'z. B. LED, TASTER, SENSOR';
  @override
  String get mode => 'Modus';
  @override
  String get pwmNeeded => 'Ein PWM-Pin (~) ist nötig: Das Diagramm verwendet ihn mit analogWrite.';
  @override
  String get pullupNote =>
      'Mit Pull-up liest der Pin im Ruhezustand HIGH und LOW, wenn der Taster '
      '(gegen GND geschaltet) gedrückt ist.';
  @override
  String get microcontroller => 'Mikrocontroller';
  @override
  String boardSemantics(String board) =>
      'Abbildung: $board. Tippe auf einen Pin, um ihn zu konfigurieren';

  // ================================================================ informazioni
  @override
  String version(String v) => 'Version $v';
  @override
  String get aboutDescription =>
      'Editor für strukturierte, ausführbare Programmablaufpläne für Lehrkräfte und '
      'Lernende: Du baust den Algorithmus aus Blöcken, führst ihn Schritt für Schritt aus '
      'und erzeugst daraus Code (Pseudocode, Python, C, Arduino).';
  @override
  String madeBy(String author) => 'Entwickelt von $author.';
  @override
  String get privacy => 'Datenschutz';
  @override
  String get noAccount => 'Kein Konto';
  @override
  String get noAds => 'Keine Werbung';
  @override
  String get noDataCollection => 'Keine Datenerhebung';
  @override
  String get dataStaysOnDevice => 'Die Diagramme bleiben auf dem Gerät';
  @override
  String get privacySummary =>
      'Die App enthält keine Analyse-, Werbe- oder Fehlerberichtssysteme und nutzt kein '
      'Internet. Dateien werden direkt zwischen Personen geteilt (AirDrop, Mail, Dateien …).';
  @override
  String get privacyPolicy => 'Datenschutzerklärung';
  @override
  String get guideBlocks => 'Kurzanleitung: die Blöcke';
  @override
  String get guideExpressions => 'Kurzanleitung: die Ausdrücke';
  @override
  List<(String, String)> get guideBlockItems => const [
    ('Start / Ende', 'Wo der Algorithmus beginnt und wo er endet.'),
    ('Deklaration', 'Erzeugt eine Variable: Ganzzahl, Kommazahl, Zeichenkette, Wahrheitswert.'),
    ('Zuweisung', 'Berechnet einen Wert und speichert ihn in einer Variable: a ← b + 1.'),
    ('Eingabe / Ausgabe', 'Tastatur und Konsole (beim Arduino: serielle Schnittstelle).'),
    ('Verzweigung', 'Wenn, Solange, Wiederhole…solange: die Bedingung ist wahr oder falsch.'),
    ('Zählschleife', 'Ein Zähler läuft von einem Wert bis zu einem anderen, mit Schrittweite.'),
    ('Arduino-Pins', 'digitalRead/Write, analogRead/Write: Ein- und Ausgänge.'),
    ('delay', 'Wartezeit in Millisekunden (Arduino).'),
  ];
  @override
  List<(String, String)> get guideExpressionItems => const [
    ('Zahlen und Text', '12   3.14   "hallo"   wahr   falsch'),
    ('Arithmetik', '+  -  *  /  %   (7 / 2 = 3.5, 7 % 2 = 1)'),
    ('Vergleiche', '==  !=  <  <=  >  >='),
    ('Logik', 'and  or  not   (auch &&  ||  !)'),
    ('Text verbinden', '"Summe: " & s'),
  ];
  @override
  String get availableFunctions => 'Verfügbare Funktionen:';
  @override
  String get license => 'Lizenz';
  @override
  String licenseText(String license) =>
      'Öffentlicher, überprüfbarer Quellcode (source-available) unter der Lizenz $license: '
      'freie Nutzung für nicht-kommerzielle Zwecke.';
  @override
  String get componentLicenses => 'Lizenzen der verwendeten Komponenten';

  // ================================================================ informativa privacy
  @override
  String get privacyUpdated => 'Zuletzt aktualisiert: 21. November 2026';
  @override
  List<(String, List<String>)> privacySections(
    String app,
    String author,
    String license,
    String contact,
  ) => [
    (
      'Kurz gesagt',
      [
        '$app erhebt, überträgt und verkauft keine personenbezogenen Daten.',
        'Es ist kein Konto nötig und es gibt keine Registrierung.',
        'Die App enthält keine Werbung.',
        'Die Diagramme bleiben auf deinem Gerät.',
      ],
    ),
    (
      'Verantwortlich',
      [
        '$app wird von $author entwickelt. Da die App keine personenbezogenen Daten erhebt, '
            'gelangen keine Daten der Nutzer zum Entwickler.',
      ],
    ),
    (
      'Welche Daten die App verwendet',
      [
        'Nur die Diagramme, die du erstellst, gespeichert im Speicher der App auf dem Gerät, und die Wahl des Designs (hell oder dunkel). Auf iPhone und iPad sind die Diagramme auch in der App Dateien sichtbar, im Ordner von $app.',
        'Die App verwendet keine Namen, E-Mail-Adressen, Standortdaten, Fotos, Kontakte, Mikrofon, Kamera, Geräte- oder Werbekennungen.',
        'Wenn die Gerätesicherung aktiv ist (iCloud, Google oder Time Machine auf dem Mac), kann das Betriebssystem die Diagramme in die Sicherung aufnehmen, wie die Dokumente jeder anderen App. Das ist ein Dienst des Systems, gesteuert über die Einstellungen des Geräts.',
      ],
    ),
    (
      'Internetverbindung',
      [
        'Die App funktioniert ohne Verbindung und sendet nichts ins Netz: kein Server, kein '
            'externer Dienst.',
      ],
    ),
    (
      'Dienste von Drittanbietern',
      [
        'Keine Analyse- oder Statistiksysteme, keine Werbung und keine automatischen '
            'Fehlerberichte. Die Komponenten, mit denen die App gebaut ist, stehen unter '
            '»$componentLicenses«.',
      ],
    ),
    (
      'Teilen von Dateien',
      [
        'Ein Diagramm, ein Bild, ein PDF oder der Code verlassen die App nur, wenn du selbst »$share«, »Exportieren« oder am Computer »$saveAs« wählst. Du entscheidest, an wen oder wohin du es sendest (AirDrop, Mail, Dateien …) oder in welchem Ordner du es speicherst. Ab dann gelten die Regeln der App oder des Dienstes, den du gewählt hast.',
        'Eine empfangene .flow-Datei öffnest du mit »$openFlowFile« oder durch Tippen in Mail, Dateien oder im Finder: Die App liest nur diese Datei und speichert eine Kopie bei deinen Diagrammen.',
      ],
    ),
    (
      'In der Schule',
      [
        'Die App ist für Lehrkräfte und Lernende gedacht und fragt keine personenbezogenen '
            'Daten ab. Tipp: Gib in Diagrammnamen und Texten keine personenbezogenen Daten ein '
            '(zum Beispiel Vor- und Nachnamen von Schülerinnen und Schülern), besonders wenn '
            'die Dateien geteilt werden.',
      ],
    ),
    (
      'Daten löschen',
      [
        'Du kannst ein Diagramm aus der Liste auf dem Startbildschirm löschen. Wenn du die App auf iPhone, iPad, Android oder Windows deinstallierst, löscht das System alle darin gespeicherten Diagramme. Auf dem Mac bleiben die Diagramme, wenn du die App aus dem Ordner Programme entfernst, in ihrem Datenordner (Library › Containers › $app); diesen kannst du löschen. Kopien, die du anderswo geteilt oder exportiert hast, bleiben in jedem Fall erhalten.',
      ],
    ),
    (
      'Überprüfbarkeit',
      [
        'Der Code von $app ist öffentlich (source-available, Lizenz $license): Jeder kann '
            'überprüfen, dass sich die App so verhält, wie hier beschrieben.',
      ],
    ),
    (
      'Änderungen und Kontakt',
      [
        'Wenn sich diese Datenschutzerklärung ändert, steht die neue Version mit '
            'aktualisiertem Datum auf dieser Seite. Bei Fragen: $contact.',
      ],
    ),
  ];

  // ================================================================ componenti e scelta del pin
  @override
  String get componentLed => 'LED';
  @override
  String get componentButton => 'Taster';
  @override
  String get componentPotentiometer => 'Potentiometer';
  @override
  String get componentOther => 'Anderes';
  @override
  String get whatToConnect => 'Was schließt du an?';
  @override
  String get digitalPinsTitle => 'Digitale Pins';
  @override
  String get analogPinsTitle => 'Analoge Pins';
  @override
  String pinSwapNotice(String other, String otherNewPin) =>
      'Dieser Pin ist von $other belegt: Die beiden werden getauscht, $other kommt auf Pin $otherNewPin.';
  @override
  String pinMoveNotice(String other, String newPin) =>
      'Dieser Pin ist von $other belegt; $other wird auf Pin $newPin verschoben.';
  @override
  String pinCannotSwap(String other, String pin) =>
      'Dieser Pin ist von $other belegt, und $other kann nicht auf Pin $pin: Wähle einen anderen Pin.';
  @override
  String pinCannotMove(String other) =>
      'Dieser Pin ist von $other belegt und es gibt keinen anderen passenden freien Pin: Wähle einen anderen Pin.';
  @override
  String pinMoved(String name, String pin) => '$name auf Pin $pin verschoben';

  // ================================================================ esercizi

  @override
  String get exercise => 'Aufgabe';
  @override
  String get exercises => 'Aufgaben';
  @override
  String get exerciseCreate => 'Aufgabe erstellen';
  @override
  String get exerciseEdit => 'Aufgabe bearbeiten';
  @override
  String get exerciseText => 'Aufgabenstellung';
  @override
  String get exerciseTextHint => 'Was soll das Diagramm tun? Gib auch an, was es ausgeben soll.';
  @override
  String get testCases => 'Testfälle';
  @override
  String testCase(int n) => 'Testfall $n';
  @override
  String get hiddenCase => 'Verdeckter Testfall';
  @override
  String get caseInputs => 'Eingabewerte';
  @override
  String get caseInputsHint => 'Ein Wert pro Zeile, in der Reihenfolge des Einlesens';
  @override
  String get caseExpected => 'Erwartete Ausgabe';
  @override
  String get caseExpectedHint => 'Eine Zeile pro ausgegebenem Wert';
  @override
  String get caseActual => 'Tatsächliche Ausgabe';
  @override
  String get caseHidden => 'Vor den Lernenden verborgen';
  @override
  String get addCase => 'Testfall hinzufügen';
  @override
  String get removeCase => 'Testfall löschen';
  @override
  String get fillFromDiagram => 'Aus dem Diagramm berechnen';
  @override
  String get fillFromDiagramHelp =>
      'Führt das Diagramm mit den Eingabewerten jedes Testfalls aus und übernimmt die Ausgabe als erwartete Ausgabe.';
  @override
  String filledCases(int n) =>
      n == 1 ? 'Ausgabe für 1 Testfall berechnet' : 'Ausgabe für $n Testfälle berechnet';
  @override
  String fillProblem(int n, String problem) => 'Testfall $n: $problem';
  @override
  String get removeExercise => 'Aufgabe entfernen';
  @override
  String get removeExerciseBody =>
      'Aufgabenstellung und Testfälle werden entfernt. Das Diagramm bleibt erhalten.';
  @override
  String get remove => 'Entfernen';
  @override
  String get shareExercise => 'Als Aufgabe teilen';
  @override
  String get shareExerciseHelp =>
      'Ohne deine Lösung: Die Lernenden beginnen mit einem leeren Diagramm und können Aufgabe und Testfälle nicht ändern.';
  @override
  String get verify => 'Prüfen';
  @override
  String get verifyFixFirst => 'Behebe zuerst die markierten Fehler im Diagramm.';
  @override
  String get verifyAllPassed => 'Alle Testfälle bestanden!';
  @override
  String verifyPassed(int ok, int total) =>
      '$ok von $total ${total == 1 ? 'Testfall' : 'Testfällen'} bestanden';
  @override
  String get verifyResults => 'Prüfergebnis';
  @override
  String get casePassed => 'bestanden';
  @override
  String get caseFailed => 'nicht bestanden';
  @override
  String get outcomeWrongOutput => 'Die Ausgabe stimmt nicht mit der erwarteten überein.';
  @override
  String get outcomeMissingInput => 'Das Diagramm liest mehr Werte ein, als der Testfall liefert.';
  @override
  String get outcomeUnusedInput => 'Das Diagramm endet, ohne alle Werte des Testfalls einzulesen.';
  @override
  String outcomeBadInput(String message) => 'Ein Eingabewert passt nicht: $message';
  @override
  String outcomeError(String message) => 'Fehler: $message';
  @override
  String get noOutput => '(keine Ausgabe)';
  @override
  String get noInputs => '(keine)';
  @override
  String get exerciseLocked =>
      'Erhaltene Aufgabe: Aufgabenstellung und Testfälle können nicht geändert werden.';
  @override
  String hiddenCasesCount(int n) =>
      n == 1 ? 'dazu 1 verdeckter Testfall' : 'dazu $n verdeckte Testfälle';
  @override
  String get noCases => 'Keine Testfälle: Füge mindestens einen hinzu, um prüfen zu können.';
  @override
  String get showTask => 'Aufgabenstellung lesen';

  // ================================================================ simulazione Arduino

  @override
  String get whatPin => 'der Pin';
  @override
  String get whatValue => 'der Wert';
  @override
  String runTooManyStepsLoop(int n) =>
      'mehr als $n Schritte in einem einzigen Durchlauf von loop(): vielleicht eine Endlosschleife (wird die Bedingung nie falsch?)';
  @override
  String runDelayNegative(int ms) => 'delay darf nicht negativ sein, hat aber den Wert $ms';
  @override
  String runPwmRange(int value, int max) =>
      'analogWrite akzeptiert Werte von 0 bis $max, der Wert ist aber $value';
  @override
  String runPinNotOnBoard(int pin, String board) => 'Pin $pin gibt es auf der Platine $board nicht';
  @override
  String runAnalogReadPin(String pin) =>
      'analogRead funktioniert nur an analogen Eingängen (A0…), nicht an Pin $pin';
  @override
  String get circuit => 'Schaltung';
  @override
  String simLoop(int n) => 'loop()-Durchlauf $n';
  @override
  String get toLoopEnd => 'Bis zum Ende dieses loop()-Durchlaufs';
  @override
  String get ledOn => 'an';
  @override
  String get ledOff => 'aus';
  @override
  String get pressed => 'gedrückt';
  @override
  String get released => 'losgelassen';
  @override
  String get tapToPress => 'Tippen zum Drücken oder Loslassen';
  @override
  String noSimPins(String pinsAndBoard) =>
      'Keine Pins konfiguriert: Füge sie unter „$pinsAndBoard“ hinzu, um sie hier zu sehen.';
  @override
  String get simNote =>
      'Simulation: Die Zeit pro Block ist angenähert; delay dauert beim automatischen Ablauf wirklich so lange.';
}
