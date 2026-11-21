// English texts (school terminology: GCSE / AP-style flowcharts and pseudocode).
import '../expr/types.dart';
import 'tr.dart';

class TrEn extends Tr {
  const TrEn();

  @override
  AppLanguage get language => AppLanguage.en;

  String _t(VarType t) => switch (t) {
    VarType.integer => typeInteger,
    VarType.real => typeReal,
    VarType.string => typeString,
    VarType.boolean => typeBoolean,
  };

  // ================================================================ types and values
  @override
  String get typeInteger => 'integer';
  @override
  String get typeReal => 'real';
  @override
  String get typeString => 'string';
  @override
  String get typeBoolean => 'boolean';
  @override
  String aType(VarType t) => switch (t) {
    VarType.integer => 'an integer',
    _ => 'a ${_t(t)}',
  };
  @override
  String get trueWord => 'true';
  @override
  String get falseWord => 'false';
  @override
  String get realUndefined => 'undefined';
  @override
  String get realInfinite => 'infinity';

  // ================================================================ lexer
  @override
  String get lexIncompleteNumber => 'incomplete number: digits missing after the decimal point';
  @override
  String get lexNameStartsWithDigit => 'a name cannot start with a digit';
  @override
  String get lexNumberTooLarge => 'number too large';
  @override
  String lexAccentedLetter(String ch) =>
      "letter '$ch' is not allowed in names: use letters without accents";
  @override
  String get lexUnclosedString => 'unclosed string: missing closing quote "';
  @override
  String get lexUseOr => "for 'or' use 'or' (or '||')";
  @override
  String get lexUseDoubleEquals => "to compare use '=='; a single '=' is not allowed here";
  @override
  String get lexUseNotEquals => "for 'not equal to' use '!='";
  @override
  String get lexUseDoubleQuotes => 'strings go in double quotes: "text"';
  @override
  String lexInvalidChar(String ch) => "invalid character: '$ch'";
  @override
  String get idEmpty => 'the name is empty';
  @override
  String get idHasSpaces => 'a name cannot contain spaces (use _ instead of a space)';
  @override
  String get idInvalidChars => 'use only letters without accents, digits and _';
  @override
  String idIsFunction(String name) => "'$name' is the name of a function";
  @override
  String idReserved(String name) => "'$name' is a reserved word";

  // ================================================================ parser
  @override
  String get parseEmpty => 'empty expression';
  @override
  String get parseChainedComparison =>
      'chained comparisons are not allowed: write, for example, a < b and b < c';
  @override
  String get parseMissingCloseParen => "missing ')' to close this '('";
  @override
  String get parseIncomplete => 'incomplete expression: a value is missing at the end';
  @override
  String get parseMissingValueBeforeClose => "missing a value before ')'";
  @override
  String get parseUnexpectedComma => 'unexpected comma: use a point for decimals (3.14)';
  @override
  String parseMissingValueBefore(String token) => "missing a value before '$token'";
  @override
  String parseUnknownFunction(String name) => "unknown function '$name'";
  @override
  String parseArity(String fn, int arity, int given) =>
      '$fn ${switch (arity) {
        0 => 'takes empty brackets: $fn()',
        1 => 'takes 1 argument',
        _ => 'takes $arity arguments',
      }}, but you wrote $given';
  @override
  String get parseUnmatchedClose => "')' without a matching '('";
  @override
  String parseMissingOperatorBefore(String token) => "missing an operator before '$token'";
  @override
  String parseUnexpected(String token) => "unexpected '$token' here";

  // ================================================================ type checking
  @override
  String typeUndeclared(String name) => "variable '$name' has not been declared";
  @override
  String typeUndeclaredLowercase(String name, String lower) =>
      "variable '$name' has not been declared: write '$lower' in lower case";
  @override
  String typeNegNumber(VarType t) => "the '-' sign applies to a number, not to ${aType(t)}";
  @override
  String typeNotBoolean(VarType t) =>
      "'not' applies to a boolean, not to ${aType(t)}; if needed, use brackets: not (a > b)";
  @override
  String typePair(VarType a, VarType b) => '${_t(a)} and ${_t(b)}';
  @override
  String typeArith(String sym, VarType a, VarType b) =>
      "'$sym' works between numbers, not between ${typePair(a, b)}";
  @override
  String typePlusText(VarType a, VarType b) =>
      "'+' does not join ${typePair(a, b)}: to build text use '&'";
  @override
  String typeModInts(VarType a, VarType b) =>
      "'%' (remainder) works between integers, not between ${typePair(a, b)}";
  @override
  String typeCannotCompare(VarType a, VarType b) => 'cannot compare ${typePair(a, b)}';
  @override
  String typeCompareNumStr(String sym, VarType a, VarType b) =>
      "'$sym' works between numbers or between strings, not between ${typePair(a, b)}";
  @override
  String typeLogical(String sym, VarType a, VarType b) =>
      "'$sym' works between conditions (booleans), not between ${typePair(a, b)}";
  @override
  String typeArduinoOnly(String fn) => "'$fn' can only be used in Arduino flowcharts";
  @override
  String fnNeedsNumber(String fn, VarType t) => '$fn needs a number, not ${aType(t)}';
  @override
  String fnNeedsString(String fn, VarType t) => '$fn needs a string, not ${aType(t)}';
  @override
  String fnNeedsInteger(String fn, VarType t) => '$fn needs an integer, not ${aType(t)}';
  @override
  String fnNeedsPin(String fn, VarType t) => '$fn needs a pin (integer), not ${aType(t)}';
  @override
  String functionSignature(String fn) => switch (fn) {
    'abs' || 'sqrt' || 'int' || 'round' => '$fn(number)',
    'len' => 'len(string)',
    'random' => 'random(n)',
    'digitalRead' || 'analogRead' => '$fn(pin)',
    _ => '$fn()',
  };
  @override
  String functionDescription(String fn) => switch (fn) {
    'abs' => 'absolute value',
    'sqrt' => 'square root (real result)',
    'int' => 'integer part, drops the decimals: int(3.9) = 3, int(-3.9) = -3',
    'round' => 'rounds to the nearest integer (0.5 rounds away from zero)',
    'len' => 'number of characters in the string',
    'random' => 'random integer from 0 to n-1',
    'digitalRead' => 'reads a digital input: HIGH (1) or LOW (0)',
    'analogRead' => 'reads an analogue input: 0 to 1023',
    'millis' => 'milliseconds since power-on',
    _ => fn,
  };

  // ================================================================ validation
  @override
  String get valChooseVariable => 'choose a variable';
  @override
  String valConstant(String name) => "'$name' is a constant: its value cannot change";
  @override
  String valUndeclared(String name) => "variable '$name' has not been declared";
  @override
  String valConditionBoolean(VarType t) =>
      'the condition must be true or false (boolean), but it is ${aType(t)}';
  @override
  String valNameIsPin(String name) => "'$name' is already the name of a pin or a constant";
  @override
  String valAlreadyDeclared(String name) => "variable '$name' is already declared";
  @override
  String valCounterInteger(String name) => "the counter '$name' must be an integer variable";
  @override
  String get whatFrom => 'the start value';
  @override
  String get whatTo => 'the end value';
  @override
  String get whatStep => 'the step';
  @override
  String valMustBeInteger(String what, VarType t) =>
      '$what must be an integer, but it is ${aType(t)}';
  @override
  String get valStepZero => 'the step cannot be 0';
  @override
  String valHighLow(VarType t) => 'the value must be HIGH or LOW, but it is ${aType(t)}';
  @override
  String valPwmInteger(VarType t) =>
      'the value must be an integer from 0 to 255, but it is ${aType(t)}';
  @override
  String valPwmRange(int max, int value) =>
      'the analogWrite value goes from 0 to $max, but it is $value';
  @override
  String valReadIntoInteger(String name) =>
      "'$name' must be an integer variable to store the reading";
  @override
  String valDelayInteger(VarType t) =>
      'the delay must be a whole number of milliseconds, but it is ${aType(t)}';
  @override
  String get valDelayNegative => 'the delay cannot be negative';
  @override
  String get valArduinoOnlyBlock => 'this block can only be used in Arduino flowcharts';
  @override
  String get valChoosePin => 'choose a pin';
  @override
  String valPinNotConfigured(String name) => "pin '$name' is not set up: add it in «$pinsAndBoard»";
  @override
  String valPinMustBeInt(VarType t) =>
      'the pin must be an integer or a pin name, but it is ${aType(t)}';
  @override
  String valPinNamed(String name, String pin) => "'$name' (pin $pin)";
  @override
  String valPinNumber(String pin) => 'pin $pin';
  @override
  String valPinNotOnBoard(String pin, String board) => 'pin $pin does not exist on the $board';
  @override
  String valPinNotConfiguredLabel(String label) =>
      '$label is not set up: add it in «$pinsAndBoard» with a name (e.g. LED)';
  @override
  String valPinNotOutput(String label, String mode) =>
      '$label is set up as $mode: to write to it, it must be an output';
  @override
  String valNoPwm(String label, String board, String pins) =>
      '$label does not support analogWrite (PWM): on the $board use one of pins $pins';
  @override
  String valPinIsOutput(String label) => '$label is an output: to read it, set it up as an input';
  @override
  String valAnalogReadPins(String pins) => 'analogRead only works on pins $pins';
  @override
  String valAnalogAlias(String label, String digital) =>
      '$label works only with analogRead(): as a digital pin it is pin $digital.';
  @override
  String valAnalogOnly(String label) =>
      '$label is an analog-only input: read it with analogRead().';
  @override
  String valAnalogReadMode(String label) =>
      '$label must be set up as an analogue input to use analogRead';
  @override
  String valPinNameError(String name, String error) => "pin name '$name': $error";
  @override
  String valPinNameTwice(String name) => "the name '$name' is used for two pins";
  @override
  String valPinNotExists(String name, String pin, String board) =>
      '$name: pin $pin does not exist on the $board';
  @override
  String valPinTwice(String pin) => 'pin $pin is set up twice';
  @override
  String valPinModeInvalid(String name, String pin, String mode) =>
      '$name: pin $pin cannot be $mode';
  @override
  String valSerialPins(String name, List<String> pins) =>
      '$name: pins ${pins.join(' and ')} are used for serial communication (Input/Output): '
      'choose another pin';
  @override
  String valAssignRealToInt(String target) =>
      "'$target' is an integer but the value is real: use int(...) or round(...), "
      "or declare '$target' as real";
  @override
  String valAssignType(VarType value, String target, VarType targetType) =>
      "you cannot assign ${aType(value)} to '$target', which is of type ${_t(targetType)}";

  // ================================================================ .flow files
  @override
  String get fileDamaged => 'the file is damaged or is not a DB Flow flowchart';
  @override
  String get fileNotFlow => 'the file is not a DB Flow flowchart';
  @override
  String get fileBadVersion => 'file version missing or invalid';
  @override
  String get fileTooNew =>
      'the file was created with a newer version of the app: please update DB Flow';
  @override
  String fileFieldMissing(String key) => "field '$key' missing or invalid";
  @override
  String fileFieldInvalid(String key) => "field '$key' invalid";
  @override
  String get fileBadBlock => 'invalid block';
  @override
  String fileUnknownBlock(String t) => "unknown block type: '$t'";
  @override
  String fileUnknownType(String name) => "unknown type: '$name'";
  @override
  String get untitled => 'Untitled';

  // ================================================================ execution
  @override
  String runUndeclared(String name) => "variable '$name' has not been declared";
  @override
  String runNoValue(String name) =>
      "variable '$name' has no value yet: assign it a value or input it before using it";
  @override
  String runAssignType(VarType value, String name, VarType varType) =>
      "you cannot assign ${aType(value)} to '$name', which is of type ${_t(varType)}";
  @override
  String get inputNeedInteger => 'type an integer, for example 42';
  @override
  String get inputNeedNumber => 'type a number, for example 3.5';
  @override
  String get inputNeedBoolean => 'type true or false';
  @override
  String runTypeInvalid(String what) => 'invalid type: $what';
  @override
  String get runNeedNumber => 'a number is needed';
  @override
  String get runNeedBoolean => 'a boolean is needed';
  @override
  String runOpNotApplicable(String op, VarType t) => "'$op' does not apply to ${aType(t)}";
  @override
  String get runDivZero => 'division by zero';
  @override
  String get runModInts => "'%' works between integers";
  @override
  String get runModZero => 'remainder of a division by zero';
  @override
  String runSqrtNegative(String value) => 'square root of a negative number ($value)';
  @override
  String runNotFinite(String fn) => '$fn: the value is not a finite number';
  @override
  String get runLenString => 'len needs a string';
  @override
  String get runRandomInt => 'random needs an integer';
  @override
  String runRandomPositive(int n) => 'random(n) needs n greater than 0, but n = $n';
  @override
  String runNotSimulated(String fn) => "'$fn' is not available in the simulation yet";
  @override
  String runTooManySteps(int n) =>
      'more than $n steps: the program may contain an infinite loop '
      '(does the condition never become false?)';
  @override
  String runConditionValue(String value) =>
      'the condition must be true or false, but its value is $value';
  @override
  String runMustBeInteger(String what, String value) =>
      '$what must be an integer, but its value is $value';
  @override
  String get runStepZero => 'the loop step cannot be 0';
  @override
  String get runArduinoNotSimulated =>
      'Arduino blocks cannot be simulated yet: generate the sketch';
  @override
  String runCounterInteger(String name) => "the counter '$name' must stay an integer";
  @override
  String runInvalidExpr(String text) => "invalid expression: '$text'";
  @override
  String get runInputMissing => 'missing input';
  @override
  String runFinished(int steps) => 'Program finished ($steps steps)';
  @override
  String runErrorLine(String message) => 'Error: $message';

  // ================================================================ flowchart
  @override
  String get flowStart => 'Start';
  @override
  String get flowEnd => 'End';
  @override
  String get edgeTrue => 'true';
  @override
  String get edgeFalse => 'false';
  @override
  String get flowRepeat => 'repeat';
  @override
  String labelRead(String variable) => 'Input $variable';
  @override
  String labelWrite(String text) => 'Output $text';
  @override
  String labelFor(String variable, String from, String to, String? step) =>
      '$variable from $from to $to${step == null ? '' : ', step $step'}';
  @override
  String get kindAlgorithm => 'Algorithm';
  @override
  String get kindArduino => 'Arduino';
  @override
  String get pinModeOutput => 'output';
  @override
  String get pinModeInput => 'input';
  @override
  String get pinModeInputPullup => 'input with pull-up';
  @override
  String get pinModeAnalogInput => 'analogue input';

  // ================================================================ generated code
  @override
  String get codeGenerated => 'Code generated by DB Flow';
  @override
  String codeGeneratedFor(String board) => 'Code generated by DB Flow for $board';
  @override
  String get codeConnections => 'Wiring:';
  @override
  String codeInvalidExpr(String text) => 'ERROR: invalid expression: $text';
  @override
  String codeArduinoOnly(String label) => '$label: only available on Arduino';
  @override
  String inputPrompt(String variable) => 'Enter $variable: ';
  @override
  String get codeAnswerVar => 'answer';
  @override
  String get codeConcatUnsupported => 'text concatenation: use an Output block or an assignment';
  @override
  String get codeLanguagePseudo => 'Pseudocode';
  @override
  String pAlgorithm(String name) => 'ALGORITHM $name';
  @override
  String get pBegin => 'BEGIN';
  @override
  String get pEnd => 'END';
  @override
  String pDeclare(String name, String type) => 'DECLARE $name AS ${type.toUpperCase()}';
  @override
  String pRead(String variable) => 'INPUT $variable';
  @override
  String pWrite(String text) => 'OUTPUT $text';
  @override
  String pIf(String cond) => 'IF $cond THEN';
  @override
  String get pElse => 'ELSE';
  @override
  String get pEndIf => 'END IF';
  @override
  String pWhile(String cond) => 'WHILE $cond DO';
  @override
  String get pEndWhile => 'END WHILE';
  @override
  String get pRepeat => 'REPEAT';
  @override
  String pRepeatWhile(String cond) => 'WHILE $cond';
  @override
  String pFor(String variable, String from, String to, String? step) =>
      'FOR $variable FROM $from TO $to${step == null ? '' : ' STEP $step'} DO';
  @override
  String get pEndFor => 'END FOR';
  @override
  String pSketch(String name, String board) => 'SKETCH $name ($board)';
  @override
  String pPin(String name, String pin, String mode) => 'PIN $name = $pin ($mode)';
  @override
  String get pSetup => 'SETUP';
  @override
  String get pEndSetup => 'END SETUP';
  @override
  String get pLoop => 'LOOP (forever)';
  @override
  String get pEndLoop => 'END LOOP';

  // ================================================================ interface: common
  @override
  String get cancel => 'Cancel';
  @override
  String get undo => 'Undo';
  @override
  String get redo => 'Redo';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Delete';
  @override
  String get share => 'Share';
  @override
  String get saveAs => 'Save as…';
  @override
  String get saveFlowFile => 'Save .flow file…';
  @override
  String get saveExercise => 'Save as exercise…';
  @override
  String get more => 'More';
  @override
  String get name => 'Name';
  @override
  String get create => 'Create';
  @override
  String get insert => 'Insert';
  @override
  String get save => 'Save';
  @override
  String get add => 'Add';
  @override
  String get edit => 'Edit';
  @override
  String get run => 'Run';
  @override
  String get pin => 'Pin';
  @override
  String get pinsAndBoard => 'Pins and board';
  @override
  String get code => 'Code';
  @override
  String get info => 'About';
  @override
  String get theme => 'Theme';
  @override
  String get themeSystem => 'Same as device';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';

  // ================================================================ home
  @override
  String get newDiagram => 'New flowchart';
  @override
  String get myDiagrams => 'My flowcharts';
  @override
  String get noDiagrams => 'No flowcharts';
  @override
  String get noDiagramsHint => 'Create a new one or start from an example.';
  @override
  String get damagedFile => 'Damaged file';
  @override
  String modified(String date) => 'Modified: $date';
  @override
  String get examples => 'Examples';
  @override
  String get examplesArduino => 'Arduino examples';
  @override
  String get opensCopy => 'Opens an editable copy';
  @override
  String get openFlowFile => 'Open a .flow file';
  @override
  String openFailed(String message) => 'Could not open: $message';
  @override
  String importFailed(String message) => 'Could not open the file: $message';
  @override
  String get importNotFlow => 'Could not open the file: it is not a DB Flow flowchart';
  @override
  String shareFailed(String error) => 'Sharing failed: $error';
  @override
  String get deleteTitle => 'Delete the flowchart?';
  @override
  String deleteBody(String name) => '"$name" will be deleted from this device.';
  @override
  String get hintNameArduino => 'e.g. Traffic lights';
  @override
  String get hintNameAlgorithm => 'e.g. Sum of two numbers';
  @override
  String get newArduinoHint =>
      'The flowchart will have a setup() part and a loop() part. '
      'Set up the wiring with the «Pin» button.';

  // ================================================================ editor
  @override
  String saveFailed(String error) => 'Saving failed: $error';
  @override
  String get blockDeleted => 'Block deleted';
  @override
  String get blockDeletedWithContent => 'Block deleted with its contents';
  @override
  String get diagramName => 'Flowchart name';
  @override
  String fixBeforeRun(int count) => count == 1
      ? 'First fix the block in red, then you can run the program.'
      : 'First fix the $count problems marked in red.';
  @override
  String operationFailed(String error) => 'Operation failed: $error';
  @override
  String get insertBlock => 'Insert a block';
  @override
  String pinIssues(int count) =>
      count == 1 ? '$pinsAndBoard: 1 problem to fix' : '$pinsAndBoard: $count problems to fix';
  @override
  String blockIssues(int count) => count == 1
      ? '1 problem: tap the block in red to see it'
      : '$count problems: tap the blocks in red to see them';
  @override
  String get backToEdit => 'Back to editing';
  @override
  String get centerDiagram => 'Centre the flowchart';
  @override
  String get shareFlowFile => 'Share .flow file';
  @override
  String get exportPng => 'Export PNG image';
  @override
  String get exportSvg => 'Export SVG';
  @override
  String get exportPdf => 'Export PDF';
  @override
  String get duplicate => 'Duplicate';
  @override
  String get moveUp => 'Move up';
  @override
  String get moveDown => 'Move down';
  @override
  String get arduinoSketch => 'Arduino sketch';
  @override
  String get chooseSketchFolder => 'Choose where to create the sketch folder';
  @override
  String get arduinoSketchFile => 'Arduino sketch (.ino)';
  @override
  String get arduinoSketchHelp => 'Open it in the Arduino IDE to upload it to the board';
  @override
  String sketchSaved(String path) => 'Sketch saved in $path';
  @override
  String wiringLine(String name, String pin, String mode) => '$name: pin $pin, $mode';
  @override
  String get pdfWiring => 'Wiring';
  @override
  String get pdfCode => 'Code';
  @override
  String get defaultFileName => 'flowchart';
  @override
  String get blockDeclare => 'Declare variable';
  @override
  String get blockAssign => 'Assignment';
  @override
  String get blockInput => 'Input (read)';
  @override
  String get blockOutput => 'Output (write)';
  @override
  String get blockIf => 'If … then … else';
  @override
  String get blockWhile => 'While';
  @override
  String get blockDoWhile => 'Repeat … while (do-while)';
  @override
  String get blockFor => 'For';
  @override
  String get blockComment => 'Comment';
  @override
  String get blockDigitalRead => 'digitalRead (digital input)';
  @override
  String get blockAnalogRead => 'analogRead (analogue input)';
  @override
  String get blockDigitalWrite => 'digitalWrite (digital output)';
  @override
  String get blockAnalogWrite => 'analogWrite (PWM output)';
  @override
  String get blockDelay => 'delay (wait)';
  @override
  String get fieldVarToModify => 'Variable to change';
  @override
  String get fieldNewValue => 'New value';
  @override
  String get hintNewValue => 'e.g. a + 1';
  @override
  String get fieldVarToRead => 'Variable to input into';
  @override
  String get fieldWhatToWrite => 'What to output';
  @override
  String get hintWrite => 'e.g. "Result: " & r';
  @override
  String get fieldCondition => 'Condition';
  @override
  String get hintCondition => 'e.g. a > b';
  @override
  String get fieldCounter => 'Counter (integer variable)';
  @override
  String get fieldFrom => 'From';
  @override
  String get fieldTo => 'To (inclusive)';
  @override
  String get fieldStep => 'Step';
  @override
  String get hintFrom => 'e.g. 1';
  @override
  String get hintTo => 'e.g. n';
  @override
  String get fieldCommentText => 'Comment text';
  @override
  String get fieldValue => 'Value';
  @override
  String get hintHighLow => 'HIGH or LOW';
  @override
  String get fieldPwmValue => 'Value (0–255)';
  @override
  String get hintPwm => 'e.g. 128';
  @override
  String get fieldDelayMs => 'Delay in milliseconds';
  @override
  String get hintDelay => 'e.g. 500 (half a second)';
  @override
  String get fieldReadTarget => 'Variable that stores the reading';
  @override
  String get readsDigital => 'Reads HIGH (1) or LOW (0).';
  @override
  String get readsAnalog => 'Reads a value from 0 (0 V) to 1023 (5 V).';
  @override
  String varExists(String name) => "a variable '$name' already exists";
  @override
  String get fieldVarName => 'Variable name';
  @override
  String get hintVarName => 'e.g. total';
  @override
  String get fieldType => 'Type';
  @override
  String get noIntegerVariables => "No integer variables: first add a '$blockDeclare' block.";
  @override
  String get noVariables => "No variables: first add a '$blockDeclare' block.";
  @override
  String notDeclared(String name) => '$name (not declared)';
  @override
  String get noInputPins => 'No inputs set up';
  @override
  String get noAnalogPins => 'No analogue inputs set up';
  @override
  String get noOutputPins => 'No output pins set up';
  @override
  String get addFromPins => ': add one in «$pinsAndBoard» (Pin button at the top).';
  @override
  String get noPwmTag => ' · no PWM';
  @override
  String pwmOn(String board, String pins) => 'PWM on the $board: $pins';
  @override
  String column(int column, String message) => 'Column $column: $message';

  // ================================================================ execution (panel)
  @override
  String get variables => 'Variables';
  @override
  String get console => 'Console';
  @override
  String get restart => 'Restart';
  @override
  String get pause => 'Pause';
  @override
  String get oneStep => 'One step';
  @override
  String get toEnd => 'Run to end';
  @override
  String get statusReady => 'Ready: press ▶ or ⏭';
  @override
  String statusPaused(int steps) => 'Paused · step $steps';
  @override
  String statusRunning(int steps) => 'Running · step $steps';
  @override
  String statusWaiting(String variable, String type) => 'Enter a value for $variable ($type)';
  @override
  String statusFinished(int steps) => 'Finished in $steps steps';
  @override
  String get statusFailed => 'Error while running';
  @override
  String condition(bool value) => 'condition: ${value ? 'true' : 'false'}';
  @override
  String get send => 'Enter';
  @override
  String get noVariablesYet => 'No variables declared so far';
  @override
  String get consoleEmpty => 'The program’s output appears here';

  // ================================================================ code
  @override
  String get codeHasErrors => 'The flowchart contains errors: the code may not work.';
  @override
  String get copy => 'Copy';
  @override
  String get codeCopied => 'Code copied';

  // ================================================================ pins and board
  @override
  String get addPin => 'Add pin';
  @override
  String get board => 'Board';
  @override
  String get serialBaud => 'Serial (baud)';
  @override
  String get toFix => 'To fix';
  @override
  String get usedNotConfigured => 'Used in the flowchart but not set up';
  @override
  String suggestionTitle(String name, String mode, String? pin) =>
      '$name → $mode${pin == null ? '' : ' (pin $pin)'}';
  @override
  String usedIn(String where) => 'in: $where';
  @override
  String get wiring => 'Wiring';
  @override
  String get tapPinHint => 'Tap a pin on the drawing to set it up.';
  @override
  String get configuredPins => 'Pins set up';
  @override
  String get noPins => 'No pins';
  @override
  String get noPinsHint =>
      'Give each connection a name (e.g. LED on pin 13): you will use the name in the blocks.';
  @override
  String get pwmTag => 'PWM';
  @override
  String get onBoardLed => 'On-board LED';
  @override
  String removePin(String name) => 'Remove $name';
  @override
  String get generatedSetup => 'Generated setup()';
  @override
  String get setupNote =>
      'pinMode and Serial.begin update automatically. The blocks you add to the '
      'setup() part of the flowchart run straight after them.';
  @override
  String get pinNameExists => 'a pin with this name already exists';
  @override
  String get variableNameExists => 'a variable with this name already exists';
  @override
  String get analogTag => 'analogue';
  @override
  String get serialTag => 'serial';
  @override
  String pinOption(String pin, List<String> tags) =>
      tags.isEmpty ? 'pin $pin' : 'pin $pin  ·  ${tags.join(', ')}';
  @override
  String get newPin => 'New pin';
  @override
  String get editPin => 'Edit pin';
  @override
  String get hintPinName => 'e.g. LED, BUTTON, SENSOR';
  @override
  String get mode => 'Mode';
  @override
  String get pwmNeeded => 'A PWM pin (~) is needed: the flowchart uses it with analogWrite.';
  @override
  String get pullupNote =>
      'With pull-up the pin reads HIGH at rest and LOW when the button '
      '(connected to GND) is pressed.';
  @override
  String get microcontroller => 'microcontroller';
  @override
  String boardSemantics(String board) => 'Drawing of the $board: tap a pin to set it up';

  // ================================================================ about
  @override
  String version(String v) => 'Version $v';
  @override
  String get aboutDescription =>
      'An editor for structured, runnable flowcharts, for teachers and students: '
      'build the algorithm from blocks, run it step by step and generate its code '
      '(pseudocode, Python, C, Arduino).';
  @override
  String madeBy(String author) => 'Made by $author.';
  @override
  String get privacy => 'Privacy';
  @override
  String get noAccount => 'No account';
  @override
  String get noAds => 'No ads';
  @override
  String get noDataCollection => 'No data collection';
  @override
  String get dataStaysOnDevice => 'Flowcharts stay on the device';
  @override
  String get privacySummary =>
      'The app contains no analytics, advertising or error reporting, and does not use the '
      'internet. Files are shared directly between people (AirDrop, Mail, Files…).';
  @override
  String get privacyPolicy => 'Privacy policy';
  @override
  String get guideBlocks => 'Quick guide: blocks';
  @override
  String get guideExpressions => 'Quick guide: expressions';
  @override
  List<(String, String)> get guideBlockItems => const [
    ('Start / End', 'Where the algorithm begins and where it ends.'),
    ('Declaration', 'Creates a variable: integer, real, string, boolean.'),
    ('Assignment', 'Works out a value and stores it in a variable: a ← b + 1.'),
    ('Input / Output', 'Keyboard and console (serial on Arduino).'),
    ('Decision', 'If, While, Repeat…while: the condition is true or false.'),
    ('For loop', 'A counter goes from one value to another, with a step.'),
    ('Arduino pins', 'digitalRead/Write, analogRead/Write: inputs and outputs.'),
    ('delay', 'Wait in milliseconds (Arduino).'),
  ];
  @override
  List<(String, String)> get guideExpressionItems => const [
    ('Numbers and text', '12   3.14   "hello"   true   false'),
    ('Arithmetic', '+  -  *  /  %   (7 / 2 = 3.5, 7 % 2 = 1)'),
    ('Comparisons', '==  !=  <  <=  >  >='),
    ('Logical', 'and  or  not   (also &&  ||  !)'),
    ('Joining text', '"Total: " & t'),
  ];
  @override
  String get availableFunctions => 'Available functions:';
  @override
  String get license => 'Licence';
  @override
  String licenseText(String license) =>
      'Public, verifiable code (source-available) under the $license licence: '
      'free to use for non-commercial purposes.';
  @override
  String get componentLicenses => 'Licences of the components used';

  // ================================================================ privacy policy
  @override
  String get privacyUpdated => 'Last updated: 21 November 2026';
  @override
  List<(String, List<String>)> privacySections(
    String app,
    String author,
    String license,
    String contact,
  ) => [
    (
      'In brief',
      [
        '$app does not collect, transmit or sell personal data.',
        'No account is needed and there is no registration.',
        'The app contains no advertising.',
        'Your flowcharts stay on your device.',
      ],
    ),
    (
      'Who is responsible',
      [
        '$app is made by $author. Since the app does not collect personal data, '
            'no user data reaches the developer.',
      ],
    ),
    (
      'What data the app uses',
      [
        'Only the flowcharts you create, saved in the app’s storage on the device, and your theme choice (light or dark). On iPhone and iPad the flowcharts are also visible in the Files app, in the $app folder.',
        'The app does not use names, email addresses, location, photos, contacts, microphone, camera, device identifiers or advertising identifiers.',
        'If device backup is turned on (iCloud, Google or Time Machine on the Mac), the operating system may include the flowcharts in the backup, as with any other app’s documents. This is a system service, managed in the device settings.',
      ],
    ),
    (
      'Internet connection',
      [
        'The app works offline and sends nothing over the network: no servers, no '
            'external services.',
      ],
    ),
    (
      'Third-party services',
      [
        'No analytics or statistics, no advertising and no automatic error reporting. '
            'The components used to build the app are listed in '
            '«$componentLicenses».',
      ],
    ),
    (
      'Sharing files',
      [
        'A flowchart, an image, a PDF or the code leaves the app only when you choose «Share», «Export» or, on a computer, «$saveAs». You decide who to send it to or where (AirDrop, Mail, Files…) or which folder to save it in. From then on, the rules of the app or service you chose apply.',
        'A .flow file you receive opens with «$openFlowFile» or by tapping it in Mail, Files or Finder: the app reads only that file and saves a copy among your flowcharts.',
      ],
    ),
    (
      'At school',
      [
        'The app is designed for teachers and students and does not ask for personal data. '
            'Tip: do not put personal data (for example students’ first names and '
            'surnames) in flowchart names or texts, especially if the files are shared.',
      ],
    ),
    (
      'Deleting data',
      [
        'You can delete a flowchart from the list on the home screen. If you uninstall the app from iPhone, iPad, Android or Windows, the system deletes all the flowcharts saved in it. On the Mac, removing the app from the Applications folder leaves the flowcharts in its data folder (Library › Containers › $app), which you can delete. Copies you have shared or exported elsewhere always remain.',
      ],
    ),
    (
      'Verifiability',
      [
        'The code of $app is public (source-available, $license licence): anyone '
            'can check that the app behaves as described here.',
      ],
    ),
    (
      'Changes and contacts',
      [
        'If this policy changes, the new version will be on this page with the updated '
            'date. For questions: $contact.',
      ],
    ),
  ];

  // ================================================================ componenti e scelta del pin
  @override
  String get componentLed => 'LED';
  @override
  String get componentButton => 'Push button';
  @override
  String get componentPotentiometer => 'Potentiometer';
  @override
  String get componentOther => 'Other';
  @override
  String get whatToConnect => 'What are you connecting?';
  @override
  String get digitalPinsTitle => 'Digital pins';
  @override
  String get analogPinsTitle => 'Analogue pins';
  @override
  String pinSwapNotice(String other, String otherNewPin) =>
      'This pin is used by $other: they will swap, $other moves to pin $otherNewPin.';
  @override
  String pinMoveNotice(String other, String newPin) =>
      'This pin is used by $other, which will move to pin $newPin.';
  @override
  String pinCannotSwap(String other, String pin) =>
      'This pin is used by $other, which cannot go on pin $pin: choose another pin.';
  @override
  String pinCannotMove(String other) =>
      'This pin is used by $other and there is no other suitable free pin: choose another pin.';
  @override
  String pinMoved(String name, String pin) => '$name moved to pin $pin';

  // ================================================================ esercizi

  @override
  String get exercise => 'Exercise';
  @override
  String get exercises => 'Exercises';
  @override
  String get exerciseCreate => 'Create exercise';
  @override
  String get exerciseEdit => 'Edit exercise';
  @override
  String get exerciseText => 'Task';
  @override
  String get exerciseTextHint =>
      'What should the flowchart do? Also say exactly what it should output.';
  @override
  String get testCases => 'Test cases';
  @override
  String testCase(int n) => 'Case $n';
  @override
  String get hiddenCase => 'Hidden case';
  @override
  String get caseInputs => 'Input values';
  @override
  String get caseInputsHint => 'One value per line, in the order they are read';
  @override
  String get caseExpected => 'Expected output';
  @override
  String get caseExpectedHint => 'One line for each value written';
  @override
  String get caseActual => 'Actual output';
  @override
  String get caseHidden => 'Hidden from students';
  @override
  String get addCase => 'Add case';
  @override
  String get removeCase => 'Delete case';
  @override
  String get fillFromDiagram => 'Compute from flowchart';
  @override
  String get fillFromDiagramHelp =>
      'Runs the flowchart with the input values of each case and copies its output as the expected output.';
  @override
  String filledCases(int n) =>
      n == 1 ? 'Output computed for 1 case' : 'Output computed for $n cases';
  @override
  String fillProblem(int n, String problem) => 'Case $n: $problem';
  @override
  String get removeExercise => 'Remove exercise';
  @override
  String get removeExerciseBody =>
      'The task and the test cases will be removed. The flowchart stays.';
  @override
  String get remove => 'Remove';
  @override
  String get shareExercise => 'Share as exercise';
  @override
  String get shareExerciseHelp =>
      'Without your solution: students start from an empty flowchart and cannot change the task or the cases.';
  @override
  String get verify => 'Check';
  @override
  String get verifyFixFirst => 'First fix the errors marked in the flowchart.';
  @override
  String get verifyAllPassed => 'All cases passed!';
  @override
  String verifyPassed(int ok, int total) => '$ok of $total ${total == 1 ? 'case' : 'cases'} passed';
  @override
  String get verifyResults => 'Check results';
  @override
  String get casePassed => 'passed';
  @override
  String get caseFailed => 'failed';
  @override
  String get outcomeWrongOutput => 'The output does not match the expected one.';
  @override
  String get outcomeMissingInput => 'The flowchart asks for more values than the case provides.';
  @override
  String get outcomeUnusedInput => 'The flowchart ends without reading all the values of the case.';
  @override
  String outcomeBadInput(String message) => 'An input value is not valid: $message';
  @override
  String outcomeError(String message) => 'Error: $message';
  @override
  String get noOutput => '(no output)';
  @override
  String get noInputs => '(none)';
  @override
  String get exerciseLocked => 'Received exercise: the task and the test cases cannot be changed.';
  @override
  String hiddenCasesCount(int n) => n == 1 ? 'plus 1 hidden case' : 'plus $n hidden cases';
  @override
  String get noCases => 'No test cases: add at least one to be able to check.';
  @override
  String get showTask => 'Read the task';

  // ================================================================ simulazione Arduino

  @override
  String get whatPin => 'the pin';
  @override
  String get whatValue => 'the value';
  @override
  String runTooManyStepsLoop(int n) =>
      'more than $n steps in a single run of loop(): there may be an infinite loop (does the condition never become false?)';
  @override
  String runDelayNegative(int ms) => 'delay cannot be negative, but its value is $ms';
  @override
  String runPwmRange(int value, int max) =>
      'analogWrite accepts values from 0 to $max, but the value is $value';
  @override
  String runPinNotOnBoard(int pin, String board) => 'pin $pin does not exist on the $board';
  @override
  String runAnalogReadPin(String pin) =>
      'analogRead works only on analog inputs (A0…), not on pin $pin';
  @override
  String get circuit => 'Circuit';
  @override
  String simLoop(int n) => 'loop() run $n';
  @override
  String get toLoopEnd => 'To the end of this run of loop()';
  @override
  String get ledOn => 'on';
  @override
  String get ledOff => 'off';
  @override
  String get pressed => 'pressed';
  @override
  String get released => 'released';
  @override
  String get tapToPress => 'Tap to press or release';
  @override
  String noSimPins(String pinsAndBoard) =>
      'No pins configured: add them in “$pinsAndBoard” to see them here.';
  @override
  String get simNote =>
      'Simulation: block timing is approximate; delays take their real time when running automatically.';
}
