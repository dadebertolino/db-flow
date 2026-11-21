// Textos en español (terminología escolar de los diagramas de flujo y del pseudocódigo
// estilo PSeInt).
import '../expr/types.dart';
import 'tr.dart';

class TrEs extends Tr {
  const TrEs();

  @override
  AppLanguage get language => AppLanguage.es;

  String _t(VarType t) => switch (t) {
    VarType.integer => typeInteger,
    VarType.real => typeReal,
    VarType.string => typeString,
    VarType.boolean => typeBoolean,
  };

  // ================================================================ tipi e valori
  @override
  String get typeInteger => 'entero';
  @override
  String get typeReal => 'real';
  @override
  String get typeString => 'cadena';
  @override
  String get typeBoolean => 'lógico';
  @override
  String aType(VarType t) => switch (t) {
    VarType.string => 'una cadena',
    _ => 'un ${_t(t)}',
  };
  @override
  String get trueWord => 'verdadero';
  @override
  String get falseWord => 'falso';
  @override
  String get realUndefined => 'indefinido';
  @override
  String get realInfinite => 'infinito';

  // ================================================================ lexer
  @override
  String get lexIncompleteNumber => 'número incompleto: falta la parte decimal después del punto';
  @override
  String get lexNameStartsWithDigit => 'un nombre no puede empezar con un dígito';
  @override
  String get lexNumberTooLarge => 'número demasiado grande';
  @override
  String lexAccentedLetter(String ch) =>
      "la letra '$ch' no se permite en los nombres: usa letras sin tilde";
  @override
  String get lexUnclosedString => 'cadena sin cerrar: falta la comilla "';
  @override
  String get lexUseOr => "para 'o' usa 'or' (o '||')";
  @override
  String get lexUseDoubleEquals => "para comparar usa '=='; un solo '=' no se permite aquí";
  @override
  String get lexUseNotEquals => "para 'distinto de' usa '!='";
  @override
  String get lexUseDoubleQuotes => 'las cadenas van entre comillas dobles: "texto"';
  @override
  String lexInvalidChar(String ch) => "carácter no válido: '$ch'";
  @override
  String get idEmpty => 'el nombre está vacío';
  @override
  String get idHasSpaces => 'un nombre no puede contener espacios (usa _ en lugar del espacio)';
  @override
  String get idInvalidChars => 'usa solo letras sin tilde ni ñ, dígitos y _';
  @override
  String idIsFunction(String name) => "'$name' es el nombre de una función";
  @override
  String idReserved(String name) => "'$name' es una palabra reservada";

  // ================================================================ parser
  @override
  String get parseEmpty => 'expresión vacía';
  @override
  String get parseChainedComparison =>
      'no se permiten comparaciones encadenadas: escribe por ejemplo a < b and b < c';
  @override
  String get parseMissingCloseParen => "falta el paréntesis ')' que cierra este '('";
  @override
  String get parseIncomplete => 'expresión incompleta: falta un valor al final';
  @override
  String get parseMissingValueBeforeClose => "falta un valor antes de ')'";
  @override
  String get parseUnexpectedComma => 'coma inesperada: para los decimales usa el punto (3.14)';
  @override
  String parseMissingValueBefore(String token) => "falta un valor antes de '$token'";
  @override
  String parseUnknownFunction(String name) => "función '$name' desconocida";
  @override
  String parseArity(String fn, int arity, int given) =>
      '$fn necesita ${switch (arity) {
        0 => 'los paréntesis vacíos: $fn()',
        1 => '1 argumento',
        _ => '$arity argumentos',
      }}, pero escribiste $given';
  @override
  String get parseUnmatchedClose => "paréntesis ')' sin su '(' correspondiente";
  @override
  String parseMissingOperatorBefore(String token) => "falta un operador antes de '$token'";
  @override
  String parseUnexpected(String token) => "'$token' inesperado aquí";

  // ================================================================ controllo dei tipi
  @override
  String typeUndeclared(String name) => "variable '$name' no definida";
  @override
  String typeUndeclaredLowercase(String name, String lower) =>
      "variable '$name' no definida: escribe '$lower' en minúsculas";
  @override
  String typeNegNumber(VarType t) => "el signo '-' se aplica a un número, no a ${aType(t)}";
  @override
  String typeNotBoolean(VarType t) =>
      "'not' se aplica a un valor lógico, no a ${aType(t)}; si hace falta, usa paréntesis: "
      'not (a > b)';
  @override
  String typePair(VarType a, VarType b) => '${_t(a)} y ${_t(b)}';
  @override
  String typeArith(String sym, VarType a, VarType b) =>
      "'$sym' se usa entre números, no entre ${typePair(a, b)}";
  @override
  String typePlusText(VarType a, VarType b) =>
      "'+' no une ${typePair(a, b)}: para componer un texto usa '&'";
  @override
  String typeModInts(VarType a, VarType b) =>
      "'%' (resto) se usa entre enteros, no entre ${typePair(a, b)}";
  @override
  String typeCannotCompare(VarType a, VarType b) => 'no se pueden comparar ${typePair(a, b)}';
  @override
  String typeCompareNumStr(String sym, VarType a, VarType b) =>
      "'$sym' se usa entre números o entre cadenas, no entre ${typePair(a, b)}";
  @override
  String typeLogical(String sym, VarType a, VarType b) =>
      "'$sym' se usa entre condiciones (valores lógicos), no entre ${typePair(a, b)}";
  @override
  String typeArduinoOnly(String fn) => "'$fn' solo se puede usar en los diagramas Arduino";
  @override
  String fnNeedsNumber(String fn, VarType t) => '$fn requiere un número, no ${aType(t)}';
  @override
  String fnNeedsString(String fn, VarType t) => '$fn requiere una cadena, no ${aType(t)}';
  @override
  String fnNeedsInteger(String fn, VarType t) => '$fn requiere un entero, no ${aType(t)}';
  @override
  String fnNeedsPin(String fn, VarType t) => '$fn requiere un pin (entero), no ${aType(t)}';
  @override
  String functionSignature(String fn) => switch (fn) {
    'abs' || 'sqrt' || 'int' || 'round' => '$fn(número)',
    'len' => 'len(cadena)',
    'random' => 'random(n)',
    'digitalRead' || 'analogRead' => '$fn(pin)',
    _ => '$fn()',
  };
  @override
  String functionDescription(String fn) => switch (fn) {
    'abs' => 'valor absoluto',
    'sqrt' => 'raíz cuadrada (resultado real)',
    'int' => 'parte entera, trunca los decimales: int(3.9) = 3, int(-3.9) = -3',
    'round' => 'redondea al entero más cercano (0.5 se redondea alejándose del cero)',
    'len' => 'número de caracteres de la cadena',
    'random' => 'entero aleatorio entre 0 y n-1',
    'digitalRead' => 'lee una entrada digital: HIGH (1) o LOW (0)',
    'analogRead' => 'lee una entrada analógica: de 0 a 1023',
    'millis' => 'milisegundos transcurridos desde el encendido',
    _ => fn,
  };

  // ================================================================ validazione
  @override
  String get valChooseVariable => 'elige una variable';
  @override
  String valConstant(String name) => "'$name' es una constante: no puede cambiar de valor";
  @override
  String valUndeclared(String name) => "variable '$name' no definida";
  @override
  String valConditionBoolean(VarType t) =>
      'la condición debe ser verdadera o falsa (lógica), pero es ${aType(t)}';
  @override
  String valNameIsPin(String name) => "'$name' ya es el nombre de un pin o de una constante";
  @override
  String valAlreadyDeclared(String name) => "la variable '$name' ya está definida";
  @override
  String valCounterInteger(String name) => "el contador '$name' debe ser una variable entera";
  @override
  String get whatFrom => 'el valor inicial';
  @override
  String get whatTo => 'el valor final';
  @override
  String get whatStep => 'el paso';
  @override
  String valMustBeInteger(String what, VarType t) =>
      '$what debe ser un entero, pero es ${aType(t)}';
  @override
  String get valStepZero => 'el paso no puede ser 0';
  @override
  String valHighLow(VarType t) => 'el valor debe ser HIGH o LOW, pero es ${aType(t)}';
  @override
  String valPwmInteger(VarType t) => 'el valor debe ser un entero de 0 a 255, pero es ${aType(t)}';
  @override
  String valPwmRange(int max, int value) =>
      'el valor de analogWrite va de 0 a $max, pero es $value';
  @override
  String valReadIntoInteger(String name) =>
      "'$name' debe ser una variable entera para recibir la lectura";
  @override
  String valDelayInteger(VarType t) => 'la espera es en milisegundos enteros, pero es ${aType(t)}';
  @override
  String get valDelayNegative => 'la espera no puede ser negativa';
  @override
  String get valArduinoOnlyBlock => 'este bloque solo se puede usar en los diagramas Arduino';
  @override
  String get valChoosePin => 'elige un pin';
  @override
  String valPinNotConfigured(String name) =>
      "pin '$name' no configurado: agrégalo en «$pinsAndBoard»";
  @override
  String valPinMustBeInt(VarType t) =>
      'el pin debe ser un número entero o el nombre de un pin, pero es ${aType(t)}';
  @override
  String valPinNamed(String name, String pin) => "'$name' (pin $pin)";
  @override
  String valPinNumber(String pin) => 'el pin $pin';
  @override
  String valPinNotOnBoard(String pin, String board) => 'el pin $pin no existe en $board';
  @override
  String valPinNotConfiguredLabel(String label) =>
      '$label no está configurado: agrégalo en «$pinsAndBoard» con un nombre (p. ej. LED)';
  @override
  String valPinNotOutput(String label, String mode) =>
      '$label está configurado como $mode: para escribir en él debe ser una salida';
  @override
  String valNoPwm(String label, String board, String pins) =>
      '$label no admite analogWrite (PWM): en $board usa uno de los pines $pins';
  @override
  String valPinIsOutput(String label) =>
      '$label es una salida: para leerlo, configúralo como entrada';
  @override
  String valAnalogReadPins(String pins) => 'analogRead solo funciona en los pines $pins';
  @override
  String valAnalogAlias(String label, String digital) =>
      '$label solo se usa con analogRead(): como pin digital es el pin $digital.';
  @override
  String valAnalogOnly(String label) =>
      '$label es solo una entrada analógica: léela con analogRead().';
  @override
  String valAnalogReadMode(String label) =>
      '$label debe configurarse como entrada analógica para usar analogRead';
  @override
  String valPinNameError(String name, String error) => "nombre del pin '$name': $error";
  @override
  String valPinNameTwice(String name) => "el nombre '$name' se usa para dos pines";
  @override
  String valPinNotExists(String name, String pin, String board) =>
      '$name: el pin $pin no existe en $board';
  @override
  String valPinTwice(String pin) => 'el pin $pin está configurado dos veces';
  @override
  String valPinModeInvalid(String name, String pin, String mode) =>
      '$name: el pin $pin no puede ser $mode';
  @override
  String valSerialPins(String name, List<String> pins) =>
      '$name: los pines ${pins.join(' y ')} se usan para la comunicación serie (Leer/Escribir): '
      'elige otro pin';
  @override
  String valAssignRealToInt(String target) =>
      "'$target' es entera pero el valor es real: usa int(...) o round(...), "
      "o define '$target' como real";
  @override
  String valAssignType(VarType value, String target, VarType targetType) =>
      "no puedes asignar ${aType(value)} a '$target', que es de tipo ${_t(targetType)}";

  // ================================================================ file .flow
  @override
  String get fileDamaged => 'el archivo está dañado o no es un diagrama de DB Flow';
  @override
  String get fileNotFlow => 'el archivo no es un diagrama de DB Flow';
  @override
  String get fileBadVersion => 'versión del archivo ausente o no válida';
  @override
  String get fileTooNew =>
      'el archivo se creó con una versión más reciente de la app: actualiza DB Flow';
  @override
  String fileFieldMissing(String key) => "campo '$key' ausente o no válido";
  @override
  String fileFieldInvalid(String key) => "campo '$key' no válido";
  @override
  String get fileBadBlock => 'bloque no válido';
  @override
  String fileUnknownBlock(String t) => "tipo de bloque desconocido: '$t'";
  @override
  String fileUnknownType(String name) => "tipo desconocido: '$name'";
  @override
  String get untitled => 'Sin nombre';

  // ================================================================ esecuzione
  @override
  String runUndeclared(String name) => "la variable '$name' no ha sido definida";
  @override
  String runNoValue(String name) =>
      "la variable '$name' todavía no tiene valor: asígnale uno o léela antes de usarla";
  @override
  String runAssignType(VarType value, String name, VarType varType) =>
      "no puedes asignar ${aType(value)} a '$name', que es de tipo ${_t(varType)}";
  @override
  String get inputNeedInteger => 'escribe un número entero, por ejemplo 42';
  @override
  String get inputNeedNumber => 'escribe un número, por ejemplo 3.5';
  @override
  String get inputNeedBoolean => 'escribe verdadero o falso';
  @override
  String runTypeInvalid(String what) => 'tipo no válido: $what';
  @override
  String get runNeedNumber => 'se necesita un número';
  @override
  String get runNeedBoolean => 'se necesita un valor lógico';
  @override
  String runOpNotApplicable(String op, VarType t) => "'$op' no se aplica a ${aType(t)}";
  @override
  String get runDivZero => 'división por cero';
  @override
  String get runModInts => "'%' se usa entre enteros";
  @override
  String get runModZero => 'resto de una división por cero';
  @override
  String runSqrtNegative(String value) => 'raíz cuadrada de un número negativo ($value)';
  @override
  String runNotFinite(String fn) => '$fn: el valor no es un número finito';
  @override
  String get runLenString => 'len requiere una cadena';
  @override
  String get runRandomInt => 'random requiere un entero';
  @override
  String runRandomPositive(int n) => 'random(n) requiere n mayor que 0, pero n = $n';
  @override
  String runNotSimulated(String fn) => "'$fn' todavía no está disponible en la simulación";
  @override
  String runTooManySteps(int n) =>
      'se superaron los $n pasos: quizá el programa tiene un bucle infinito '
      '(¿la condición nunca se vuelve falsa?)';
  @override
  String runConditionValue(String value) =>
      'la condición debe ser verdadera o falsa, pero vale $value';
  @override
  String runMustBeInteger(String what, String value) =>
      '$what debe ser un entero, pero vale $value';
  @override
  String get runStepZero => 'el paso del bucle no puede ser 0';
  @override
  String get runArduinoNotSimulated =>
      'los bloques Arduino todavía no se simulan: genera el sketch';
  @override
  String runCounterInteger(String name) => "el contador '$name' debe seguir siendo entero";
  @override
  String runInvalidExpr(String text) => "expresión no válida: '$text'";
  @override
  String get runInputMissing => 'falta la entrada';
  @override
  String runFinished(int steps) => 'Programa terminado ($steps pasos)';
  @override
  String runErrorLine(String message) => 'Error: $message';

  // ================================================================ diagramma
  @override
  String get flowStart => 'Inicio';
  @override
  String get flowEnd => 'Fin';
  @override
  String get edgeTrue => 'verdadero';
  @override
  String get edgeFalse => 'falso';
  @override
  String get flowRepeat => 'repetir';
  @override
  String labelRead(String variable) => 'Leer $variable';
  @override
  String labelWrite(String text) => 'Escribir $text';
  @override
  String labelFor(String variable, String from, String to, String? step) =>
      '$variable desde $from hasta $to${step == null ? '' : ', paso $step'}';
  @override
  String get kindAlgorithm => 'Algoritmo';
  @override
  String get kindArduino => 'Arduino';
  @override
  String get pinModeOutput => 'salida';
  @override
  String get pinModeInput => 'entrada';
  @override
  String get pinModeInputPullup => 'entrada con pull-up';
  @override
  String get pinModeAnalogInput => 'entrada analógica';

  // ================================================================ codice generato
  @override
  String get codeGenerated => 'Código generado por DB Flow';
  @override
  String codeGeneratedFor(String board) => 'Código generado por DB Flow para $board';
  @override
  String get codeConnections => 'Conexiones:';
  @override
  String codeInvalidExpr(String text) => 'ERROR: expresión no válida: $text';
  @override
  String codeArduinoOnly(String label) => '$label: disponible solo en Arduino';
  @override
  String inputPrompt(String variable) => 'Ingresa $variable: ';
  @override
  String get codeAnswerVar => 'respuesta';
  @override
  String get codeConcatUnsupported =>
      'concatenación de texto: usa un bloque Escribir o una asignación';
  @override
  String get codeLanguagePseudo => 'Pseudocódigo';
  @override
  String pAlgorithm(String name) => 'ALGORITMO $name';
  @override
  String get pBegin => 'INICIO';
  @override
  String get pEnd => 'FIN';
  @override
  String pDeclare(String name, String type) => 'DEFINIR $name COMO ${type.toUpperCase()}';
  @override
  String pRead(String variable) => 'LEER $variable';
  @override
  String pWrite(String text) => 'ESCRIBIR $text';
  @override
  String pIf(String cond) => 'SI $cond ENTONCES';
  @override
  String get pElse => 'SINO';
  @override
  String get pEndIf => 'FIN SI';
  @override
  String pWhile(String cond) => 'MIENTRAS $cond HACER';
  @override
  String get pEndWhile => 'FIN MIENTRAS';
  @override
  String get pRepeat => 'REPETIR';
  @override
  String pRepeatWhile(String cond) => 'MIENTRAS QUE $cond';
  @override
  String pFor(String variable, String from, String to, String? step) =>
      'PARA $variable DESDE $from HASTA $to${step == null ? '' : ' CON PASO $step'} HACER';
  @override
  String get pEndFor => 'FIN PARA';
  @override
  String pSketch(String name, String board) => 'SKETCH $name ($board)';
  @override
  String pPin(String name, String pin, String mode) => 'PIN $name = $pin ($mode)';
  @override
  String get pSetup => 'SETUP';
  @override
  String get pEndSetup => 'FIN SETUP';
  @override
  String get pLoop => 'LOOP (repetir siempre)';
  @override
  String get pEndLoop => 'FIN LOOP';

  // ================================================================ interfaccia: comuni
  @override
  String get cancel => 'Cancelar';
  @override
  String get undo => 'Deshacer';
  @override
  String get redo => 'Rehacer';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Eliminar';
  @override
  String get share => 'Compartir';
  @override
  String get saveAs => 'Guardar como…';
  @override
  String get saveFlowFile => 'Guardar archivo .flow…';
  @override
  String get saveExercise => 'Guardar como ejercicio…';
  @override
  String get more => 'Más';
  @override
  String get name => 'Nombre';
  @override
  String get create => 'Crear';
  @override
  String get insert => 'Insertar';
  @override
  String get save => 'Guardar';
  @override
  String get add => 'Agregar';
  @override
  String get edit => 'Editar';
  @override
  String get run => 'Ejecutar';
  @override
  String get pin => 'Pin';
  @override
  String get pinsAndBoard => 'Pines y placa';
  @override
  String get code => 'Código';
  @override
  String get info => 'Información';
  @override
  String get theme => 'Tema';
  @override
  String get themeSystem => 'Como el dispositivo';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Oscuro';

  // ================================================================ home
  @override
  String get newDiagram => 'Nuevo diagrama';
  @override
  String get myDiagrams => 'Mis diagramas';
  @override
  String get noDiagrams => 'Ningún diagrama';
  @override
  String get noDiagramsHint => 'Crea uno nuevo o parte de un ejemplo.';
  @override
  String get damagedFile => 'Archivo dañado';
  @override
  String modified(String date) => 'Modificado: $date';
  @override
  String get examples => 'Ejemplos';
  @override
  String get examplesArduino => 'Ejemplos Arduino';
  @override
  String get opensCopy => 'Abre una copia editable';
  @override
  String get openFlowFile => 'Abrir un archivo .flow';
  @override
  String openFailed(String message) => 'No se pudo abrir: $message';
  @override
  String importFailed(String message) => 'No se pudo abrir el archivo: $message';
  @override
  String get importNotFlow => 'No se pudo abrir el archivo: no es un diagrama de DB Flow';
  @override
  String shareFailed(String error) => 'No se pudo compartir: $error';
  @override
  String get deleteTitle => '¿Eliminar el diagrama?';
  @override
  String deleteBody(String name) => '"$name" se eliminará de este dispositivo.';
  @override
  String get hintNameArduino => 'p. ej. Semáforo';
  @override
  String get hintNameAlgorithm => 'p. ej. Suma de dos números';
  @override
  String get newArduinoHint =>
      'El diagrama tendrá una parte setup() y una loop(). '
      'Configura las conexiones con el botón «$pin».';

  // ================================================================ editor
  @override
  String saveFailed(String error) => 'No se pudo guardar: $error';
  @override
  String get blockDeleted => 'Bloque eliminado';
  @override
  String get blockDeletedWithContent => 'Bloque eliminado con su contenido';
  @override
  String get diagramName => 'Nombre del diagrama';
  @override
  String fixBeforeRun(int count) => count == 1
      ? 'Primero corrige el bloque en rojo; después podrás ejecutar el programa.'
      : 'Primero corrige los $count problemas marcados en rojo.';
  @override
  String operationFailed(String error) => 'La operación falló: $error';
  @override
  String get insertBlock => 'Insertar un bloque';
  @override
  String pinIssues(int count) => count == 1
      ? '$pinsAndBoard: 1 problema por corregir'
      : '$pinsAndBoard: $count problemas por corregir';
  @override
  String blockIssues(int count) => count == 1
      ? '1 problema: toca el bloque en rojo para verlo'
      : '$count problemas: toca los bloques en rojo para verlos';
  @override
  String get backToEdit => 'Volver a editar';
  @override
  String get centerDiagram => 'Centrar el diagrama';
  @override
  String get shareFlowFile => 'Compartir archivo .flow';
  @override
  String get exportPng => 'Exportar imagen PNG';
  @override
  String get exportSvg => 'Exportar SVG';
  @override
  String get exportPdf => 'Exportar PDF';
  @override
  String get duplicate => 'Duplicar';
  @override
  String get moveUp => 'Subir';
  @override
  String get moveDown => 'Bajar';
  @override
  String get arduinoSketch => 'Sketch de Arduino';
  @override
  String get chooseSketchFolder => 'Elige dónde crear la carpeta del sketch';
  @override
  String get arduinoSketchFile => 'Sketch de Arduino (.ino)';
  @override
  String get arduinoSketchHelp => 'Ábrelo con el Arduino IDE para cargarlo en la placa';
  @override
  String sketchSaved(String path) => 'Sketch guardado en $path';
  @override
  String wiringLine(String name, String pin, String mode) => '$name: pin $pin, $mode';
  @override
  String get pdfWiring => 'Conexiones';
  @override
  String get pdfCode => 'Código';
  @override
  String get defaultFileName => 'diagrama';
  @override
  String get blockDeclare => 'Definir variable';
  @override
  String get blockAssign => 'Asignación';
  @override
  String get blockInput => 'Leer (entrada)';
  @override
  String get blockOutput => 'Escribir (salida)';
  @override
  String get blockIf => 'Si … entonces … sino';
  @override
  String get blockWhile => 'Mientras (while)';
  @override
  String get blockDoWhile => 'Repetir … mientras que (do-while)';
  @override
  String get blockFor => 'Para (for)';
  @override
  String get blockComment => 'Comentario';
  @override
  String get blockDigitalRead => 'digitalRead (entrada digital)';
  @override
  String get blockAnalogRead => 'analogRead (entrada analógica)';
  @override
  String get blockDigitalWrite => 'digitalWrite (salida digital)';
  @override
  String get blockAnalogWrite => 'analogWrite (salida PWM)';
  @override
  String get blockDelay => 'delay (espera)';
  @override
  String get fieldVarToModify => 'Variable que se modifica';
  @override
  String get fieldNewValue => 'Nuevo valor';
  @override
  String get hintNewValue => 'p. ej. a + 1';
  @override
  String get fieldVarToRead => 'Variable donde se guarda lo leído';
  @override
  String get fieldWhatToWrite => 'Qué escribir';
  @override
  String get hintWrite => 'p. ej. "Resultado: " & r';
  @override
  String get fieldCondition => 'Condición';
  @override
  String get hintCondition => 'p. ej. a > b';
  @override
  String get fieldCounter => 'Contador (variable entera)';
  @override
  String get fieldFrom => 'Desde';
  @override
  String get fieldTo => 'Hasta (incluido)';
  @override
  String get fieldStep => 'Paso';
  @override
  String get hintFrom => 'p. ej. 1';
  @override
  String get hintTo => 'p. ej. n';
  @override
  String get fieldCommentText => 'Texto del comentario';
  @override
  String get fieldValue => 'Valor';
  @override
  String get hintHighLow => 'HIGH o LOW';
  @override
  String get fieldPwmValue => 'Valor (0–255)';
  @override
  String get hintPwm => 'p. ej. 128';
  @override
  String get fieldDelayMs => 'Espera en milisegundos';
  @override
  String get hintDelay => 'p. ej. 500 (medio segundo)';
  @override
  String get fieldReadTarget => 'Variable que recibe la lectura';
  @override
  String get readsDigital => 'Lee HIGH (1) o LOW (0).';
  @override
  String get readsAnalog => 'Lee un valor de 0 (0 V) a 1023 (5 V).';
  @override
  String varExists(String name) => "ya existe una variable '$name'";
  @override
  String get fieldVarName => 'Nombre de la variable';
  @override
  String get hintVarName => 'p. ej. suma';
  @override
  String get fieldType => 'Tipo';
  @override
  String get noIntegerVariables =>
      "No hay variables enteras: primero agrega un bloque '$blockDeclare'.";
  @override
  String get noVariables => "No hay variables: primero agrega un bloque '$blockDeclare'.";
  @override
  String notDeclared(String name) => '$name (no definida)';
  @override
  String get noInputPins => 'No hay entradas configuradas';
  @override
  String get noAnalogPins => 'No hay entradas analógicas configuradas';
  @override
  String get noOutputPins => 'No hay pines de salida configurados';
  @override
  String get addFromPins => ': agrégalo en «$pinsAndBoard» (botón $pin arriba).';
  @override
  String get noPwmTag => ' · sin PWM';
  @override
  String pwmOn(String board, String pins) => 'PWM en $board: $pins';
  @override
  String column(int column, String message) => 'Columna $column: $message';

  // ================================================================ esecuzione (pannello)
  @override
  String get variables => 'Variables';
  @override
  String get console => 'Consola';
  @override
  String get restart => 'Reiniciar';
  @override
  String get pause => 'Pausa';
  @override
  String get oneStep => 'Un paso';
  @override
  String get toEnd => 'Hasta el final';
  @override
  String get statusReady => 'Listo: pulsa ▶ o ⏭';
  @override
  String statusPaused(int steps) => 'En pausa · paso $steps';
  @override
  String statusRunning(int steps) => 'En ejecución · paso $steps';
  @override
  String statusWaiting(String variable, String type) => 'Escribe un valor para $variable ($type)';
  @override
  String statusFinished(int steps) => 'Terminado en $steps pasos';
  @override
  String get statusFailed => 'Error durante la ejecución';
  @override
  String condition(bool value) => 'condición: ${value ? 'verdadera' : 'falsa'}';
  @override
  String get send => 'Enviar';
  @override
  String get noVariablesYet => 'Todavía no hay variables definidas';
  @override
  String get consoleEmpty => 'Aquí aparece lo que escribe el programa';

  // ================================================================ codice
  @override
  String get codeHasErrors => 'El diagrama contiene errores: puede que el código no funcione.';
  @override
  String get copy => 'Copiar';
  @override
  String get codeCopied => 'Código copiado';

  // ================================================================ pin e scheda
  @override
  String get addPin => 'Agregar pin';
  @override
  String get board => 'Placa';
  @override
  String get serialBaud => 'Serie (baudios)';
  @override
  String get toFix => 'Por corregir';
  @override
  String get usedNotConfigured => 'Usados en el diagrama pero no configurados';
  @override
  String suggestionTitle(String name, String mode, String? pin) =>
      '$name → $mode${pin == null ? '' : ' (pin $pin)'}';
  @override
  String usedIn(String where) => 'en: $where';
  @override
  String get wiring => 'Conexiones';
  @override
  String get tapPinHint => 'Toca un pin en el dibujo para configurarlo.';
  @override
  String get configuredPins => 'Pines configurados';
  @override
  String get noPins => 'Ningún pin';
  @override
  String get noPinsHint =>
      'Ponle un nombre a cada conexión (p. ej. LED en el pin 13): en los bloques usarás el nombre.';
  @override
  String get pwmTag => 'PWM';
  @override
  String get onBoardLed => 'LED de la placa';
  @override
  String removePin(String name) => 'Quitar $name';
  @override
  String get generatedSetup => 'setup() generado';
  @override
  String get setupNote =>
      'Los pinMode y Serial.begin se actualizan solos. Los bloques que agregues en la parte '
      'setup() del diagrama se ejecutan justo después.';
  @override
  String get pinNameExists => 'ya existe un pin con este nombre';
  @override
  String get variableNameExists => 'ya existe una variable con este nombre';
  @override
  String get analogTag => 'analógico';
  @override
  String get serialTag => 'serie';
  @override
  String pinOption(String pin, List<String> tags) =>
      tags.isEmpty ? 'pin $pin' : 'pin $pin  ·  ${tags.join(', ')}';
  @override
  String get newPin => 'Nuevo pin';
  @override
  String get editPin => 'Editar pin';
  @override
  String get hintPinName => 'p. ej. LED, BOTON, SENSOR';
  @override
  String get mode => 'Modo';
  @override
  String get pwmNeeded => 'Hace falta un pin PWM (~): el diagrama lo usa con analogWrite.';
  @override
  String get pullupNote =>
      'Con el pull-up, el pin lee HIGH en reposo y LOW cuando el botón '
      '(conectado a GND) está pulsado.';
  @override
  String get microcontroller => 'microcontrolador';
  @override
  String boardSemantics(String board) => 'Dibujo de $board: toca un pin para configurarlo';

  // ================================================================ informazioni
  @override
  String version(String v) => 'Versión $v';
  @override
  String get aboutDescription =>
      'Editor de diagramas de flujo estructurados y ejecutables, para docentes y estudiantes: '
      'construyes el algoritmo con bloques, lo ejecutas paso a paso y generas su código '
      '(pseudocódigo, Python, C, Arduino).';
  @override
  String madeBy(String author) => 'Realizado por el $author.';
  @override
  String get privacy => 'Privacidad';
  @override
  String get noAccount => 'Sin cuenta';
  @override
  String get noAds => 'Sin publicidad';
  @override
  String get noDataCollection => 'Sin recopilación de datos';
  @override
  String get dataStaysOnDevice => 'Los diagramas se quedan en el dispositivo';
  @override
  String get privacySummary =>
      'La app no contiene sistemas de análisis, publicidad ni informes de errores, y no usa '
      'internet. Los archivos se comparten directamente entre personas (AirDrop, Mail, '
      'Archivos…).';
  @override
  String get privacyPolicy => 'Política de privacidad';
  @override
  String get guideBlocks => 'Guía rápida: los bloques';
  @override
  String get guideExpressions => 'Guía rápida: las expresiones';
  @override
  List<(String, String)> get guideBlockItems => const [
    ('Inicio / Fin', 'Dónde empieza y dónde termina el algoritmo.'),
    ('Definición', 'Crea una variable: entero, real, cadena, lógico.'),
    ('Asignación', 'Calcula un valor y lo guarda en una variable: a ← b + 1.'),
    ('Leer / Escribir', 'Entrada y salida: teclado y consola (puerto serie en Arduino).'),
    ('Decisión', 'Si, Mientras, Repetir…mientras que: la condición es verdadera o falsa.'),
    ('Ciclo Para', 'Un contador va de un valor a otro, con un paso.'),
    ('Pines Arduino', 'digitalRead/Write, analogRead/Write: entradas y salidas.'),
    ('delay', 'Espera en milisegundos (Arduino).'),
  ];
  @override
  List<(String, String)> get guideExpressionItems => const [
    ('Números y texto', '12   3.14   "hola"   verdadero   falso'),
    ('Aritmética', '+  -  *  /  %   (7 / 2 = 3.5, 7 % 2 = 1)'),
    ('Comparaciones', '==  !=  <  <=  >  >='),
    ('Lógicos', 'and  or  not   (también &&  ||  !)'),
    ('Unir texto', '"Total: " & t'),
  ];
  @override
  String get availableFunctions => 'Funciones disponibles:';
  @override
  String get license => 'Licencia';
  @override
  String licenseText(String license) =>
      'Código público y verificable (source-available) con licencia $license: '
      'uso libre con fines no comerciales.';
  @override
  String get componentLicenses => 'Licencias de los componentes utilizados';

  // ================================================================ informativa privacy
  @override
  String get privacyUpdated => 'Última actualización: 21 de noviembre de 2026';
  @override
  List<(String, List<String>)> privacySections(
    String app,
    String author,
    String license,
    String contact,
  ) => [
    (
      'En resumen',
      [
        '$app no recopila, no transmite y no vende datos personales.',
        'No se necesita una cuenta ni hay ningún registro.',
        'La app no contiene publicidad.',
        'Los diagramas se quedan en tu dispositivo.',
      ],
    ),
    (
      'Quién es el responsable',
      [
        '$app ha sido realizada por el $author. Como la app no recopila datos personales, '
            'ningún dato del usuario llega al desarrollador.',
      ],
    ),
    (
      'Qué datos usa la app',
      [
        'Solo los diagramas que creas, guardados en la memoria de la app en el dispositivo, y la elección del tema (claro u oscuro). En iPhone y iPad los diagramas también se ven en la app Archivos, en la carpeta de $app.',
        'La app no usa nombres, correos electrónicos, ubicación, fotos, contactos, micrófono, cámara, identificadores del dispositivo ni identificadores publicitarios.',
        'Si la copia de seguridad del dispositivo está activada (iCloud, Google o Time Machine en el Mac), el sistema operativo puede incluir los diagramas en ella, como los documentos de cualquier otra app. Es un servicio del sistema, gestionado desde los ajustes del dispositivo.',
      ],
    ),
    (
      'Conexión a internet',
      [
        'La app funciona sin conexión y no envía nada por la red: ningún servidor, ningún '
            'servicio externo.',
      ],
    ),
    (
      'Servicios de terceros',
      [
        'Ningún sistema de análisis o estadísticas, de publicidad ni de informe automático de '
            'errores. Los componentes utilizados para crear la app se enumeran en '
            '«$componentLicenses».',
      ],
    ),
    (
      'Compartir archivos',
      [
        'Un diagrama, una imagen, un PDF o el código salen de la app solo cuando tú eliges «Compartir», «Exportar» o, en el ordenador, «$saveAs». Tú decides a quién o adónde enviarlo (AirDrop, Mail, Archivos…) o en qué carpeta guardarlo. A partir de ese momento se aplican las reglas de la app o del servicio que elegiste.',
        'Un archivo .flow recibido se abre con «$openFlowFile» o tocándolo en Mail, Archivos o el Finder: la app lee solo ese archivo y guarda una copia entre tus diagramas.',
      ],
    ),
    (
      'En la escuela',
      [
        'La app está pensada para docentes y estudiantes y no pide datos personales. Consejo: '
            'no escribas datos personales en los nombres de los diagramas ni en los textos (por '
            'ejemplo, nombres y apellidos de los estudiantes), sobre todo si los archivos se '
            'comparten.',
      ],
    ),
    (
      'Borrar los datos',
      [
        'Puedes eliminar un diagrama de la lista en la pantalla de inicio. Al desinstalar la app en iPhone, iPad, Android o Windows, el sistema elimina todos los diagramas guardados en ella. En el Mac, si quitas la app de la carpeta Aplicaciones, los diagramas quedan en su carpeta de datos (Biblioteca › Containers › $app), que puedes eliminar. Las copias que hayas compartido o exportado a otro lugar se conservan en cualquier caso.',
      ],
    ),
    (
      'Verificabilidad',
      [
        'El código de $app es público (source-available, licencia $license): cualquiera '
            'puede verificar que la app se comporta como se describe aquí.',
      ],
    ),
    (
      'Cambios y contacto',
      [
        'Si la política cambia, la nueva versión estará en esta página con la fecha '
            'actualizada. Para preguntas: $contact.',
      ],
    ),
  ];

  // ================================================================ componenti e scelta del pin
  @override
  String get componentLed => 'LED';
  @override
  String get componentButton => 'Pulsador';
  @override
  String get componentPotentiometer => 'Potenciómetro';
  @override
  String get componentOther => 'Otro';
  @override
  String get whatToConnect => '¿Qué conectas?';
  @override
  String get digitalPinsTitle => 'Pines digitales';
  @override
  String get analogPinsTitle => 'Pines analógicos';
  @override
  String pinSwapNotice(String other, String otherNewPin) =>
      'Este pin lo usa $other: se intercambian y $other pasa al pin $otherNewPin.';
  @override
  String pinMoveNotice(String other, String newPin) =>
      'Este pin lo usa $other, que se moverá al pin $newPin.';
  @override
  String pinCannotSwap(String other, String pin) =>
      'Este pin lo usa $other, que no puede ir al pin $pin: elige otro pin.';
  @override
  String pinCannotMove(String other) =>
      'Este pin lo usa $other y no hay otro pin libre adecuado: elige otro pin.';
  @override
  String pinMoved(String name, String pin) => '$name movido al pin $pin';

  // ================================================================ esercizi

  @override
  String get exercise => 'Ejercicio';
  @override
  String get exercises => 'Ejercicios';
  @override
  String get exerciseCreate => 'Crear ejercicio';
  @override
  String get exerciseEdit => 'Editar ejercicio';
  @override
  String get exerciseText => 'Enunciado';
  @override
  String get exerciseTextHint => '¿Qué debe hacer el diagrama? Indica también qué debe escribir.';
  @override
  String get testCases => 'Casos de prueba';
  @override
  String testCase(int n) => 'Caso $n';
  @override
  String get hiddenCase => 'Caso oculto';
  @override
  String get caseInputs => 'Datos de entrada';
  @override
  String get caseInputsHint => 'Un valor por línea, en el orden en que se leen';
  @override
  String get caseExpected => 'Salida esperada';
  @override
  String get caseExpectedHint => 'Una línea por cada valor escrito';
  @override
  String get caseActual => 'Salida obtenida';
  @override
  String get caseHidden => 'Oculto a los alumnos';
  @override
  String get addCase => 'Añadir caso';
  @override
  String get removeCase => 'Eliminar caso';
  @override
  String get fillFromDiagram => 'Calcular desde el diagrama';
  @override
  String get fillFromDiagramHelp =>
      'Ejecuta el diagrama con los datos de entrada de cada caso y copia su salida como salida esperada.';
  @override
  String filledCases(int n) =>
      n == 1 ? 'Salida calculada para 1 caso' : 'Salida calculada para $n casos';
  @override
  String fillProblem(int n, String problem) => 'Caso $n: $problem';
  @override
  String get removeExercise => 'Quitar ejercicio';
  @override
  String get removeExerciseBody =>
      'Se quitarán el enunciado y los casos de prueba. El diagrama se mantiene.';
  @override
  String get remove => 'Quitar';
  @override
  String get shareExercise => 'Compartir como ejercicio';
  @override
  String get shareExerciseHelp =>
      'Sin tu solución: el alumno parte de un diagrama vacío y no puede cambiar el enunciado ni los casos.';
  @override
  String get verify => 'Comprobar';
  @override
  String get verifyFixFirst => 'Primero corrige los errores señalados en el diagrama.';
  @override
  String get verifyAllPassed => '¡Todos los casos superados!';
  @override
  String verifyPassed(int ok, int total) =>
      ok == 1 ? 'Superado 1 caso de $total' : 'Superados $ok casos de $total';
  @override
  String get verifyResults => 'Resultado de la comprobación';
  @override
  String get casePassed => 'superado';
  @override
  String get caseFailed => 'no superado';
  @override
  String get outcomeWrongOutput => 'La salida no coincide con la esperada.';
  @override
  String get outcomeMissingInput => 'El diagrama pide más datos de los que tiene el caso.';
  @override
  String get outcomeUnusedInput => 'El diagrama termina sin leer todos los datos del caso.';
  @override
  String outcomeBadInput(String message) => 'Un dato no es válido: $message';
  @override
  String outcomeError(String message) => 'Error: $message';
  @override
  String get noOutput => '(sin salida)';
  @override
  String get noInputs => '(ninguno)';
  @override
  String get exerciseLocked =>
      'Ejercicio recibido: el enunciado y los casos de prueba no se pueden modificar.';
  @override
  String hiddenCasesCount(int n) => n == 1 ? 'más 1 caso oculto' : 'más $n casos ocultos';
  @override
  String get noCases => 'Ningún caso de prueba: añade al menos uno para poder comprobar.';
  @override
  String get showTask => 'Leer el enunciado';

  // ================================================================ simulazione Arduino

  @override
  String get whatPin => 'el pin';
  @override
  String get whatValue => 'el valor';
  @override
  String runTooManyStepsLoop(int n) =>
      'más de $n pasos en una sola vuelta de loop(): quizá hay un bucle infinito (¿la condición nunca se vuelve falsa?)';
  @override
  String runDelayNegative(int ms) => 'delay no puede ser negativo, pero vale $ms';
  @override
  String runPwmRange(int value, int max) =>
      'analogWrite acepta valores de 0 a $max, pero vale $value';
  @override
  String runPinNotOnBoard(int pin, String board) => 'el pin $pin no existe en la placa $board';
  @override
  String runAnalogReadPin(String pin) =>
      'analogRead solo funciona en las entradas analógicas (A0…), no en el pin $pin';
  @override
  String get circuit => 'Circuito';
  @override
  String simLoop(int n) => 'vuelta $n de loop()';
  @override
  String get toLoopEnd => 'Hasta el final de esta vuelta de loop()';
  @override
  String get ledOn => 'encendido';
  @override
  String get ledOff => 'apagado';
  @override
  String get pressed => 'pulsado';
  @override
  String get released => 'suelto';
  @override
  String get tapToPress => 'Toca para pulsar o soltar';
  @override
  String noSimPins(String pinsAndBoard) =>
      'Ningún pin configurado: añádelos en «$pinsAndBoard» para verlos aquí.';
  @override
  String get simNote =>
      'Simulación: el tiempo de cada bloque es aproximado; los delay duran de verdad en ejecución automática.';
}
