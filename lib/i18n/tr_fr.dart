// Textes en français (terminologie de l'algorithmique au lycée).
import '../expr/types.dart';
import 'tr.dart';

class TrFr extends Tr {
  const TrFr();

  @override
  AppLanguage get language => AppLanguage.fr;

  String _t(VarType t) => switch (t) {
    VarType.integer => typeInteger,
    VarType.real => typeReal,
    VarType.string => typeString,
    VarType.boolean => typeBoolean,
  };

  // ================================================================ tipi e valori
  @override
  String get typeInteger => 'entier';
  @override
  String get typeReal => 'réel';
  @override
  String get typeString => 'chaîne';
  @override
  String get typeBoolean => 'booléen';
  @override
  String aType(VarType t) => switch (t) {
    VarType.string => 'une chaîne',
    _ => 'un ${_t(t)}',
  };
  @override
  String get trueWord => 'vrai';
  @override
  String get falseWord => 'faux';
  @override
  String get realUndefined => 'non défini';
  @override
  String get realInfinite => 'infini';

  // ================================================================ lexer
  @override
  String get lexIncompleteNumber =>
      'nombre incomplet : il manque la partie décimale après le point';
  @override
  String get lexNameStartsWithDigit => 'un nom ne peut pas commencer par un chiffre';
  @override
  String get lexNumberTooLarge => 'nombre trop grand';
  @override
  String lexAccentedLetter(String ch) =>
      "lettre '$ch' interdite dans les noms : utilisez des lettres sans accent";
  @override
  String get lexUnclosedString => 'chaîne non fermée : il manque le guillemet "';
  @override
  String get lexUseOr => "pour « ou », utilisez 'or' (ou '||')";
  @override
  String get lexUseDoubleEquals =>
      "pour comparer, utilisez '==' ; le '=' simple n'est pas autorisé ici";
  @override
  String get lexUseNotEquals => "pour « différent de », utilisez '!='";
  @override
  String get lexUseDoubleQuotes => 'les chaînes s\'écrivent entre guillemets doubles : "texte"';
  @override
  String lexInvalidChar(String ch) => "caractère non valide : '$ch'";
  @override
  String get idEmpty => 'le nom est vide';
  @override
  String get idHasSpaces => "un nom ne peut pas contenir d'espaces (utilisez _ à la place)";
  @override
  String get idInvalidChars => 'utilisez seulement des lettres sans accent, des chiffres et _';
  @override
  String idIsFunction(String name) => "'$name' est le nom d'une fonction";
  @override
  String idReserved(String name) => "'$name' est un mot réservé";

  // ================================================================ parser
  @override
  String get parseEmpty => 'expression vide';
  @override
  String get parseChainedComparison =>
      'comparaisons enchaînées interdites : écrivez par exemple a < b and b < c';
  @override
  String get parseMissingCloseParen => "il manque la parenthèse ')' qui ferme cette '('";
  @override
  String get parseIncomplete => 'expression incomplète : il manque une valeur à la fin';
  @override
  String get parseMissingValueBeforeClose => "il manque une valeur avant ')'";
  @override
  String get parseUnexpectedComma =>
      'virgule inattendue : pour les décimaux, utilisez le point (3.14)';
  @override
  String parseMissingValueBefore(String token) => "il manque une valeur avant '$token'";
  @override
  String parseUnknownFunction(String name) => "fonction '$name' inconnue";
  @override
  String parseArity(String fn, int arity, int given) =>
      '$fn attend ${switch (arity) {
        0 => 'des parenthèses vides : $fn()',
        1 => '1 argument',
        _ => '$arity arguments',
      }}, vous en avez écrit $given';
  @override
  String get parseUnmatchedClose => "parenthèse ')' sans '(' correspondante";
  @override
  String parseMissingOperatorBefore(String token) => "il manque un opérateur avant '$token'";
  @override
  String parseUnexpected(String token) => "'$token' inattendu ici";

  // ================================================================ controllo dei tipi
  @override
  String typeUndeclared(String name) => "variable '$name' non déclarée";
  @override
  String typeUndeclaredLowercase(String name, String lower) =>
      "variable '$name' non déclarée : écrivez '$lower' en minuscules";
  @override
  String typeNegNumber(VarType t) => "le signe '-' s'applique à un nombre, pas à ${aType(t)}";
  @override
  String typeNotBoolean(VarType t) =>
      "'not' s'applique à un booléen, pas à ${aType(t)} ; si besoin, utilisez des "
      'parenthèses : not (a > b)';
  @override
  String typePair(VarType a, VarType b) => '${aType(a)} et ${aType(b)}';
  @override
  String typeArith(String sym, VarType a, VarType b) =>
      "'$sym' s'utilise entre nombres, pas entre ${typePair(a, b)}";
  @override
  String typePlusText(VarType a, VarType b) =>
      "'+' ne joint pas ${typePair(a, b)} : pour composer un texte, utilisez '&'";
  @override
  String typeModInts(VarType a, VarType b) =>
      "'%' (reste) s'utilise entre entiers, pas entre ${typePair(a, b)}";
  @override
  String typeCannotCompare(VarType a, VarType b) => 'impossible de comparer ${typePair(a, b)}';
  @override
  String typeCompareNumStr(String sym, VarType a, VarType b) =>
      "'$sym' s'utilise entre nombres ou entre chaînes, pas entre ${typePair(a, b)}";
  @override
  String typeLogical(String sym, VarType a, VarType b) =>
      "'$sym' s'utilise entre conditions (booléens), pas entre ${typePair(a, b)}";
  @override
  String typeArduinoOnly(String fn) => "'$fn' ne s'utilise que dans les organigrammes Arduino";
  @override
  String fnNeedsNumber(String fn, VarType t) => '$fn attend un nombre, pas ${aType(t)}';
  @override
  String fnNeedsString(String fn, VarType t) => '$fn attend une chaîne, pas ${aType(t)}';
  @override
  String fnNeedsInteger(String fn, VarType t) => '$fn attend un entier, pas ${aType(t)}';
  @override
  String fnNeedsPin(String fn, VarType t) => '$fn attend une broche (entier), pas ${aType(t)}';
  @override
  String functionSignature(String fn) => switch (fn) {
    'abs' || 'sqrt' || 'int' || 'round' => '$fn(nombre)',
    'len' => 'len(chaîne)',
    'random' => 'random(n)',
    'digitalRead' || 'analogRead' => '$fn(broche)',
    _ => '$fn()',
  };
  @override
  String functionDescription(String fn) => switch (fn) {
    'abs' => 'valeur absolue',
    'sqrt' => 'racine carrée (résultat réel)',
    'int' => 'partie entière, tronque les décimales : int(3.9) = 3, int(-3.9) = -3',
    'round' => "arrondit à l'entier le plus proche (0.5 est arrondi en s'éloignant de zéro)",
    'len' => 'nombre de caractères de la chaîne',
    'random' => 'entier aléatoire entre 0 et n-1',
    'digitalRead' => 'lit une entrée numérique : HIGH (1) ou LOW (0)',
    'analogRead' => 'lit une entrée analogique : de 0 à 1023',
    'millis' => 'millisecondes écoulées depuis la mise sous tension',
    _ => fn,
  };

  // ================================================================ validazione
  @override
  String get valChooseVariable => 'choisissez une variable';
  @override
  String valConstant(String name) => "'$name' est une constante : sa valeur ne peut pas changer";
  @override
  String valUndeclared(String name) => "variable '$name' non déclarée";
  @override
  String valConditionBoolean(VarType t) =>
      'la condition doit être vraie ou fausse (booléen), pas ${aType(t)}';
  @override
  String valNameIsPin(String name) => "'$name' est déjà le nom d'une broche ou d'une constante";
  @override
  String valAlreadyDeclared(String name) => "la variable '$name' est déjà déclarée";
  @override
  String valCounterInteger(String name) => "le compteur '$name' doit être une variable entière";
  @override
  String get whatFrom => 'la valeur initiale';
  @override
  String get whatTo => 'la valeur finale';
  @override
  String get whatStep => 'le pas';
  @override
  String valMustBeInteger(String what, VarType t) => '$what doit être un entier, pas ${aType(t)}';
  @override
  String get valStepZero => 'le pas ne peut pas être 0';
  @override
  String valHighLow(VarType t) => 'la valeur doit être HIGH ou LOW, pas ${aType(t)}';
  @override
  String valPwmInteger(VarType t) => 'la valeur doit être un entier de 0 à 255, pas ${aType(t)}';
  @override
  String valPwmRange(int max, int value) =>
      "la valeur d'analogWrite va de 0 à $max, or elle vaut $value";
  @override
  String valReadIntoInteger(String name) =>
      "'$name' doit être une variable entière pour recevoir la lecture";
  @override
  String valDelayInteger(VarType t) =>
      "l'attente doit être un nombre entier de millisecondes, pas ${aType(t)}";
  @override
  String get valDelayNegative => "l'attente ne peut pas être négative";
  @override
  String get valArduinoOnlyBlock => "ce bloc ne s'utilise que dans les organigrammes Arduino";
  @override
  String get valChoosePin => 'choisissez une broche';
  @override
  String valPinNotConfigured(String name) =>
      "broche '$name' non configurée : ajoutez-la dans « $pinsAndBoard »";
  @override
  String valPinMustBeInt(VarType t) =>
      "la broche doit être un nombre entier ou le nom d'une broche, pas ${aType(t)}";
  @override
  String valPinNamed(String name, String pin) => "'$name' (broche $pin)";
  @override
  String valPinNumber(String pin) => 'la broche $pin';
  @override
  String valPinNotOnBoard(String pin, String board) => "la broche $pin n'existe pas sur $board";
  @override
  String valPinNotConfiguredLabel(String label) =>
      'aucune configuration pour $label : ajoutez-la dans « $pinsAndBoard » '
      'avec un nom (ex. LED)';
  @override
  String valPinNotOutput(String label, String mode) =>
      '$label est en mode $mode : pour y écrire, il faut une sortie';
  @override
  String valNoPwm(String label, String board, String pins) =>
      "$label ne gère pas analogWrite (PWM) : sur $board, utilisez l'une des broches $pins";
  @override
  String valPinIsOutput(String label) => '$label est une sortie : pour lire, configurez une entrée';
  @override
  String valAnalogReadPins(String pins) => 'analogRead ne fonctionne que sur les broches $pins';
  @override
  String valAnalogAlias(String label, String digital) =>
      "$label ne s'utilise qu'avec analogRead() : comme broche numérique, c'est la broche $digital.";
  @override
  String valAnalogOnly(String label) =>
      '$label est uniquement une entrée analogique : lisez-la avec analogRead().';
  @override
  String valAnalogReadMode(String label) =>
      '$label doit être en mode entrée analogique pour utiliser analogRead';
  @override
  String valPinNameError(String name, String error) => "nom de la broche '$name' : $error";
  @override
  String valPinNameTwice(String name) => "le nom '$name' est utilisé pour deux broches";
  @override
  String valPinNotExists(String name, String pin, String board) =>
      "$name : la broche $pin n'existe pas sur $board";
  @override
  String valPinTwice(String pin) => 'la broche $pin est configurée deux fois';
  @override
  String valPinModeInvalid(String name, String pin, String mode) =>
      '$name : la broche $pin ne peut pas être en mode $mode';
  @override
  String valSerialPins(String name, List<String> pins) =>
      '$name : les broches ${pins.join(' et ')} servent à la liaison série (Lire/Écrire) : '
      'choisissez une autre broche';
  @override
  String valAssignRealToInt(String target) =>
      "'$target' est entière mais la valeur est réelle : utilisez int(...) ou round(...), "
      "ou déclarez '$target' comme réel";
  @override
  String valAssignType(VarType value, String target, VarType targetType) =>
      "impossible d'affecter ${aType(value)} à '$target', qui est de type ${_t(targetType)}";

  // ================================================================ file .flow
  @override
  String get fileDamaged => "le fichier est endommagé ou n'est pas un organigramme DB Flow";
  @override
  String get fileNotFlow => "le fichier n'est pas un organigramme DB Flow";
  @override
  String get fileBadVersion => 'version du fichier manquante ou non valide';
  @override
  String get fileTooNew =>
      "le fichier a été créé avec une version plus récente de l'application : "
      'mettez à jour DB Flow';
  @override
  String fileFieldMissing(String key) => "champ '$key' manquant ou non valide";
  @override
  String fileFieldInvalid(String key) => "champ '$key' non valide";
  @override
  String get fileBadBlock => 'bloc non valide';
  @override
  String fileUnknownBlock(String t) => "type de bloc inconnu : '$t'";
  @override
  String fileUnknownType(String name) => "type inconnu : '$name'";
  @override
  String get untitled => 'Sans titre';

  // ================================================================ esecuzione
  @override
  String runUndeclared(String name) => "la variable '$name' n'a pas été déclarée";
  @override
  String runNoValue(String name) =>
      "la variable '$name' n'a pas encore de valeur : affectez-lui une valeur ou "
      "lisez-la avant de l'utiliser";
  @override
  String runAssignType(VarType value, String name, VarType varType) =>
      "impossible d'affecter ${aType(value)} à '$name', qui est de type ${_t(varType)}";
  @override
  String get inputNeedInteger => 'saisissez un nombre entier, par exemple 42';
  @override
  String get inputNeedNumber => 'saisissez un nombre, par exemple 3.5';
  @override
  String get inputNeedBoolean => 'saisissez vrai ou faux';
  @override
  String runTypeInvalid(String what) => 'type non valide : $what';
  @override
  String get runNeedNumber => 'un nombre est attendu';
  @override
  String get runNeedBoolean => 'un booléen est attendu';
  @override
  String runOpNotApplicable(String op, VarType t) => "'$op' ne s'applique pas à ${aType(t)}";
  @override
  String get runDivZero => 'division par zéro';
  @override
  String get runModInts => "'%' s'utilise entre entiers";
  @override
  String get runModZero => "reste d'une division par zéro";
  @override
  String runSqrtNegative(String value) => "racine carrée d'un nombre négatif ($value)";
  @override
  String runNotFinite(String fn) => "$fn : la valeur n'est pas un nombre fini";
  @override
  String get runLenString => 'len attend une chaîne';
  @override
  String get runRandomInt => 'random attend un entier';
  @override
  String runRandomPositive(int n) => 'random(n) attend n supérieur à 0, or n = $n';
  @override
  String runNotSimulated(String fn) => "'$fn' n'est pas encore disponible dans la simulation";
  @override
  String runTooManySteps(int n) =>
      'plus de $n étapes : le programme contient peut-être une boucle infinie '
      '(la condition ne devient-elle jamais fausse ?)';
  @override
  String runConditionValue(String value) =>
      'la condition doit être vraie ou fausse, or elle vaut $value';
  @override
  String runMustBeInteger(String what, String value) =>
      '$what doit être un entier (valeur obtenue : $value)';
  @override
  String get runStepZero => 'le pas de la boucle ne peut pas être 0';
  @override
  String get runArduinoNotSimulated =>
      'les blocs Arduino ne sont pas encore simulés : générez le sketch';
  @override
  String runCounterInteger(String name) => "le compteur '$name' doit rester entier";
  @override
  String runInvalidExpr(String text) => "expression non valide : '$text'";
  @override
  String get runInputMissing => 'saisie manquante';
  @override
  String runFinished(int steps) => 'Programme terminé ($steps étapes)';
  @override
  String runErrorLine(String message) => 'Erreur : $message';

  // ================================================================ diagramma
  @override
  String get flowStart => 'Début';
  @override
  String get flowEnd => 'Fin';
  @override
  String get edgeTrue => 'vrai';
  @override
  String get edgeFalse => 'faux';
  @override
  String get flowRepeat => 'répéter';
  @override
  String labelRead(String variable) => 'Lire $variable';
  @override
  String labelWrite(String text) => 'Écrire $text';
  @override
  String labelFor(String variable, String from, String to, String? step) =>
      '$variable de $from à $to${step == null ? '' : ', pas $step'}';
  @override
  String get kindAlgorithm => 'Algorithme';
  @override
  String get kindArduino => 'Arduino';
  @override
  String get pinModeOutput => 'sortie';
  @override
  String get pinModeInput => 'entrée';
  @override
  String get pinModeInputPullup => 'entrée avec pull-up';
  @override
  String get pinModeAnalogInput => 'entrée analogique';

  // ================================================================ codice generato
  @override
  String get codeGenerated => 'Code généré par DB Flow';
  @override
  String codeGeneratedFor(String board) => 'Code généré par DB Flow pour $board';
  @override
  String get codeConnections => 'Branchements :';
  @override
  String codeInvalidExpr(String text) => 'ERREUR : expression non valide : $text';
  @override
  String codeArduinoOnly(String label) => '$label : disponible uniquement sur Arduino';
  @override
  String inputPrompt(String variable) => 'Saisir $variable : ';
  @override
  String get codeAnswerVar => 'reponse';
  @override
  String get codeConcatUnsupported =>
      'concaténation de texte : utilisez un bloc Écrire ou une affectation';
  @override
  String get codeLanguagePseudo => 'Pseudo-code';
  @override
  String pAlgorithm(String name) => 'ALGORITHME $name';
  @override
  String get pBegin => 'DÉBUT';
  @override
  String get pEnd => 'FIN';
  @override
  String pDeclare(String name, String type) => 'DÉCLARER $name : ${type.toUpperCase()}';
  @override
  String pRead(String variable) => 'LIRE $variable';
  @override
  String pWrite(String text) => 'ÉCRIRE $text';
  @override
  String pIf(String cond) => 'SI $cond ALORS';
  @override
  String get pElse => 'SINON';
  @override
  String get pEndIf => 'FIN SI';
  @override
  String pWhile(String cond) => 'TANT QUE $cond FAIRE';
  @override
  String get pEndWhile => 'FIN TANT QUE';
  @override
  String get pRepeat => 'RÉPÉTER';
  @override
  String pRepeatWhile(String cond) => 'TANT QUE $cond';
  @override
  String pFor(String variable, String from, String to, String? step) =>
      'POUR $variable DE $from À $to${step == null ? '' : ' PAS $step'} FAIRE';
  @override
  String get pEndFor => 'FIN POUR';
  @override
  String pSketch(String name, String board) => 'SKETCH $name ($board)';
  @override
  String pPin(String name, String pin, String mode) => 'BROCHE $name = $pin ($mode)';
  @override
  String get pSetup => 'SETUP';
  @override
  String get pEndSetup => 'FIN SETUP';
  @override
  String get pLoop => 'LOOP (répéter indéfiniment)';
  @override
  String get pEndLoop => 'FIN LOOP';

  // ================================================================ interfaccia: comuni
  @override
  String get cancel => 'Annuler';
  @override
  String get undo => 'Annuler';
  @override
  String get redo => 'Rétablir';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Supprimer';
  @override
  String get share => 'Partager';
  @override
  String get saveAs => 'Enregistrer sous…';
  @override
  String get saveFlowFile => 'Enregistrer le fichier .flow…';
  @override
  String get saveExercise => 'Enregistrer comme exercice…';
  @override
  String get more => 'Plus';
  @override
  String get name => 'Nom';
  @override
  String get create => 'Créer';
  @override
  String get insert => 'Insérer';
  @override
  String get save => 'Enregistrer';
  @override
  String get add => 'Ajouter';
  @override
  String get edit => 'Modifier';
  @override
  String get run => 'Exécuter';
  @override
  String get pin => 'Broche';
  @override
  String get pinsAndBoard => 'Broches et carte';
  @override
  String get code => 'Code';
  @override
  String get info => 'Informations';
  @override
  String get theme => 'Thème';
  @override
  String get themeSystem => "Comme l'appareil";
  @override
  String get themeLight => 'Clair';
  @override
  String get themeDark => 'Sombre';

  // ================================================================ home
  @override
  String get newDiagram => 'Nouvel organigramme';
  @override
  String get myDiagrams => 'Mes organigrammes';
  @override
  String get noDiagrams => 'Aucun organigramme';
  @override
  String get noDiagramsHint => 'Créez-en un nouveau ou partez d\'un exemple.';
  @override
  String get damagedFile => 'Fichier endommagé';
  @override
  String modified(String date) => 'Modifié : $date';
  @override
  String get examples => 'Exemples';
  @override
  String get examplesArduino => 'Exemples Arduino';
  @override
  String get opensCopy => 'Ouvre une copie modifiable';
  @override
  String get openFlowFile => 'Ouvrir un fichier .flow';
  @override
  String openFailed(String message) => "Impossible d'ouvrir : $message";
  @override
  String importFailed(String message) => "Impossible d'ouvrir le fichier : $message";
  @override
  String get importNotFlow =>
      "Impossible d'ouvrir le fichier : ce n'est pas un organigramme DB Flow";
  @override
  String shareFailed(String error) => 'Échec du partage : $error';
  @override
  String get deleteTitle => "Supprimer l'organigramme ?";
  @override
  String deleteBody(String name) => '« $name » sera supprimé de cet appareil.';
  @override
  String get hintNameArduino => 'ex. Feu tricolore';
  @override
  String get hintNameAlgorithm => 'ex. Somme de deux nombres';
  @override
  String get newArduinoHint =>
      "L'organigramme aura une partie setup() et une partie loop(). "
      'Configurez les branchements avec le bouton « $pin ».';

  // ================================================================ editor
  @override
  String saveFailed(String error) => "Échec de l'enregistrement : $error";
  @override
  String get blockDeleted => 'Bloc supprimé';
  @override
  String get blockDeletedWithContent => 'Bloc supprimé avec son contenu';
  @override
  String get diagramName => "Nom de l'organigramme";
  @override
  String fixBeforeRun(int count) => count == 1
      ? "Corrigez d'abord le bloc en rouge, puis vous pourrez exécuter le programme."
      : "Corrigez d'abord les $count problèmes signalés en rouge.";
  @override
  String operationFailed(String error) => "Échec de l'opération : $error";
  @override
  String get insertBlock => 'Insérer un bloc';
  @override
  String pinIssues(int count) => count == 1
      ? '$pinsAndBoard : 1 problème à corriger'
      : '$pinsAndBoard : $count problèmes à corriger';
  @override
  String blockIssues(int count) => count == 1
      ? '1 problème : touchez le bloc en rouge pour le voir'
      : '$count problèmes : touchez les blocs en rouge pour les voir';
  @override
  String get backToEdit => 'Revenir à la modification';
  @override
  String get centerDiagram => "Centrer l'organigramme";
  @override
  String get shareFlowFile => 'Partager le fichier .flow';
  @override
  String get exportPng => 'Exporter en image PNG';
  @override
  String get exportSvg => 'Exporter en SVG';
  @override
  String get exportPdf => 'Exporter en PDF';
  @override
  String get duplicate => 'Dupliquer';
  @override
  String get moveUp => 'Monter';
  @override
  String get moveDown => 'Descendre';
  @override
  String get arduinoSketch => 'Sketch Arduino';
  @override
  String get chooseSketchFolder => 'Choisissez où créer le dossier du croquis';
  @override
  String get arduinoSketchFile => 'Croquis Arduino (.ino)';
  @override
  String get arduinoSketchHelp => "À ouvrir avec l'IDE Arduino pour le téléverser sur la carte";
  @override
  String sketchSaved(String path) => 'Croquis enregistré dans $path';
  @override
  String wiringLine(String name, String pin, String mode) => '$name : broche $pin, $mode';
  @override
  String get pdfWiring => 'Branchements';
  @override
  String get pdfCode => 'Code';
  @override
  String get defaultFileName => 'organigramme';
  @override
  String get blockDeclare => 'Déclarer une variable';
  @override
  String get blockAssign => 'Affectation';
  @override
  String get blockInput => 'Lire (entrée)';
  @override
  String get blockOutput => 'Écrire (sortie)';
  @override
  String get blockIf => 'Si … alors … sinon';
  @override
  String get blockWhile => 'Tant que (while)';
  @override
  String get blockDoWhile => 'Répéter … tant que (do-while)';
  @override
  String get blockFor => 'Pour (for)';
  @override
  String get blockComment => 'Commentaire';
  @override
  String get blockDigitalRead => 'digitalRead (entrée numérique)';
  @override
  String get blockAnalogRead => 'analogRead (entrée analogique)';
  @override
  String get blockDigitalWrite => 'digitalWrite (sortie numérique)';
  @override
  String get blockAnalogWrite => 'analogWrite (sortie PWM)';
  @override
  String get blockDelay => 'delay (attente)';
  @override
  String get fieldVarToModify => 'Variable à modifier';
  @override
  String get fieldNewValue => 'Nouvelle valeur';
  @override
  String get hintNewValue => 'ex. a + 1';
  @override
  String get fieldVarToRead => 'Variable où lire';
  @override
  String get fieldWhatToWrite => 'Ce qu\'il faut écrire';
  @override
  String get hintWrite => 'ex. "Résultat : " & r';
  @override
  String get fieldCondition => 'Condition';
  @override
  String get hintCondition => 'ex. a > b';
  @override
  String get fieldCounter => 'Compteur (variable entière)';
  @override
  String get fieldFrom => 'De';
  @override
  String get fieldTo => 'À (inclus)';
  @override
  String get fieldStep => 'Pas';
  @override
  String get hintFrom => 'ex. 1';
  @override
  String get hintTo => 'ex. n';
  @override
  String get fieldCommentText => 'Texte du commentaire';
  @override
  String get fieldValue => 'Valeur';
  @override
  String get hintHighLow => 'HIGH ou LOW';
  @override
  String get fieldPwmValue => 'Valeur (0–255)';
  @override
  String get hintPwm => 'ex. 128';
  @override
  String get fieldDelayMs => 'Attente en millisecondes';
  @override
  String get hintDelay => 'ex. 500 (une demi-seconde)';
  @override
  String get fieldReadTarget => 'Variable qui reçoit la lecture';
  @override
  String get readsDigital => 'Lit HIGH (1) ou LOW (0).';
  @override
  String get readsAnalog => 'Lit une valeur de 0 (0 V) à 1023 (5 V).';
  @override
  String varExists(String name) => "une variable '$name' existe déjà";
  @override
  String get fieldVarName => 'Nom de la variable';
  @override
  String get hintVarName => 'ex. somme';
  @override
  String get fieldType => 'Type';
  @override
  String get noIntegerVariables =>
      "Aucune variable entière : ajoutez d'abord un bloc « $blockDeclare ».";
  @override
  String get noVariables => "Aucune variable : ajoutez d'abord un bloc « $blockDeclare ».";
  @override
  String notDeclared(String name) => '$name (non déclarée)';
  @override
  String get noInputPins => 'Aucune entrée configurée';
  @override
  String get noAnalogPins => 'Aucune entrée analogique configurée';
  @override
  String get noOutputPins => 'Aucune broche de sortie configurée';
  @override
  String get addFromPins => ' : ajoutez-en une dans « $pinsAndBoard » (bouton $pin en haut).';
  @override
  String get noPwmTag => ' · sans PWM';
  @override
  String pwmOn(String board, String pins) => 'PWM sur $board : $pins';
  @override
  String column(int column, String message) => 'Colonne $column : $message';

  // ================================================================ esecuzione (pannello)
  @override
  String get variables => 'Variables';
  @override
  String get console => 'Console';
  @override
  String get restart => 'Recommencer';
  @override
  String get pause => 'Pause';
  @override
  String get oneStep => 'Une étape';
  @override
  String get toEnd => "Jusqu'à la fin";
  @override
  String get statusReady => 'Prêt : appuyez sur ▶ ou ⏭';
  @override
  String statusPaused(int steps) => 'En pause · étape $steps';
  @override
  String statusRunning(int steps) => 'En cours · étape $steps';
  @override
  String statusWaiting(String variable, String type) =>
      'Saisissez une valeur pour $variable ($type)';
  @override
  String statusFinished(int steps) => 'Terminé en $steps étapes';
  @override
  String get statusFailed => "Erreur pendant l'exécution";
  @override
  String condition(bool value) => 'condition : ${value ? 'vraie' : 'fausse'}';
  @override
  String get send => 'Envoyer';
  @override
  String get noVariablesYet => "Aucune variable déclarée pour l'instant";
  @override
  String get consoleEmpty => "Ce que le programme écrit s'affiche ici";

  // ================================================================ codice
  @override
  String get codeHasErrors =>
      "L'organigramme contient des erreurs : le code risque de ne pas fonctionner.";
  @override
  String get copy => 'Copier';
  @override
  String get codeCopied => 'Code copié';

  // ================================================================ pin e scheda
  @override
  String get addPin => 'Ajouter une broche';
  @override
  String get board => 'Carte';
  @override
  String get serialBaud => 'Série (bauds)';
  @override
  String get toFix => 'À corriger';
  @override
  String get usedNotConfigured => "Utilisées dans l'organigramme mais non configurées";
  @override
  String suggestionTitle(String name, String mode, String? pin) =>
      '$name → $mode${pin == null ? '' : ' (broche $pin)'}';
  @override
  String usedIn(String where) => 'dans : $where';
  @override
  String get wiring => 'Branchements';
  @override
  String get tapPinHint => 'Touchez une broche sur le schéma pour la configurer.';
  @override
  String get configuredPins => 'Broches configurées';
  @override
  String get noPins => 'Aucune broche';
  @override
  String get noPinsHint =>
      'Donnez un nom à chaque branchement (ex. LED sur la broche 13) : '
      'dans les blocs, vous utiliserez ce nom.';
  @override
  String get pwmTag => 'PWM';
  @override
  String get onBoardLed => 'LED de la carte';
  @override
  String removePin(String name) => 'Retirer $name';
  @override
  String get generatedSetup => 'setup() généré';
  @override
  String get setupNote =>
      'Les pinMode et Serial.begin se mettent à jour automatiquement. Les blocs ajoutés dans '
      "la partie setup() de l'organigramme sont exécutés juste après.";
  @override
  String get pinNameExists => 'une broche porte déjà ce nom';
  @override
  String get variableNameExists => 'une variable porte déjà ce nom';
  @override
  String get analogTag => 'analogique';
  @override
  String get serialTag => 'série';
  @override
  String pinOption(String pin, List<String> tags) =>
      tags.isEmpty ? 'broche $pin' : 'broche $pin  ·  ${tags.join(', ')}';
  @override
  String get newPin => 'Nouvelle broche';
  @override
  String get editPin => 'Modifier la broche';
  @override
  String get hintPinName => 'ex. LED, BOUTON, CAPTEUR';
  @override
  String get mode => 'Mode';
  @override
  String get pwmNeeded =>
      "Une broche PWM (~) est nécessaire : l'organigramme l'utilise avec analogWrite.";
  @override
  String get pullupNote =>
      'Avec le pull-up, la broche lit HIGH au repos et LOW quand le bouton '
      '(relié à GND) est appuyé.';
  @override
  String get microcontroller => 'microcontrôleur';
  @override
  String boardSemantics(String board) => 'Schéma : $board. Touchez une broche pour la configurer';

  // ================================================================ informazioni
  @override
  String version(String v) => 'Version $v';
  @override
  String get aboutDescription =>
      "Éditeur d'organigrammes structurés et exécutables, pour enseignants et élèves : "
      "on construit l'algorithme avec des blocs, on l'exécute pas à pas et on en génère le "
      'code (pseudo-code, Python, C, Arduino).';
  @override
  String madeBy(String author) => 'Réalisé par le $author.';
  @override
  String get privacy => 'Confidentialité';
  @override
  String get noAccount => 'Aucun compte';
  @override
  String get noAds => 'Aucune publicité';
  @override
  String get noDataCollection => 'Aucune collecte de données';
  @override
  String get dataStaysOnDevice => "Les organigrammes restent sur l'appareil";
  @override
  String get privacySummary =>
      "L'application ne contient aucun outil d'analyse, de publicité ou de signalement des "
      "erreurs et n'utilise pas internet. Les fichiers se partagent directement entre "
      'personnes (AirDrop, Mail, Fichiers…).';
  @override
  String get privacyPolicy => 'Politique de confidentialité';
  @override
  String get guideBlocks => 'Guide rapide : les blocs';
  @override
  String get guideExpressions => 'Guide rapide : les expressions';
  @override
  List<(String, String)> get guideBlockItems => const [
    ('Début / Fin', "Là où l'algorithme commence et se termine."),
    ('Déclaration', 'Crée une variable : entier, réel, chaîne, booléen.'),
    ('Affectation', 'Calcule une valeur et la range dans une variable : a ← b + 1.'),
    ('Lire / Écrire', 'Entrée et sortie : clavier et console (liaison série sur Arduino).'),
    ('Décision', 'Si, Tant que, Répéter…tant que : la condition est vraie ou fausse.'),
    ('Boucle Pour', "Un compteur va d'une valeur à une autre, avec un pas."),
    ('Broches Arduino', 'digitalRead/Write, analogRead/Write : entrées et sorties.'),
    ('delay', 'Attente en millisecondes (Arduino).'),
  ];
  @override
  List<(String, String)> get guideExpressionItems => const [
    ('Nombres et texte', '12   3.14   "bonjour"   vrai   faux'),
    ('Arithmétique', '+  -  *  /  %   (7 / 2 = 3.5, 7 % 2 = 1)'),
    ('Comparaisons', '==  !=  <  <=  >  >='),
    ('Logique', 'and  or  not   (aussi &&  ||  !)'),
    ('Joindre du texte', '"Total : " & t'),
  ];
  @override
  String get availableFunctions => 'Fonctions disponibles :';
  @override
  String get license => 'Licence';
  @override
  String licenseText(String license) =>
      'Code source public et vérifiable (source-available) sous licence $license : '
      'utilisation libre à des fins non commerciales.';
  @override
  String get componentLicenses => 'Licences des composants utilisés';

  // ================================================================ informativa privacy
  @override
  String get privacyUpdated => 'Dernière mise à jour : 21 novembre 2026';
  @override
  List<(String, List<String>)> privacySections(
    String app,
    String author,
    String license,
    String contact,
  ) => [
    (
      'En bref',
      [
        '$app ne collecte, ne transmet et ne vend aucune donnée personnelle.',
        "Aucun compte n'est nécessaire et il n'y a aucune inscription.",
        "L'application ne contient pas de publicité.",
        'Les organigrammes restent sur votre appareil.',
      ],
    ),
    (
      'Qui est responsable',
      [
        "$app est réalisée par le $author. Comme l'application ne collecte aucune donnée "
            "personnelle, aucune donnée de l'utilisateur ne parvient au développeur.",
      ],
    ),
    (
      "Données utilisées par l'application",
      [
        "Uniquement les organigrammes que vous créez, enregistrés dans la mémoire de l'application sur l'appareil, et le choix du thème (clair ou sombre). Sur iPhone et iPad, les organigrammes sont aussi visibles dans l'app Fichiers, dans le dossier de $app.",
        "L'application n'utilise ni noms, ni e-mails, ni position, ni photos, ni contacts, ni microphone, ni appareil photo, ni identifiants de l'appareil ou publicitaires.",
        "Si la sauvegarde de l'appareil est activée (iCloud, Google ou Time Machine sur Mac), le système d'exploitation peut inclure les organigrammes dans la sauvegarde, comme les documents de toute autre application. C'est un service du système, géré dans les réglages de l'appareil.",
      ],
    ),
    (
      'Connexion à internet',
      [
        "L'application fonctionne sans connexion et n'envoie rien sur le réseau : aucun "
            'serveur, aucun service externe.',
      ],
    ),
    (
      'Services tiers',
      [
        "Aucun outil d'analyse ou de statistiques, de publicité ou de signalement automatique "
            "des erreurs. Les composants utilisés pour construire l'application sont listés "
            'dans « $componentLicenses ».',
      ],
    ),
    (
      'Partage des fichiers',
      [
        "Un organigramme, une image, un PDF ou le code ne sortent de l'application que lorsque vous choisissez « Partager », « Exporter » ou, sur ordinateur, « $saveAs ». Vous décidez à qui ou où l'envoyer (AirDrop, Mail, Fichiers…) ou dans quel dossier l'enregistrer. À partir de ce moment, ce sont les règles de l'application ou du service choisi qui s'appliquent.",
        "Un fichier .flow reçu s'ouvre avec « $openFlowFile » ou en le touchant dans Mail, Fichiers ou le Finder : l'application ne lit que ce fichier et en enregistre une copie parmi vos organigrammes.",
      ],
    ),
    (
      "À l'école",
      [
        "L'application est conçue pour les enseignants et les élèves et ne demande aucune "
            "donnée personnelle. Conseil : n'insérez pas de données personnelles dans les noms "
            'des organigrammes et dans les textes (par exemple les noms et prénoms des '
            'élèves), surtout si les fichiers sont partagés.',
      ],
    ),
    (
      'Effacer les données',
      [
        "Vous pouvez supprimer un organigramme depuis la liste de l'écran d'accueil. Si vous désinstallez l'application sur iPhone, iPad, Android ou Windows, le système supprime tous les organigrammes qui y sont enregistrés. Sur Mac, si vous retirez l'application du dossier Applications, les organigrammes restent dans son dossier de données (Bibliothèque › Containers › $app), que vous pouvez supprimer. Les copies que vous avez partagées ou exportées ailleurs restent dans tous les cas.",
      ],
    ),
    (
      'Vérifiabilité',
      [
        'Le code de $app est public (source-available, licence $license) : chacun peut '
            "vérifier que l'application se comporte comme décrit ici.",
      ],
    ),
    (
      'Modifications et contacts',
      [
        'Si cette politique change, la nouvelle version figurera sur cette page avec la date '
            'mise à jour. Pour toute question : $contact.',
      ],
    ),
  ];

  // ================================================================ componenti e scelta del pin
  @override
  String get componentLed => 'LED';
  @override
  String get componentButton => 'Bouton-poussoir';
  @override
  String get componentPotentiometer => 'Potentiomètre';
  @override
  String get componentOther => 'Autre';
  @override
  String get whatToConnect => 'Que branchez-vous ?';
  @override
  String get digitalPinsTitle => 'Broches numériques';
  @override
  String get analogPinsTitle => 'Broches analogiques';
  @override
  String pinSwapNotice(String other, String otherNewPin) =>
      'Cette broche est utilisée par $other : elles seront échangées, $other passe sur la broche $otherNewPin.';
  @override
  String pinMoveNotice(String other, String newPin) =>
      'Cette broche est utilisée par $other, qui sera déplacé sur la broche $newPin.';
  @override
  String pinCannotSwap(String other, String pin) =>
      'Cette broche est utilisée par $other, qui ne peut pas aller sur la broche $pin : choisissez une autre broche.';
  @override
  String pinCannotMove(String other) =>
      'Cette broche est utilisée par $other et aucune autre broche libre ne convient : choisissez une autre broche.';
  @override
  String pinMoved(String name, String pin) => '$name déplacé sur la broche $pin';

  // ================================================================ esercizi

  @override
  String get exercise => 'Exercice';
  @override
  String get exercises => 'Exercices';
  @override
  String get exerciseCreate => 'Créer un exercice';
  @override
  String get exerciseEdit => "Modifier l'exercice";
  @override
  String get exerciseText => 'Consigne';
  @override
  String get exerciseTextHint =>
      "Que doit faire l'organigramme ? Précisez aussi ce qu'il doit afficher.";
  @override
  String get testCases => 'Cas de test';
  @override
  String testCase(int n) => 'Cas $n';
  @override
  String get hiddenCase => 'Cas caché';
  @override
  String get caseInputs => "Données d'entrée";
  @override
  String get caseInputsHint => "Une valeur par ligne, dans l'ordre de lecture";
  @override
  String get caseExpected => 'Sortie attendue';
  @override
  String get caseExpectedHint => 'Une ligne pour chaque valeur affichée';
  @override
  String get caseActual => 'Sortie obtenue';
  @override
  String get caseHidden => 'Caché aux élèves';
  @override
  String get addCase => 'Ajouter un cas';
  @override
  String get removeCase => 'Supprimer le cas';
  @override
  String get fillFromDiagram => "Calculer depuis l'organigramme";
  @override
  String get fillFromDiagramHelp =>
      "Exécute l'organigramme avec les données de chaque cas et copie sa sortie comme sortie attendue.";
  @override
  String filledCases(int n) =>
      n == 1 ? 'Sortie calculée pour 1 cas' : 'Sortie calculée pour $n cas';
  @override
  String fillProblem(int n, String problem) => 'Cas $n : $problem';
  @override
  String get removeExercise => "Retirer l'exercice";
  @override
  String get removeExerciseBody =>
      "La consigne et les cas de test seront retirés. L'organigramme reste.";
  @override
  String get remove => 'Retirer';
  @override
  String get shareExercise => 'Partager comme exercice';
  @override
  String get shareExerciseHelp =>
      "Sans votre solution : l'élève part d'un organigramme vide et ne peut pas modifier la consigne ni les cas.";
  @override
  String get verify => 'Vérifier';
  @override
  String get verifyFixFirst => "Corrigez d'abord les erreurs signalées dans l'organigramme.";
  @override
  String get verifyAllPassed => 'Tous les cas sont réussis !';
  @override
  String verifyPassed(int ok, int total) =>
      ok <= 1 ? '$ok cas réussi sur $total' : '$ok cas réussis sur $total';
  @override
  String get verifyResults => 'Résultat de la vérification';
  @override
  String get casePassed => 'réussi';
  @override
  String get caseFailed => 'échoué';
  @override
  String get outcomeWrongOutput => 'La sortie ne correspond pas à celle attendue.';
  @override
  String get outcomeMissingInput =>
      "L'organigramme demande plus de données que le cas n'en fournit.";
  @override
  String get outcomeUnusedInput => "L'organigramme se termine sans lire toutes les données du cas.";
  @override
  String outcomeBadInput(String message) => 'Une donnée ne convient pas : $message';
  @override
  String outcomeError(String message) => 'Erreur : $message';
  @override
  String get noOutput => '(aucune sortie)';
  @override
  String get noInputs => '(aucune)';
  @override
  String get exerciseLocked =>
      'Exercice reçu : la consigne et les cas de test ne peuvent pas être modifiés.';
  @override
  String hiddenCasesCount(int n) => n == 1 ? 'plus 1 cas caché' : 'plus $n cas cachés';
  @override
  String get noCases => 'Aucun cas de test : ajoutez-en au moins un pour pouvoir vérifier.';
  @override
  String get showTask => 'Lire la consigne';

  // ================================================================ simulazione Arduino

  @override
  String get whatPin => 'la broche';
  @override
  String get whatValue => 'la valeur';
  @override
  String runTooManyStepsLoop(int n) =>
      'plus de $n pas en un seul tour de loop() : il y a peut-être une boucle infinie (la condition ne devient-elle jamais fausse ?)';
  @override
  String runDelayNegative(int ms) => 'delay ne peut pas être négatif, or sa valeur est $ms';
  @override
  String runPwmRange(int value, int max) =>
      'analogWrite accepte des valeurs de 0 à $max, or la valeur est $value';
  @override
  String runPinNotOnBoard(int pin, String board) =>
      "la broche $pin n'existe pas sur la carte $board";
  @override
  String runAnalogReadPin(String pin) =>
      'analogRead ne fonctionne que sur les entrées analogiques (A0…), pas sur la broche $pin';
  @override
  String get circuit => 'Circuit';
  @override
  String simLoop(int n) => 'tour $n de loop()';
  @override
  String get toLoopEnd => "Jusqu'à la fin de ce tour de loop()";
  @override
  String get ledOn => 'allumée';
  @override
  String get ledOff => 'éteinte';
  @override
  String get pressed => 'appuyé';
  @override
  String get released => 'relâché';
  @override
  String get tapToPress => 'Touchez pour appuyer ou relâcher';
  @override
  String noSimPins(String pinsAndBoard) =>
      'Aucune broche configurée : ajoutez-les dans « $pinsAndBoard » pour les voir ici.';
  @override
  String get simNote =>
      'Simulation : la durée des blocs est approximative ; les delay durent réellement en exécution automatique.';
}
