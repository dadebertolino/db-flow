// Testi in italiano (lingua di riferimento).
import '../expr/types.dart';
import 'tr.dart';

class TrIt extends Tr {
  const TrIt();

  @override
  AppLanguage get language => AppLanguage.it;

  String _t(VarType t) => switch (t) {
    VarType.integer => typeInteger,
    VarType.real => typeReal,
    VarType.string => typeString,
    VarType.boolean => typeBoolean,
  };

  // ================================================================ tipi e valori
  @override
  String get typeInteger => 'intero';
  @override
  String get typeReal => 'reale';
  @override
  String get typeString => 'stringa';
  @override
  String get typeBoolean => 'booleano';
  @override
  String aType(VarType t) => switch (t) {
    VarType.string => 'una stringa',
    _ => 'un ${_t(t)}',
  };
  @override
  String get trueWord => 'vero';
  @override
  String get falseWord => 'falso';
  @override
  String get realUndefined => 'non definito';
  @override
  String get realInfinite => 'infinito';

  // ================================================================ lexer
  @override
  String get lexIncompleteNumber => 'numero incompleto: manca la parte decimale dopo il punto';
  @override
  String get lexNameStartsWithDigit => 'un nome non può iniziare con una cifra';
  @override
  String get lexNumberTooLarge => 'numero troppo grande';
  @override
  String lexAccentedLetter(String ch) =>
      "lettera '$ch' non ammessa nei nomi: usa lettere senza accento";
  @override
  String get lexUnclosedString => 'stringa non chiusa: manca la virgoletta "';
  @override
  String get lexUseOr => "per 'oppure' usa 'or' (o '||')";
  @override
  String get lexUseDoubleEquals => "per confrontare usa '=='; il singolo '=' non è ammesso qui";
  @override
  String get lexUseNotEquals => "per 'diverso da' usa '!='";
  @override
  String get lexUseDoubleQuotes => 'le stringhe vanno tra virgolette doppie: "testo"';
  @override
  String lexInvalidChar(String ch) => "carattere non valido: '$ch'";
  @override
  String get idEmpty => 'il nome è vuoto';
  @override
  String get idHasSpaces => 'un nome non può contenere spazi (usa _ al posto dello spazio)';
  @override
  String get idInvalidChars => 'usa solo lettere senza accento, cifre e _';
  @override
  String idIsFunction(String name) => "'$name' è il nome di una funzione";
  @override
  String idReserved(String name) => "'$name' è una parola riservata";

  // ================================================================ parser
  @override
  String get parseEmpty => 'espressione vuota';
  @override
  String get parseChainedComparison =>
      'confronti concatenati non ammessi: scrivi ad esempio a < b and b < c';
  @override
  String get parseMissingCloseParen => "manca la parentesi ')' che chiude questa '('";
  @override
  String get parseIncomplete => 'espressione incompleta: manca un valore alla fine';
  @override
  String get parseMissingValueBeforeClose => "manca un valore prima di ')'";
  @override
  String get parseUnexpectedComma => 'virgola non attesa: per i decimali usa il punto (3.14)';
  @override
  String parseMissingValueBefore(String token) => "manca un valore prima di '$token'";
  @override
  String parseUnknownFunction(String name) => "funzione '$name' sconosciuta";
  @override
  String parseArity(String fn, int arity, int given) =>
      '$fn vuole ${switch (arity) {
        0 => 'le parentesi vuote: $fn()',
        1 => '1 argomento',
        _ => '$arity argomenti',
      }}, ne hai scritti $given';
  @override
  String get parseUnmatchedClose => "parentesi ')' senza la corrispondente '('";
  @override
  String parseMissingOperatorBefore(String token) => "manca un operatore prima di '$token'";
  @override
  String parseUnexpected(String token) => "'$token' non atteso qui";

  // ================================================================ controllo dei tipi
  @override
  String typeUndeclared(String name) => "variabile '$name' non dichiarata";
  @override
  String typeUndeclaredLowercase(String name, String lower) =>
      "variabile '$name' non dichiarata: scrivi '$lower' in minuscolo";
  @override
  String typeNegNumber(VarType t) => "il segno '-' si applica a un numero, non a ${aType(t)}";
  @override
  String typeNotBoolean(VarType t) =>
      "'not' si applica a un booleano, non a ${aType(t)}; se serve, usa le parentesi: not (a > b)";
  @override
  String typePair(VarType a, VarType b) => '${_t(a)} e ${_t(b)}';
  @override
  String typeArith(String sym, VarType a, VarType b) =>
      "'$sym' si usa tra numeri, non tra ${typePair(a, b)}";
  @override
  String typePlusText(VarType a, VarType b) =>
      "'+' non unisce ${typePair(a, b)}: per comporre un testo usa '&'";
  @override
  String typeModInts(VarType a, VarType b) =>
      "'%' (resto) si usa tra interi, non tra ${typePair(a, b)}";
  @override
  String typeCannotCompare(VarType a, VarType b) => 'non si possono confrontare ${typePair(a, b)}';
  @override
  String typeCompareNumStr(String sym, VarType a, VarType b) =>
      "'$sym' si usa tra numeri o tra stringhe, non tra ${typePair(a, b)}";
  @override
  String typeLogical(String sym, VarType a, VarType b) =>
      "'$sym' si usa tra condizioni (booleani), non tra ${typePair(a, b)}";
  @override
  String typeArduinoOnly(String fn) => "'$fn' si può usare solo nei diagrammi Arduino";
  @override
  String fnNeedsNumber(String fn, VarType t) => '$fn richiede un numero, non ${aType(t)}';
  @override
  String fnNeedsString(String fn, VarType t) => '$fn richiede una stringa, non ${aType(t)}';
  @override
  String fnNeedsInteger(String fn, VarType t) => '$fn richiede un intero, non ${aType(t)}';
  @override
  String fnNeedsPin(String fn, VarType t) => '$fn richiede un pin (intero), non ${aType(t)}';
  @override
  String functionSignature(String fn) => switch (fn) {
    'abs' || 'sqrt' || 'int' || 'round' => '$fn(numero)',
    'len' => 'len(stringa)',
    'random' => 'random(n)',
    'digitalRead' || 'analogRead' => '$fn(pin)',
    _ => '$fn()',
  };
  @override
  String functionDescription(String fn) => switch (fn) {
    'abs' => 'valore assoluto',
    'sqrt' => 'radice quadrata (risultato reale)',
    'int' => 'parte intera, tronca i decimali: int(3.9) = 3, int(-3.9) = -3',
    'round' => "arrotonda all'intero più vicino (0.5 si arrotonda per eccesso in valore assoluto)",
    'len' => 'numero di caratteri della stringa',
    'random' => 'intero casuale tra 0 e n-1',
    'digitalRead' => 'legge un ingresso digitale: HIGH (1) o LOW (0)',
    'analogRead' => 'legge un ingresso analogico: da 0 a 1023',
    'millis' => "millisecondi trascorsi dall'accensione",
    _ => fn,
  };

  // ================================================================ validazione
  @override
  String get valChooseVariable => 'scegli una variabile';
  @override
  String valConstant(String name) => "'$name' è una costante: non può cambiare valore";
  @override
  String valUndeclared(String name) => "variabile '$name' non dichiarata";
  @override
  String valConditionBoolean(VarType t) =>
      'la condizione deve essere vera o falsa (booleana), invece è ${aType(t)}';
  @override
  String valNameIsPin(String name) => "'$name' è già il nome di un pin o di una costante";
  @override
  String valAlreadyDeclared(String name) => "la variabile '$name' è già dichiarata";
  @override
  String valCounterInteger(String name) => "il contatore '$name' deve essere una variabile intera";
  @override
  String get whatFrom => 'il valore iniziale';
  @override
  String get whatTo => 'il valore finale';
  @override
  String get whatStep => 'il passo';
  @override
  String valMustBeInteger(String what, VarType t) =>
      '$what deve essere un intero, invece è ${aType(t)}';
  @override
  String get valStepZero => 'il passo non può essere 0';
  @override
  String valHighLow(VarType t) => 'il valore deve essere HIGH o LOW, invece è ${aType(t)}';
  @override
  String valPwmInteger(VarType t) =>
      'il valore deve essere un intero da 0 a 255, invece è ${aType(t)}';
  @override
  String valPwmRange(int max, int value) =>
      'il valore di analogWrite va da 0 a $max, invece è $value';
  @override
  String valReadIntoInteger(String name) =>
      "'$name' deve essere una variabile intera per ricevere la lettura";
  @override
  String valDelayInteger(VarType t) => "l'attesa è in millisecondi interi, invece è ${aType(t)}";
  @override
  String get valDelayNegative => "l'attesa non può essere negativa";
  @override
  String get valArduinoOnlyBlock => 'questo blocco si può usare solo nei diagrammi Arduino';
  @override
  String get valChoosePin => 'scegli un pin';
  @override
  String valPinNotConfigured(String name) =>
      "pin '$name' non configurato: aggiungilo in «$pinsAndBoard»";
  @override
  String valPinMustBeInt(VarType t) =>
      'il pin deve essere un numero intero o il nome di un pin, invece è ${aType(t)}';
  @override
  String valPinNamed(String name, String pin) => "'$name' (pin $pin)";
  @override
  String valPinNumber(String pin) => 'il pin $pin';
  @override
  String valPinNotOnBoard(String pin, String board) => 'il pin $pin non esiste su $board';
  @override
  String valPinNotConfiguredLabel(String label) =>
      '$label non è configurato: aggiungilo in «$pinsAndBoard» con un nome (es. LED)';
  @override
  String valPinNotOutput(String label, String mode) =>
      "$label è configurato come $mode: per scriverci dev'essere un'uscita";
  @override
  String valNoPwm(String label, String board, String pins) =>
      '$label non supporta analogWrite (PWM): su $board usa uno dei pin $pins';
  @override
  String valPinIsOutput(String label) =>
      "$label è un'uscita: per leggerlo configuralo come ingresso";
  @override
  String valAnalogReadPins(String pins) => 'analogRead funziona solo sui pin $pins';
  @override
  String valAnalogAlias(String label, String digital) =>
      '$label si usa solo con analogRead(): come pin digitale è il pin $digital.';
  @override
  String valAnalogOnly(String label) =>
      '$label è solo un ingresso analogico: si legge con analogRead().';
  @override
  String valAnalogReadMode(String label) =>
      '$label va configurato come ingresso analogico per usare analogRead';
  @override
  String valPinNameError(String name, String error) => "nome del pin '$name': $error";
  @override
  String valPinNameTwice(String name) => "il nome '$name' è usato per due pin";
  @override
  String valPinNotExists(String name, String pin, String board) =>
      '$name: il pin $pin non esiste su $board';
  @override
  String valPinTwice(String pin) => 'il pin $pin è configurato due volte';
  @override
  String valPinModeInvalid(String name, String pin, String mode) =>
      '$name: il pin $pin non può essere $mode';
  @override
  String valSerialPins(String name, List<String> pins) =>
      '$name: i pin ${pins.join(' e ')} servono alla comunicazione seriale (Leggi/Scrivi): '
      'scegli un altro pin';
  @override
  String valAssignRealToInt(String target) =>
      "'$target' è intera ma il valore è reale: usa int(...) o round(...), "
      "oppure dichiara '$target' reale";
  @override
  String valAssignType(VarType value, String target, VarType targetType) =>
      "non puoi assegnare ${aType(value)} a '$target', che è di tipo ${_t(targetType)}";

  // ================================================================ file .flow
  @override
  String get fileDamaged => 'il file è danneggiato o non è un diagramma DB Flow';
  @override
  String get fileNotFlow => 'il file non è un diagramma DB Flow';
  @override
  String get fileBadVersion => 'versione del file mancante o non valida';
  @override
  String get fileTooNew =>
      "il file è stato creato con una versione più recente dell'app: aggiorna DB Flow";
  @override
  String fileFieldMissing(String key) => "campo '$key' mancante o non valido";
  @override
  String fileFieldInvalid(String key) => "campo '$key' non valido";
  @override
  String get fileBadBlock => 'blocco non valido';
  @override
  String fileUnknownBlock(String t) => "tipo di blocco sconosciuto: '$t'";
  @override
  String fileUnknownType(String name) => "tipo sconosciuto: '$name'";
  @override
  String get untitled => 'Senza nome';

  // ================================================================ esecuzione
  @override
  String runUndeclared(String name) => "la variabile '$name' non è stata dichiarata";
  @override
  String runNoValue(String name) =>
      "la variabile '$name' non ha ancora un valore: assegnale un valore o leggila prima di usarla";
  @override
  String runAssignType(VarType value, String name, VarType varType) =>
      "non puoi assegnare ${aType(value)} a '$name', che è di tipo ${_t(varType)}";
  @override
  String get inputNeedInteger => 'scrivi un numero intero, ad esempio 42';
  @override
  String get inputNeedNumber => 'scrivi un numero, ad esempio 3.5';
  @override
  String get inputNeedBoolean => 'scrivi vero oppure falso';
  @override
  String runTypeInvalid(String what) => 'tipo non valido: $what';
  @override
  String get runNeedNumber => 'serve un numero';
  @override
  String get runNeedBoolean => 'serve un booleano';
  @override
  String runOpNotApplicable(String op, VarType t) => "'$op' non si applica a ${aType(t)}";
  @override
  String get runDivZero => 'divisione per zero';
  @override
  String get runModInts => "'%' si usa tra interi";
  @override
  String get runModZero => 'resto di una divisione per zero';
  @override
  String runSqrtNegative(String value) => 'radice quadrata di un numero negativo ($value)';
  @override
  String runNotFinite(String fn) => '$fn: il valore non è un numero finito';
  @override
  String get runLenString => 'len richiede una stringa';
  @override
  String get runRandomInt => 'random richiede un intero';
  @override
  String runRandomPositive(int n) => 'random(n) richiede n maggiore di 0, invece n = $n';
  @override
  String runNotSimulated(String fn) => "'$fn' non è ancora disponibile nella simulazione";
  @override
  String runTooManySteps(int n) =>
      'superati $n passi: forse il programma contiene un ciclo infinito '
      '(la condizione non diventa mai falsa?)';
  @override
  String runConditionValue(String value) =>
      'la condizione deve essere vera o falsa, invece vale $value';
  @override
  String runMustBeInteger(String what, String value) =>
      '$what deve essere un intero, invece vale $value';
  @override
  String get runStepZero => 'il passo del ciclo non può essere 0';
  @override
  String get runArduinoNotSimulated =>
      'i blocchi Arduino non sono ancora simulati: genera lo sketch';
  @override
  String runCounterInteger(String name) => "il contatore '$name' deve restare intero";
  @override
  String runInvalidExpr(String text) => "espressione non valida: '$text'";
  @override
  String get runInputMissing => 'input mancante';
  @override
  String runFinished(int steps) => 'Programma terminato ($steps passi)';
  @override
  String runErrorLine(String message) => 'Errore: $message';

  // ================================================================ diagramma
  @override
  String get flowStart => 'Inizio';
  @override
  String get flowEnd => 'Fine';
  @override
  String get edgeTrue => 'vero';
  @override
  String get edgeFalse => 'falso';
  @override
  String get flowRepeat => 'ripeti';
  @override
  String labelRead(String variable) => 'Leggi $variable';
  @override
  String labelWrite(String text) => 'Scrivi $text';
  @override
  String labelFor(String variable, String from, String to, String? step) =>
      '$variable da $from a $to${step == null ? '' : ', passo $step'}';
  @override
  String get kindAlgorithm => 'Algoritmo';
  @override
  String get kindArduino => 'Arduino';
  @override
  String get pinModeOutput => 'uscita';
  @override
  String get pinModeInput => 'ingresso';
  @override
  String get pinModeInputPullup => 'ingresso con pull-up';
  @override
  String get pinModeAnalogInput => 'ingresso analogico';

  // ================================================================ codice generato
  @override
  String get codeGenerated => 'Codice generato da DB Flow';
  @override
  String codeGeneratedFor(String board) => 'Codice generato da DB Flow per $board';
  @override
  String get codeConnections => 'Collegamenti:';
  @override
  String codeInvalidExpr(String text) => 'ERRORE: espressione non valida: $text';
  @override
  String codeArduinoOnly(String label) => '$label: disponibile solo su Arduino';
  @override
  String inputPrompt(String variable) => 'Inserisci $variable: ';
  @override
  String get codeAnswerVar => 'risposta';
  @override
  String get codeConcatUnsupported =>
      "concatenazione di testo: usa un blocco Scrivi o un'assegnazione";
  @override
  String get codeLanguagePseudo => 'Pseudocodice';
  @override
  String pAlgorithm(String name) => 'ALGORITMO $name';
  @override
  String get pBegin => 'INIZIO';
  @override
  String get pEnd => 'FINE';
  @override
  String pDeclare(String name, String type) => 'DICHIARA $name COME ${type.toUpperCase()}';
  @override
  String pRead(String variable) => 'LEGGI $variable';
  @override
  String pWrite(String text) => 'SCRIVI $text';
  @override
  String pIf(String cond) => 'SE $cond ALLORA';
  @override
  String get pElse => 'ALTRIMENTI';
  @override
  String get pEndIf => 'FINE SE';
  @override
  String pWhile(String cond) => 'MENTRE $cond ESEGUI';
  @override
  String get pEndWhile => 'FINE MENTRE';
  @override
  String get pRepeat => 'RIPETI';
  @override
  String pRepeatWhile(String cond) => 'MENTRE $cond';
  @override
  String pFor(String variable, String from, String to, String? step) =>
      'PER $variable DA $from A $to${step == null ? '' : ' PASSO $step'} ESEGUI';
  @override
  String get pEndFor => 'FINE PER';
  @override
  String pSketch(String name, String board) => 'SKETCH $name ($board)';
  @override
  String pPin(String name, String pin, String mode) => 'PIN $name = $pin ($mode)';
  @override
  String get pSetup => 'SETUP';
  @override
  String get pEndSetup => 'FINE SETUP';
  @override
  String get pLoop => 'LOOP (ripeti per sempre)';
  @override
  String get pEndLoop => 'FINE LOOP';

  // ================================================================ interfaccia: comuni
  @override
  String get cancel => 'Annulla';
  @override
  String get undo => 'Annulla';
  @override
  String get redo => 'Ripeti';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Elimina';
  @override
  String get share => 'Condividi';
  @override
  String get saveAs => 'Salva con nome…';
  @override
  String get saveFlowFile => 'Salva file .flow…';
  @override
  String get saveExercise => 'Salva come esercizio…';
  @override
  String get more => 'Altro';
  @override
  String get name => 'Nome';
  @override
  String get create => 'Crea';
  @override
  String get insert => 'Inserisci';
  @override
  String get save => 'Salva';
  @override
  String get add => 'Aggiungi';
  @override
  String get edit => 'Modifica';
  @override
  String get run => 'Esegui';
  @override
  String get pin => 'Pin';
  @override
  String get pinsAndBoard => 'Pin e scheda';
  @override
  String get code => 'Codice';
  @override
  String get info => 'Informazioni';
  @override
  String get theme => 'Tema';
  @override
  String get themeSystem => 'Come il dispositivo';
  @override
  String get themeLight => 'Chiaro';
  @override
  String get themeDark => 'Scuro';

  // ================================================================ home
  @override
  String get newDiagram => 'Nuovo diagramma';
  @override
  String get myDiagrams => 'I miei diagrammi';
  @override
  String get noDiagrams => 'Nessun diagramma';
  @override
  String get noDiagramsHint => 'Creane uno nuovo o parti da un esempio.';
  @override
  String get damagedFile => 'File danneggiato';
  @override
  String modified(String date) => 'Modificato: $date';
  @override
  String get examples => 'Esempi';
  @override
  String get examplesArduino => 'Esempi Arduino';
  @override
  String get opensCopy => 'Apre una copia modificabile';
  @override
  String get openFlowFile => 'Apri un file .flow';
  @override
  String openFailed(String message) => 'Impossibile aprire: $message';
  @override
  String importFailed(String message) => 'Impossibile aprire il file: $message';
  @override
  String get importNotFlow => 'Impossibile aprire il file: non è un diagramma DB Flow';
  @override
  String shareFailed(String error) => 'Condivisione non riuscita: $error';
  @override
  String get deleteTitle => 'Eliminare il diagramma?';
  @override
  String deleteBody(String name) => '"$name" verrà eliminato da questo dispositivo.';
  @override
  String get hintNameArduino => 'es. Semaforo';
  @override
  String get hintNameAlgorithm => 'es. Somma di due numeri';
  @override
  String get newArduinoHint =>
      'Il diagramma avrà una parte setup() e una loop(). '
      'Configura i collegamenti con il pulsante «Pin».';

  // ================================================================ editor
  @override
  String saveFailed(String error) => 'Salvataggio non riuscito: $error';
  @override
  String get blockDeleted => 'Blocco eliminato';
  @override
  String get blockDeletedWithContent => 'Blocco eliminato con il suo contenuto';
  @override
  String get diagramName => 'Nome del diagramma';
  @override
  String fixBeforeRun(int count) => count == 1
      ? 'Correggi prima il blocco in rosso, poi potrai eseguire il programma.'
      : 'Correggi prima i $count problemi segnalati in rosso.';
  @override
  String operationFailed(String error) => 'Operazione non riuscita: $error';
  @override
  String get insertBlock => 'Inserisci un blocco';
  @override
  String pinIssues(int count) => count == 1
      ? '$pinsAndBoard: 1 problema da correggere'
      : '$pinsAndBoard: $count problemi da correggere';
  @override
  String blockIssues(int count) => count == 1
      ? '1 problema: tocca il blocco in rosso per vederlo'
      : '$count problemi: tocca i blocchi in rosso per vederli';
  @override
  String get backToEdit => 'Torna a modificare';
  @override
  String get centerDiagram => 'Centra il diagramma';
  @override
  String get shareFlowFile => 'Condividi file .flow';
  @override
  String get exportPng => 'Esporta immagine PNG';
  @override
  String get exportSvg => 'Esporta SVG';
  @override
  String get exportPdf => 'Esporta PDF';
  @override
  String get duplicate => 'Duplica';
  @override
  String get moveUp => 'Sposta su';
  @override
  String get moveDown => 'Sposta giù';
  @override
  String get arduinoSketch => 'Sketch Arduino';
  @override
  String get chooseSketchFolder => 'Scegli dove creare la cartella dello sketch';
  @override
  String get arduinoSketchFile => 'Sketch Arduino (.ino)';
  @override
  String get arduinoSketchHelp => "Da aprire con l'Arduino IDE per caricarlo sulla scheda";
  @override
  String sketchSaved(String path) => 'Sketch salvato in $path';
  @override
  String wiringLine(String name, String pin, String mode) => '$name: pin $pin, $mode';
  @override
  String get pdfWiring => 'Collegamenti';
  @override
  String get pdfCode => 'Codice';
  @override
  String get defaultFileName => 'diagramma';
  @override
  String get blockDeclare => 'Dichiara variabile';
  @override
  String get blockAssign => 'Assegnazione';
  @override
  String get blockInput => 'Leggi (input)';
  @override
  String get blockOutput => 'Scrivi (output)';
  @override
  String get blockIf => 'Se … allora … altrimenti';
  @override
  String get blockWhile => 'Mentre (while)';
  @override
  String get blockDoWhile => 'Ripeti … mentre (do-while)';
  @override
  String get blockFor => 'Per (for)';
  @override
  String get blockComment => 'Commento';
  @override
  String get blockDigitalRead => 'digitalRead (ingresso digitale)';
  @override
  String get blockAnalogRead => 'analogRead (ingresso analogico)';
  @override
  String get blockDigitalWrite => 'digitalWrite (uscita digitale)';
  @override
  String get blockAnalogWrite => 'analogWrite (uscita PWM)';
  @override
  String get blockDelay => 'delay (attesa)';
  @override
  String get fieldVarToModify => 'Variabile da modificare';
  @override
  String get fieldNewValue => 'Nuovo valore';
  @override
  String get hintNewValue => 'es. a + 1';
  @override
  String get fieldVarToRead => 'Variabile in cui leggere';
  @override
  String get fieldWhatToWrite => 'Cosa scrivere';
  @override
  String get hintWrite => 'es. "Risultato: " & r';
  @override
  String get fieldCondition => 'Condizione';
  @override
  String get hintCondition => 'es. a > b';
  @override
  String get fieldCounter => 'Contatore (variabile intera)';
  @override
  String get fieldFrom => 'Da';
  @override
  String get fieldTo => 'A (incluso)';
  @override
  String get fieldStep => 'Passo';
  @override
  String get hintFrom => 'es. 1';
  @override
  String get hintTo => 'es. n';
  @override
  String get fieldCommentText => 'Testo del commento';
  @override
  String get fieldValue => 'Valore';
  @override
  String get hintHighLow => 'HIGH oppure LOW';
  @override
  String get fieldPwmValue => 'Valore (0–255)';
  @override
  String get hintPwm => 'es. 128';
  @override
  String get fieldDelayMs => 'Attesa in millisecondi';
  @override
  String get hintDelay => 'es. 500 (mezzo secondo)';
  @override
  String get fieldReadTarget => 'Variabile che riceve la lettura';
  @override
  String get readsDigital => 'Legge HIGH (1) o LOW (0).';
  @override
  String get readsAnalog => 'Legge un valore da 0 (0 V) a 1023 (5 V).';
  @override
  String varExists(String name) => "esiste già una variabile '$name'";
  @override
  String get fieldVarName => 'Nome della variabile';
  @override
  String get hintVarName => 'es. somma';
  @override
  String get fieldType => 'Tipo';
  @override
  String get noIntegerVariables =>
      "Nessuna variabile intera: aggiungi prima un blocco '$blockDeclare'.";
  @override
  String get noVariables => "Nessuna variabile: aggiungi prima un blocco '$blockDeclare'.";
  @override
  String notDeclared(String name) => '$name (non dichiarata)';
  @override
  String get noInputPins => 'Nessun ingresso configurato';
  @override
  String get noAnalogPins => 'Nessun ingresso analogico configurato';
  @override
  String get noOutputPins => "Nessun pin d'uscita configurato";
  @override
  String get addFromPins => ': aggiungilo da «$pinsAndBoard» (pulsante Pin in alto).';
  @override
  String get noPwmTag => ' · no PWM';
  @override
  String pwmOn(String board, String pins) => 'PWM su $board: $pins';
  @override
  String column(int column, String message) => 'Colonna $column: $message';

  // ================================================================ esecuzione (pannello)
  @override
  String get variables => 'Variabili';
  @override
  String get console => 'Console';
  @override
  String get restart => 'Ricomincia';
  @override
  String get pause => 'Pausa';
  @override
  String get oneStep => 'Un passo';
  @override
  String get toEnd => 'Fino alla fine';
  @override
  String get statusReady => 'Pronto: premi ▶ o ⏭';
  @override
  String statusPaused(int steps) => 'In pausa · passo $steps';
  @override
  String statusRunning(int steps) => 'In esecuzione · passo $steps';
  @override
  String statusWaiting(String variable, String type) => 'Scrivi un valore per $variable ($type)';
  @override
  String statusFinished(int steps) => 'Terminato in $steps passi';
  @override
  String get statusFailed => "Errore durante l'esecuzione";
  @override
  String condition(bool value) => 'condizione: ${value ? 'vera' : 'falsa'}';
  @override
  String get send => 'Invio';
  @override
  String get noVariablesYet => 'Nessuna variabile dichiarata finora';
  @override
  String get consoleEmpty => 'Qui compare ciò che scrive il programma';

  // ================================================================ codice
  @override
  String get codeHasErrors => 'Il diagramma contiene errori: il codice potrebbe non funzionare.';
  @override
  String get copy => 'Copia';
  @override
  String get codeCopied => 'Codice copiato';

  // ================================================================ pin e scheda
  @override
  String get addPin => 'Aggiungi pin';
  @override
  String get board => 'Scheda';
  @override
  String get serialBaud => 'Seriale (baud)';
  @override
  String get toFix => 'Da correggere';
  @override
  String get usedNotConfigured => 'Usati nel diagramma ma non configurati';
  @override
  String suggestionTitle(String name, String mode, String? pin) =>
      '$name → $mode${pin == null ? '' : ' (pin $pin)'}';
  @override
  String usedIn(String where) => 'in: $where';
  @override
  String get wiring => 'Collegamenti';
  @override
  String get tapPinHint => 'Tocca un pin sul disegno per configurarlo.';
  @override
  String get configuredPins => 'Pin configurati';
  @override
  String get noPins => 'Nessun pin';
  @override
  String get noPinsHint =>
      'Dai un nome a ogni collegamento (es. LED sul pin 13): nei blocchi userai il nome.';
  @override
  String get pwmTag => 'PWM';
  @override
  String get onBoardLed => 'LED sulla scheda';
  @override
  String removePin(String name) => 'Rimuovi $name';
  @override
  String get generatedSetup => 'setup() generato';
  @override
  String get setupNote =>
      'I pinMode e Serial.begin si aggiornano da soli. I blocchi che aggiungi nella parte '
      'setup() del diagramma vengono eseguiti subito dopo.';
  @override
  String get pinNameExists => 'esiste già un pin con questo nome';
  @override
  String get variableNameExists => 'esiste già una variabile con questo nome';
  @override
  String get analogTag => 'analogico';
  @override
  String get serialTag => 'seriale';
  @override
  String pinOption(String pin, List<String> tags) =>
      tags.isEmpty ? 'pin $pin' : 'pin $pin  ·  ${tags.join(', ')}';
  @override
  String get newPin => 'Nuovo pin';
  @override
  String get editPin => 'Modifica pin';
  @override
  String get hintPinName => 'es. LED, PULSANTE, SENSORE';
  @override
  String get mode => 'Modo';
  @override
  String get pwmNeeded => 'Serve un pin PWM (~): nel diagramma è usato con analogWrite.';
  @override
  String get pullupNote =>
      'Con il pull-up il pin legge HIGH a riposo e LOW quando il pulsante '
      '(collegato verso GND) è premuto.';
  @override
  String get microcontroller => 'microcontrollore';
  @override
  String boardSemantics(String board) => 'Disegno di $board: tocca un pin per configurarlo';

  // ================================================================ informazioni
  @override
  String version(String v) => 'Versione $v';
  @override
  String get aboutDescription =>
      'Editor di diagrammi di flusso strutturati ed eseguibili, per insegnanti e studenti: '
      "si costruisce l'algoritmo a blocchi, lo si esegue passo passo e se ne genera il codice "
      '(pseudocodice, Python, C, Arduino).';
  @override
  String madeBy(String author) => 'Realizzato dal $author.';
  @override
  String get privacy => 'Privacy';
  @override
  String get noAccount => 'Nessun account';
  @override
  String get noAds => 'Nessuna pubblicità';
  @override
  String get noDataCollection => 'Nessuna raccolta dati';
  @override
  String get dataStaysOnDevice => 'I diagrammi restano sul dispositivo';
  @override
  String get privacySummary =>
      "L'app non contiene sistemi di analisi, pubblicità o segnalazione degli errori e non usa "
      'internet. I file si condividono direttamente tra persone (AirDrop, Mail, File…).';
  @override
  String get privacyPolicy => 'Informativa sulla privacy';
  @override
  String get guideBlocks => 'Guida rapida: i blocchi';
  @override
  String get guideExpressions => 'Guida rapida: le espressioni';
  @override
  List<(String, String)> get guideBlockItems => const [
    ('Inizio / Fine', "Dove comincia e dove termina l'algoritmo."),
    ('Dichiarazione', 'Crea una variabile: intero, reale, stringa, booleano.'),
    ('Assegnazione', 'Calcola un valore e lo mette in una variabile: a ← b + 1.'),
    ('Leggi / Scrivi', 'Ingresso e uscita: tastiera e console (seriale su Arduino).'),
    ('Decisione', 'Se, Mentre, Ripeti…mentre: la condizione è vera o falsa.'),
    ('Ciclo Per', 'Un contatore va da un valore a un altro, con un passo.'),
    ('Pin Arduino', 'digitalRead/Write, analogRead/Write: ingressi e uscite.'),
    ('delay', 'Attesa in millisecondi (Arduino).'),
  ];
  @override
  List<(String, String)> get guideExpressionItems => const [
    ('Numeri e testo', '12   3.14   "ciao"   vero   falso'),
    ('Aritmetica', '+  -  *  /  %   (7 / 2 = 3.5, 7 % 2 = 1)'),
    ('Confronti', '==  !=  <  <=  >  >='),
    ('Logici', 'and  or  not   (anche &&  ||  !)'),
    ('Unire testo', '"Totale: " & t'),
  ];
  @override
  String get availableFunctions => 'Funzioni disponibili:';
  @override
  String get license => 'Licenza';
  @override
  String licenseText(String license) =>
      'Codice pubblico e verificabile (source-available) con licenza $license: '
      'uso libero per scopi non commerciali.';
  @override
  String get componentLicenses => 'Licenze dei componenti usati';

  // ================================================================ informativa privacy
  @override
  String get privacyUpdated => 'Ultimo aggiornamento: 16 novembre 2026';
  @override
  List<(String, List<String>)> privacySections(
    String app,
    String author,
    String license,
    String contact,
  ) => [
    (
      'In breve',
      [
        '$app non raccoglie, non trasmette e non vende dati personali.',
        "Non serve un account e non c'è alcuna registrazione.",
        "L'app non contiene pubblicità.",
        'I diagrammi restano sul tuo dispositivo.',
      ],
    ),
    (
      'Chi è il responsabile',
      [
        "$app è realizzata dal $author. Poiché l'app non raccoglie dati personali, "
            "nessun dato dell'utente arriva allo sviluppatore.",
      ],
    ),
    (
      "Quali dati usa l'app",
      [
        "Solo i diagrammi che crei, salvati nella memoria dell'app sul dispositivo, e la scelta del tema (chiaro o scuro). Su iPhone e iPad i diagrammi sono visibili anche nell'app File, nella cartella di $app.",
        "L'app non usa nomi, email, posizione, foto, contatti, microfono, fotocamera, identificativi del dispositivo o pubblicitari.",
        'Se il backup del dispositivo è attivo (iCloud, Google o Time Machine sul Mac), il sistema operativo può includere i diagrammi nel backup, come per i documenti di ogni altra app. È un servizio del sistema, gestito dalle impostazioni del dispositivo.',
      ],
    ),
    (
      'Connessione a internet',
      [
        "L'app funziona senza connessione e non invia nulla in rete: nessun server, nessun "
            'servizio esterno.',
      ],
    ),
    (
      'Servizi di terze parti',
      [
        'Nessun sistema di analisi o statistiche, di pubblicità o di segnalazione automatica '
            "degli errori. I componenti usati per costruire l'app sono elencati in "
            '«$componentLicenses».',
      ],
    ),
    (
      'Condivisione dei file',
      [
        "Un diagramma, un'immagine, un PDF o il codice escono dall'app solo quando scegli tu «Condividi», «Esporta» o, sul computer, «$saveAs». Decidi tu a chi o dove inviarlo (AirDrop, Mail, File…) o in quale cartella salvarlo. Da quel momento valgono le regole dell'app o del servizio che hai scelto.",
        "Un file .flow ricevuto si apre con «$openFlowFile» oppure toccandolo in Mail, File o Finder: l'app legge solo quel file e ne salva una copia tra i tuoi diagrammi.",
      ],
    ),
    (
      'A scuola',
      [
        "L'app è pensata per insegnanti e studenti e non chiede dati personali. Consiglio: "
            'nei nomi dei diagrammi e nei testi non inserire dati personali (ad esempio nomi e '
            'cognomi degli studenti), soprattutto se i file vengono condivisi.',
      ],
    ),
    (
      'Cancellare i dati',
      [
        "Puoi eliminare un diagramma dall'elenco nella schermata iniziale. Disinstallando l'app da iPhone, iPad o Android, il sistema elimina tutti i diagrammi salvati al suo interno. Sul Mac, togliendo l'app dalla cartella Applicazioni i diagrammi restano nella sua cartella dati (Libreria › Containers › $app), che puoi eliminare. Restano comunque le copie che hai condiviso o esportato altrove.",
      ],
    ),
    (
      'Verificabilità',
      [
        'Il codice di $app è pubblico (source-available, licenza $license): chiunque '
            "può verificare che l'app si comporti come descritto qui.",
      ],
    ),
    (
      'Modifiche e contatti',
      [
        "Se l'informativa cambia, la nuova versione sarà in questa pagina con la data "
            'aggiornata. Per domande: $contact.',
      ],
    ),
  ];

  // ================================================================ componenti e scelta del pin
  @override
  String get componentLed => 'LED';
  @override
  String get componentButton => 'Pulsante';
  @override
  String get componentPotentiometer => 'Potenziometro';
  @override
  String get componentOther => 'Altro';
  @override
  String get whatToConnect => 'Cosa colleghi?';
  @override
  String get digitalPinsTitle => 'Pin digitali';
  @override
  String get analogPinsTitle => 'Pin analogici';
  @override
  String pinSwapNotice(String other, String otherNewPin) =>
      'Il pin è usato da $other: si scambiano, $other va al pin $otherNewPin.';
  @override
  String pinMoveNotice(String other, String newPin) =>
      'Il pin è usato da $other, che verrà spostato sul pin $newPin.';
  @override
  String pinCannotSwap(String other, String pin) =>
      'Il pin è usato da $other, che non può andare sul pin $pin: scegli un altro pin.';
  @override
  String pinCannotMove(String other) =>
      "Il pin è usato da $other e non c'è un altro pin libero adatto: scegli un altro pin.";
  @override
  String pinMoved(String name, String pin) => '$name spostato sul pin $pin';

  // ================================================================ esercizi

  @override
  String get exercise => 'Esercizio';
  @override
  String get exercises => 'Esercizi';
  @override
  String get exerciseCreate => 'Crea esercizio';
  @override
  String get exerciseEdit => 'Modifica esercizio';
  @override
  String get exerciseText => 'Consegna';
  @override
  String get exerciseTextHint =>
      'Che cosa deve fare il diagramma? Indica anche che cosa deve scrivere.';
  @override
  String get testCases => 'Casi di prova';
  @override
  String testCase(int n) => 'Caso $n';
  @override
  String get hiddenCase => 'Caso nascosto';
  @override
  String get caseInputs => 'Dati in ingresso';
  @override
  String get caseInputsHint => "Un valore per riga, nell'ordine in cui vengono letti";
  @override
  String get caseExpected => 'Output atteso';
  @override
  String get caseExpectedHint => 'Una riga per ogni valore scritto';
  @override
  String get caseActual => 'Output ottenuto';
  @override
  String get caseHidden => 'Nascosto agli studenti';
  @override
  String get addCase => 'Aggiungi caso';
  @override
  String get removeCase => 'Elimina caso';
  @override
  String get fillFromDiagram => 'Calcola dal diagramma';
  @override
  String get fillFromDiagramHelp =>
      "Esegue il diagramma con i dati in ingresso di ogni caso e ne copia l'output come output atteso.";
  @override
  String filledCases(int n) =>
      n == 1 ? 'Output calcolato per 1 caso' : 'Output calcolato per $n casi';
  @override
  String fillProblem(int n, String problem) => 'Caso $n: $problem';
  @override
  String get removeExercise => 'Togli esercizio';
  @override
  String get removeExerciseBody =>
      'La consegna e i casi di prova verranno tolti dal diagramma. Il diagramma resta.';
  @override
  String get remove => 'Togli';
  @override
  String get shareExercise => 'Condividi come esercizio';
  @override
  String get shareExerciseHelp =>
      'Senza la tua soluzione: lo studente parte da un diagramma vuoto e non può modificare consegna e casi.';
  @override
  String get verify => 'Verifica';
  @override
  String get verifyFixFirst => 'Prima correggi gli errori segnalati nel diagramma.';
  @override
  String get verifyAllPassed => 'Tutti i casi superati!';
  @override
  String verifyPassed(int ok, int total) =>
      ok == 1 ? 'Superato 1 caso su $total' : 'Superati $ok casi su $total';
  @override
  String get verifyResults => 'Risultato della verifica';
  @override
  String get casePassed => 'superato';
  @override
  String get caseFailed => 'non superato';
  @override
  String get outcomeWrongOutput => "L'output non corrisponde a quello atteso.";
  @override
  String get outcomeMissingInput => 'Il diagramma chiede più dati di quelli del caso.';
  @override
  String get outcomeUnusedInput => 'Il diagramma termina senza leggere tutti i dati del caso.';
  @override
  String outcomeBadInput(String message) => 'Un dato non va bene: $message';
  @override
  String outcomeError(String message) => 'Errore: $message';
  @override
  String get noOutput => '(nessun output)';
  @override
  String get noInputs => '(nessuno)';
  @override
  String get exerciseLocked =>
      'Esercizio ricevuto: consegna e casi di prova non si possono modificare.';
  @override
  String hiddenCasesCount(int n) => n == 1 ? 'più 1 caso nascosto' : 'più $n casi nascosti';
  @override
  String get noCases => 'Nessun caso di prova: aggiungine almeno uno per poter verificare.';
  @override
  String get showTask => 'Leggi la consegna';

  // ================================================================ simulazione Arduino

  @override
  String get whatPin => 'il pin';
  @override
  String get whatValue => 'il valore';
  @override
  String runTooManyStepsLoop(int n) =>
      "superati $n passi in un solo giro di loop(): forse c'è un ciclo infinito (la condizione non diventa mai falsa?)";
  @override
  String runDelayNegative(int ms) => 'delay non può essere negativo, invece vale $ms';
  @override
  String runPwmRange(int value, int max) =>
      'analogWrite accetta valori da 0 a $max, invece vale $value';
  @override
  String runPinNotOnBoard(int pin, String board) => 'il pin $pin non esiste sulla scheda $board';
  @override
  String runAnalogReadPin(String pin) =>
      'analogRead funziona solo sugli ingressi analogici (A0…), non sul pin $pin';
  @override
  String get circuit => 'Circuito';
  @override
  String simLoop(int n) => 'giro $n di loop()';
  @override
  String get toLoopEnd => 'Fino alla fine di questo giro di loop()';
  @override
  String get ledOn => 'acceso';
  @override
  String get ledOff => 'spento';
  @override
  String get pressed => 'premuto';
  @override
  String get released => 'rilasciato';
  @override
  String get tapToPress => 'Tocca per premere o rilasciare';
  @override
  String noSimPins(String pinsAndBoard) =>
      'Nessun pin configurato: aggiungili in «$pinsAndBoard» per vederli qui.';
  @override
  String get simNote =>
      'Simulazione: il tempo di ogni blocco è approssimato; i delay durano davvero in esecuzione automatica.';
}
