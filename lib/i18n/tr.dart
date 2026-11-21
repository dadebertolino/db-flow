/// Testi dell'app in tutte le lingue. Dart puro (usato anche da parser,
/// validatore, interprete e generatori di codice).
///
/// Ogni lingua implementa [Tr]: se manca un testo, il codice non compila.
/// La lingua corrente è [tr]; la cambia [setLanguage].
library;

import '../expr/types.dart';
import 'tr_de.dart';
import 'tr_en.dart';
import 'tr_es.dart';
import 'tr_fr.dart';
import 'tr_it.dart';

enum AppLanguage {
  it('Italiano'),
  en('English'),
  fr('Français'),
  de('Deutsch'),
  es('Español');

  const AppLanguage(this.nativeName);
  final String nativeName;

  static AppLanguage? fromCode(String code) {
    for (final l in values) {
      if (l.name == code) return l;
    }
    return null;
  }
}

Tr trFor(AppLanguage l) => switch (l) {
  AppLanguage.it => const TrIt(),
  AppLanguage.en => const TrEn(),
  AppLanguage.fr => const TrFr(),
  AppLanguage.de => const TrDe(),
  AppLanguage.es => const TrEs(),
};

/// Lingua corrente. Predefinita: italiano.
Tr tr = const TrIt();

void setLanguage(AppLanguage l) => tr = trFor(l);

/// Parole per vero/falso accettate nelle espressioni, in qualsiasi lingua: un
/// file scritto in Italia si apre senza errori in Francia.
const trueWords = {'vero', 'true', 'vrai', 'wahr', 'verdadero'};
const falseWords = {'falso', 'false', 'faux', 'falsch'};

/// Risposte accettate quando il programma chiede un booleano (tutte le lingue).
const trueAnswers = {
  ...trueWords,
  'v',
  't',
  'w',
  'si',
  'sì',
  'sí',
  'yes',
  'y',
  'oui',
  'o',
  'ja',
  'j',
  '1',
};
const falseAnswers = {...falseWords, 'f', 'no', 'n', 'non', 'nein', '0'};

/// Tutti i testi. I commenti dicono dove compare ogni testo.
abstract class Tr {
  const Tr();

  AppLanguage get language;

  // ================================================================ tipi e valori

  String get typeInteger;
  String get typeReal;
  String get typeString;
  String get typeBoolean;

  /// Tipo con l'articolo indeterminativo: «un intero», «una stringa».
  String aType(VarType t);

  /// Parole per i valori booleani (mostrate e usate per i nuovi testi).
  String get trueWord;
  String get falseWord;

  /// Reale non definito (NaN) e infinito.
  String get realUndefined;
  String get realInfinite;

  // ================================================================ lexer

  String get lexIncompleteNumber;
  String get lexNameStartsWithDigit;
  String get lexNumberTooLarge;
  String lexAccentedLetter(String ch);
  String get lexUnclosedString;
  String get lexUseOr;
  String get lexUseDoubleEquals;
  String get lexUseNotEquals;
  String get lexUseDoubleQuotes;
  String lexInvalidChar(String ch);

  // nomi di variabili e pin
  String get idEmpty;
  String get idHasSpaces;
  String get idInvalidChars;
  String idIsFunction(String name);
  String idReserved(String name);

  // ================================================================ parser

  String get parseEmpty;
  String get parseChainedComparison;
  String get parseMissingCloseParen;
  String get parseIncomplete;
  String get parseMissingValueBeforeClose;
  String get parseUnexpectedComma;
  String parseMissingValueBefore(String token);
  String parseUnknownFunction(String name);

  /// Numero di argomenti sbagliato: [fn] ne vuole [arity], ne sono stati scritti [given].
  String parseArity(String fn, int arity, int given);
  String get parseUnmatchedClose;
  String parseMissingOperatorBefore(String token);
  String parseUnexpected(String token);

  // ================================================================ controllo dei tipi

  String typeUndeclared(String name);

  /// Variabile non dichiarata che è una parola chiave in maiuscolo (AND, VERO…).
  String typeUndeclaredLowercase(String name, String lower);
  String typeNegNumber(VarType t);
  String typeNotBoolean(VarType t);

  /// «intero e stringa» (due tipi in un messaggio).
  String typePair(VarType a, VarType b);
  String typeArith(String sym, VarType a, VarType b);
  String typePlusText(VarType a, VarType b);
  String typeModInts(VarType a, VarType b);
  String typeCannotCompare(VarType a, VarType b);
  String typeCompareNumStr(String sym, VarType a, VarType b);
  String typeLogical(String sym, VarType a, VarType b);
  String typeArduinoOnly(String fn);

  // funzioni predefinite
  String fnNeedsNumber(String fn, VarType t);
  String fnNeedsString(String fn, VarType t);
  String fnNeedsInteger(String fn, VarType t);
  String fnNeedsPin(String fn, VarType t);

  /// Firma mostrata nella guida, es. `sqrt(numero)`.
  String functionSignature(String fn);

  /// Descrizione breve della funzione.
  String functionDescription(String fn);

  // ================================================================ validazione

  String get valChooseVariable;
  String valConstant(String name);
  String valUndeclared(String name);
  String valConditionBoolean(VarType t);
  String valNameIsPin(String name);
  String valAlreadyDeclared(String name);
  String valCounterInteger(String name);

  /// Parti del ciclo Per, usate in [valMustBeInteger] e [runMustBeInteger].
  String get whatFrom;
  String get whatTo;
  String get whatStep;
  String valMustBeInteger(String what, VarType t);
  String get valStepZero;
  String valHighLow(VarType t);
  String valPwmInteger(VarType t);
  String valPwmRange(int max, int value);
  String valReadIntoInteger(String name);
  String valDelayInteger(VarType t);
  String get valDelayNegative;
  String get valArduinoOnlyBlock;
  String get valChoosePin;
  String valPinNotConfigured(String name);
  String valPinMustBeInt(VarType t);

  /// Come chiamare un pin nei messaggi: «'LED' (pin 13)» o «il pin 13».
  String valPinNamed(String name, String pin);
  String valPinNumber(String pin);
  String valPinNotOnBoard(String pin, String board);
  String valPinNotConfiguredLabel(String label);
  String valPinNotOutput(String label, String mode);
  String valNoPwm(String label, String board, String pins);
  String valPinIsOutput(String label);
  String valAnalogReadPins(String pins);

  /// Pin solo analogico (A6/A7 di Nano e Pro Mini) usato con digitalRead/Write.
  String valAnalogOnly(String label);

  /// Ingresso analogico che è anche un pin digitale con un altro nome (Micro: A6 = 4).
  String valAnalogAlias(String label, String digital);
  String valAnalogReadMode(String label);
  String valPinNameError(String name, String error);
  String valPinNameTwice(String name);
  String valPinNotExists(String name, String pin, String board);
  String valPinTwice(String pin);
  String valPinModeInvalid(String name, String pin, String mode);
  String valSerialPins(String name, List<String> pins);
  String valAssignRealToInt(String target);
  String valAssignType(VarType value, String target, VarType targetType);

  // ================================================================ file .flow

  String get fileDamaged;
  String get fileNotFlow;
  String get fileBadVersion;
  String get fileTooNew;
  String fileFieldMissing(String key);
  String fileFieldInvalid(String key);
  String get fileBadBlock;
  String fileUnknownBlock(String t);
  String fileUnknownType(String name);
  String get untitled;

  // ================================================================ esecuzione

  String runUndeclared(String name);
  String runNoValue(String name);
  String runAssignType(VarType value, String name, VarType varType);
  String get inputNeedInteger;
  String get inputNeedNumber;
  String get inputNeedBoolean;
  String runTypeInvalid(String what);
  String get runNeedNumber;
  String get runNeedBoolean;
  String runOpNotApplicable(String op, VarType t);
  String get runDivZero;
  String get runModInts;
  String get runModZero;
  String runSqrtNegative(String value);
  String runNotFinite(String fn);
  String get runLenString;
  String get runRandomInt;
  String runRandomPositive(int n);
  String runNotSimulated(String fn);
  String runTooManySteps(int n);
  String runConditionValue(String value);
  String runMustBeInteger(String what, String value);
  String get runStepZero;
  String get runArduinoNotSimulated;
  String runCounterInteger(String name);
  String runInvalidExpr(String text);
  String get runInputMissing;
  String runFinished(int steps);
  String runErrorLine(String message);

  // ================================================================ diagramma

  String get flowStart;
  String get flowEnd;
  String get edgeTrue;
  String get edgeFalse;

  /// Etichetta della freccia di ritorno del loop() Arduino.
  String get flowRepeat;
  String labelRead(String variable);
  String labelWrite(String text);

  /// Testo del blocco Per; [step] è `null` quando vale 1.
  String labelFor(String variable, String from, String to, String? step);

  // tipi di diagramma
  String get kindAlgorithm;
  String get kindArduino;

  // modi dei pin
  String get pinModeOutput;
  String get pinModeInput;
  String get pinModeInputPullup;
  String get pinModeAnalogInput;

  // ================================================================ codice generato

  String get codeGenerated;
  String codeGeneratedFor(String board);
  String get codeConnections;
  String codeInvalidExpr(String text);
  String codeArduinoOnly(String label);

  /// Prompt prima di ogni lettura, es. «Inserisci n: ».
  String inputPrompt(String variable);

  /// Nome della variabile d'appoggio per leggere un booleano nel codice C/Arduino.
  String get codeAnswerVar;
  String get codeConcatUnsupported;
  String get codeLanguagePseudo;

  // pseudocodice (parole chiave secondo l'uso scolastico del paese)
  String pAlgorithm(String name);
  String get pBegin;
  String get pEnd;
  String pDeclare(String name, String type);
  String pRead(String variable);
  String pWrite(String text);
  String pIf(String cond);
  String get pElse;
  String get pEndIf;
  String pWhile(String cond);
  String get pEndWhile;
  String get pRepeat;
  String pRepeatWhile(String cond);
  String pFor(String variable, String from, String to, String? step);
  String get pEndFor;
  String pSketch(String name, String board);
  String pPin(String name, String pin, String mode);
  String get pSetup;
  String get pEndSetup;
  String get pLoop;
  String get pEndLoop;

  // ================================================================ interfaccia: comuni

  String get cancel;
  String get undo;
  String get redo;
  String get ok;
  String get delete;
  String get share;

  /// Su computer, al posto di "Condividi".
  String get saveAs;
  String get saveFlowFile;
  String get saveExercise;
  String get more;
  String get name;
  String get create;
  String get insert;
  String get save;
  String get add;
  String get edit;
  String get run;
  String get pin;
  String get pinsAndBoard;
  String get code;
  String get info;
  String get theme;
  String get themeSystem;
  String get themeLight;
  String get themeDark;

  // ================================================================ home

  String get newDiagram;
  String get myDiagrams;
  String get noDiagrams;
  String get noDiagramsHint;
  String get damagedFile;
  String modified(String date);
  String get examples;
  String get examplesArduino;
  String get opensCopy;
  String get openFlowFile;
  String openFailed(String message);
  String importFailed(String message);
  String get importNotFlow;
  String shareFailed(String error);
  String get deleteTitle;
  String deleteBody(String name);
  String get hintNameArduino;
  String get hintNameAlgorithm;
  String get newArduinoHint;

  // ================================================================ editor

  String saveFailed(String error);
  String get blockDeleted;
  String get blockDeletedWithContent;
  String get diagramName;
  String fixBeforeRun(int count);
  String operationFailed(String error);
  String get insertBlock;
  String pinIssues(int count);
  String blockIssues(int count);
  String get backToEdit;
  String get centerDiagram;
  String get shareFlowFile;
  String get exportPng;
  String get exportSvg;
  String get exportPdf;
  String get duplicate;
  String get moveUp;
  String get moveDown;
  String get arduinoSketch;
  String get chooseSketchFolder;
  String get arduinoSketchFile;
  String get arduinoSketchHelp;
  String sketchSaved(String path);
  String wiringLine(String name, String pin, String mode);
  String get pdfWiring;
  String get pdfCode;
  String get defaultFileName;

  // titoli dei blocchi (menu di inserimento e dialog)
  String get blockDeclare;
  String get blockAssign;
  String get blockInput;
  String get blockOutput;
  String get blockIf;
  String get blockWhile;
  String get blockDoWhile;
  String get blockFor;
  String get blockComment;
  String get blockDigitalRead;
  String get blockAnalogRead;
  String get blockDigitalWrite;
  String get blockAnalogWrite;
  String get blockDelay;

  // campi dei dialog
  String get fieldVarToModify;
  String get fieldNewValue;
  String get hintNewValue;
  String get fieldVarToRead;
  String get fieldWhatToWrite;

  /// Esempio per «Scrivi», in sintassi valida: es. `"Risultato: " & r`.
  String get hintWrite;
  String get fieldCondition;
  String get hintCondition;
  String get fieldCounter;
  String get fieldFrom;
  String get fieldTo;
  String get fieldStep;
  String get hintFrom;
  String get hintTo;
  String get fieldCommentText;
  String get fieldValue;
  String get hintHighLow;
  String get fieldPwmValue;
  String get hintPwm;
  String get fieldDelayMs;
  String get hintDelay;
  String get fieldReadTarget;
  String get readsDigital;
  String get readsAnalog;
  String varExists(String name);
  String get fieldVarName;
  String get hintVarName;
  String get fieldType;
  String get noIntegerVariables;
  String get noVariables;
  String notDeclared(String name);
  String get noInputPins;
  String get noAnalogPins;
  String get noOutputPins;
  String get addFromPins;
  String get noPwmTag;
  String pwmOn(String board, String pins);
  String column(int column, String message);

  // ================================================================ esecuzione (pannello)

  String get variables;
  String get console;
  String get restart;
  String get pause;
  String get oneStep;
  String get toEnd;
  String get statusReady;
  String statusPaused(int steps);
  String statusRunning(int steps);
  String statusWaiting(String variable, String type);
  String statusFinished(int steps);
  String get statusFailed;
  String condition(bool value);
  String get send;
  String get noVariablesYet;
  String get consoleEmpty;

  // ================================================================ codice

  String get codeHasErrors;
  String get copy;
  String get codeCopied;

  // ================================================================ pin e scheda

  String get addPin;
  String get board;
  String get serialBaud;
  String get toFix;
  String get usedNotConfigured;
  String suggestionTitle(String name, String mode, String? pin);
  String usedIn(String where);
  String get wiring;
  String get tapPinHint;
  String get configuredPins;
  String get noPins;
  String get noPinsHint;
  String get pwmTag;
  String get onBoardLed;
  String removePin(String name);
  String get generatedSetup;
  String get setupNote;
  String get pinNameExists;
  String get variableNameExists;
  String get analogTag;
  String get serialTag;
  String pinOption(String pin, List<String> tags);
  String get newPin;
  String get editPin;
  String get hintPinName;
  String get mode;
  String get pullupNote;

  /// Nota nella scelta del pin quando è usato con analogWrite.
  String get pwmNeeded;
  String get microcontroller;
  String boardSemantics(String board);

  // ================================================================ componenti e scelta del pin

  String get componentLed;
  String get componentButton;
  String get componentPotentiometer;
  String get componentOther;
  String get whatToConnect;
  String get digitalPinsTitle;
  String get analogPinsTitle;

  /// Pin scelto già occupato da [other]: i due si scambiano, [other] va su [otherNewPin].
  String pinSwapNotice(String other, String otherNewPin);

  /// Pin nuovo su un pin occupato: [other] verrà spostato su [newPin].
  String pinMoveNotice(String other, String newPin);

  /// Scambio impossibile: [other] non può andare su [pin].
  String pinCannotSwap(String other, String pin);

  /// Spostamento impossibile: per [other] non c'è un altro pin libero adatto.
  String pinCannotMove(String other);

  /// Avviso dopo il salvataggio: [name] è stato spostato su [pin].
  String pinMoved(String name, String pin);

  // ================================================================ informazioni

  String version(String v);
  String get aboutDescription;
  String madeBy(String author);
  String get privacy;
  String get noAccount;
  String get noAds;
  String get noDataCollection;
  String get dataStaysOnDevice;
  String get privacySummary;
  String get privacyPolicy;
  String get guideBlocks;
  String get guideExpressions;

  /// Voci della guida ai blocchi: titolo e spiegazione, nell'ordine
  /// inizio/fine, dichiarazione, assegnazione, I/O, decisione, per, pin, delay.
  List<(String, String)> get guideBlockItems;

  /// Righe della guida alle espressioni: (argomento, esempio).
  List<(String, String)> get guideExpressionItems;
  String get availableFunctions;
  String get license;
  String licenseText(String license);
  String get componentLicenses;

  // ================================================================ esercizi

  String get exercise;
  String get exercises;
  String get exerciseCreate;
  String get exerciseEdit;
  String get exerciseText;
  String get exerciseTextHint;
  String get testCases;
  String testCase(int n);
  String get hiddenCase;
  String get caseInputs;
  String get caseInputsHint;
  String get caseExpected;
  String get caseExpectedHint;
  String get caseActual;
  String get caseHidden;
  String get addCase;
  String get removeCase;
  String get fillFromDiagram;
  String get fillFromDiagramHelp;
  String filledCases(int n);
  String fillProblem(int n, String problem);
  String get removeExercise;
  String get removeExerciseBody;
  String get remove;
  String get shareExercise;
  String get shareExerciseHelp;
  String get verify;
  String get verifyFixFirst;
  String get verifyAllPassed;
  String verifyPassed(int ok, int total);
  String get verifyResults;
  String get casePassed;
  String get caseFailed;
  String get outcomeWrongOutput;
  String get outcomeMissingInput;
  String get outcomeUnusedInput;
  String outcomeBadInput(String message);
  String outcomeError(String message);
  String get noOutput;
  String get noInputs;
  String get exerciseLocked;
  String hiddenCasesCount(int n);
  String get noCases;
  String get showTask;

  // ================================================================ simulazione Arduino

  String get whatPin;
  String get whatValue;
  String runTooManyStepsLoop(int n);
  String runDelayNegative(int ms);
  String runPwmRange(int value, int max);
  String runPinNotOnBoard(int pin, String board);
  String runAnalogReadPin(String pin);
  String get circuit;
  String simLoop(int n);
  String get toLoopEnd;
  String get ledOn;
  String get ledOff;
  String get pressed;
  String get released;
  String get tapToPress;
  String noSimPins(String pinsAndBoard);
  String get simNote;

  // ================================================================ informativa privacy

  /// «Ultimo aggiornamento: 14 novembre 2026» (data scritta come si usa nella lingua).
  String get privacyUpdated;

  /// Sezioni dell'informativa: titolo e paragrafi. Ogni frase deve restare vera.
  List<(String, List<String>)> privacySections(
    String app,
    String author,
    String license,
    String contact,
  );
}
