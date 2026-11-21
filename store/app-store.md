# DB Flow — scheda App Store (iOS e macOS)

Testi da copiare in App Store Connect. Ogni campo è in un blocco `text`:
`test/store_texts_test.dart` controlla i limiti di Apple e le parole vietate
dallo standard privacy (niente «open source», «GDPR», né un pubblico di minori:
il frame è adulto, «per insegnanti e chi impara a programmare»).

Limiti: nome 30 caratteri, sottotitolo 30, testo promozionale 170,
descrizione 4000, parole chiave 100 (separate da virgole, senza spazi,
senza ripetere le parole del nome e del sottotitolo, che Apple indicizza già).

iOS e macOS hanno pagine di versione separate: descrizione, parole chiave,
testo promozionale e screenshot vanno inseriti **in entrambe** (sono uguali).
Nome e sottotitolo sono unici per l'app.

## Dati comuni (non tradotti)

| Campo | Valore |
|---|---|
| Bundle ID | `it.davidebertolino.dbFlow` |
| SKU | `dbflow` |
| Lingua principale | Italiano |
| Categoria principale | Istruzione (Education) |
| Categoria secondaria | Strumenti per sviluppatori (Developer Tools) |
| Prezzo | Gratuito, nessun acquisto in-app |
| Classificazione età | 4+ (tutte le risposte «No» / «Nessuno») |
| Copyright | `2026 Davide Bertolino` |
| URL informativa privacy | https://www.davidebertolino.it/db-flow-privacy/ |
| URL di supporto | https://www.davidebertolino.it/db-flow/ |
| URL marketing (facoltativo) | https://www.davidebertolino.it/db-flow/ |
| Privacy dell'app | «Data Not Collected» (nessun dato raccolto) |
| Crittografia | nessuna (già dichiarato con `ITSAppUsesNonExemptEncryption = false`) |
| Accesso per la revisione | non serve: nessun account |

Se il nome «DB Flow» risulta già occupato, alternative (≤ 30 caratteri):
«DB Flow – Diagrammi di flusso», «DB Flow: diagrammi a blocchi».

### Note per la revisione (in inglese, le legge il revisore)

```text
DB Flow is an offline editor for structured, runnable flowcharts, for teachers and people learning to program. No sign-in, no network access, no in-app purchases, no data collection.

How to try it:
1. On the home screen, open an item under "Examples" (e.g. "Prime number"): an editable copy is created.
2. Tap Run (play button), then "One step" to execute block by block; variables and console are shown.
3. Menu (…) > Code shows the generated pseudocode, Python and C.
4. Arduino examples (e.g. "Dimmer with potentiometer"): "Pins and board" shows an interactive board; Run simulates the circuit (LED, buttons, potentiometer). No hardware or connection is needed.
5. "Exercises": open one (e.g. "Largest of three numbers"), build the flowchart and tap "Check" to compare its output with the expected one.

Flowcharts are stored only on the device. They can be shared or saved as .flow files and opened from Files, Mail or Finder. On Mac the app is sandboxed and can access only files chosen by the user.
```

## it — Italiano

### Nome
```text
DB Flow
```

### Sottotitolo
```text
Diagrammi di flusso eseguibili
```

### Testo promozionale
```text
Costruisci l'algoritmo a blocchi, eseguilo passo passo e ottieni il codice in Python, C o Arduino. Nessun account, nessuna pubblicità, nessuna raccolta dati.
```

### Parole chiave
```text
algoritmo,pseudocodice,python,arduino,programmazione,coding,informatica,blocchi,flowchart,esercizi,C
```

### Descrizione
```text
DB Flow è un editor di diagrammi di flusso strutturati che si eseguono davvero. Si costruisce l'algoritmo a blocchi, lo si segue passo passo e se ne ottiene il codice. È pensata per insegnanti di informatica, tecnologia ed elettronica e per chi impara a programmare.

COSTRUISCI
• Blocchi standard: dichiarazioni, lettura e scrittura, assegnazioni, se/altrimenti, cicli while, do-while e for, commenti.
• Si tocca «+» nel punto giusto e si sceglie il blocco: il diagramma si dispone da solo ed è sempre ben strutturato.
• Gli errori (variabili non dichiarate, tipi sbagliati) sono segnalati prima di eseguire.
• Annulla e ripeti, salvataggio automatico, scorciatoie da tastiera su iPad e Mac.

ESEGUI
• Esecuzione passo passo, con il blocco attivo evidenziato, le variabili, la console e l'inserimento dei dati.
• Velocità regolabile, oppure fino alla fine.

GENERA IL CODICE
• Pseudocodice, Python e C, pronti da copiare.
• Esportazione del diagramma in PNG, SVG e PDF; condivisione del file .flow.

ARDUINO
• Diagrammi con setup() e loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay e millis().
• «Pin e scheda»: disegno interattivo di Arduino Uno, Nano, Pro Mini, Micro e Mega 2560, con LED, pulsanti e potenziometri.
• Simulazione del circuito: il LED si accende e si regola, i pulsanti si premono, i potenziometri si girano.
• Sketch .ino pronto per l'Arduino IDE.

ESERCIZI CON VERIFICA
• L'insegnante scrive la consegna e i casi di prova (anche nascosti) e la condivide come file.
• Chi risolve verifica il proprio diagramma: l'output viene confrontato con quello atteso.
• 10 esercizi e 9 esempi inclusi.

PRIVACY
Nessun account, nessuna pubblicità, nessuna raccolta dati. I diagrammi restano sul dispositivo e l'app non usa la rete. Il codice è pubblico (source-available, licenza PolyForm Noncommercial): chiunque può verificarlo.

Gratuita, per iPhone, iPad e Mac, in italiano, inglese, francese, tedesco e spagnolo, con tema chiaro e scuro.

Realizzata dal Prof. Davide Bertolino.
```

## en — English

### Name
```text
DB Flow
```

### Subtitle
```text
Flowcharts you can run
```

### Promotional text
```text
Build an algorithm from blocks, run it step by step and get the code in Python, C or Arduino. No account, no ads, no data collection.
```

### Keywords
```text
algorithm,pseudocode,python,arduino,programming,coding,computer science,teacher,blocks,exercises,C
```

### Description
```text
DB Flow is an editor for structured flowcharts that really run. Build the algorithm from blocks, follow it step by step and get its code. It is designed for computing, technology and electronics teachers and for anyone learning to program.

BUILD
• Standard blocks: declarations, input and output, assignments, if/else, while, do-while and for loops, comments.
• Tap "+" where you want a block and pick it: the flowchart lays itself out and is always well structured.
• Errors (undeclared variables, wrong types) are flagged before running.
• Undo and redo, automatic saving, keyboard shortcuts on iPad and Mac.

RUN
• Step-by-step execution, with the active block highlighted, variables, console and input.
• Adjustable speed, or run to the end.

GENERATE CODE
• Pseudocode, Python and C, ready to copy.
• Export the flowchart as PNG, SVG or PDF; share the .flow file.

ARDUINO
• Flowcharts with setup() and loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay and millis().
• "Pins and board": interactive drawing of Arduino Uno, Nano, Pro Mini, Micro and Mega 2560, with LEDs, buttons and potentiometers.
• Circuit simulation: the LED lights up and dims, buttons can be pressed, potentiometers turned.
• .ino sketch ready for the Arduino IDE.

EXERCISES WITH CHECKING
• Teachers write the task and the test cases (hidden ones too) and share it as a file.
• Learners check their flowchart: its output is compared with the expected one.
• 10 exercises and 9 examples included.

PRIVACY
No account, no ads, no data collection. Flowcharts stay on the device and the app does not use the network. The code is public (source-available, PolyForm Noncommercial licence): anyone can verify it.

Free, for iPhone, iPad and Mac, in English, Italian, French, German and Spanish, with light and dark themes.

Made by Prof. Davide Bertolino.
```

## fr — Français

### Nom
```text
DB Flow
```

### Sous-titre
```text
Organigrammes exécutables
```

### Texte promotionnel
```text
Construisez l'algorithme avec des blocs, exécutez-le pas à pas et obtenez le code en Python, C ou Arduino. Sans compte, sans publicité, sans collecte de données.
```

### Mots-clés
```text
algorithme,algorigramme,pseudo-code,python,arduino,programmation,informatique,NSI,SNT,exercices,C
```

### Description
```text
DB Flow est un éditeur d'organigrammes structurés qui s'exécutent vraiment. On construit l'algorithme avec des blocs, on le suit pas à pas et on en obtient le code. L'app est pensée pour les enseignants d'informatique, de technologie et d'électronique et pour toute personne qui apprend à programmer.

CONSTRUIRE
• Blocs standard : déclarations, lecture et écriture, affectations, si/sinon, boucles tant que, répéter… tant que et pour, commentaires.
• On touche « + » à l'endroit voulu et on choisit le bloc : l'organigramme se dispose tout seul et reste toujours bien structuré.
• Les erreurs (variables non déclarées, types incorrects) sont signalées avant l'exécution.
• Annuler et rétablir, enregistrement automatique, raccourcis clavier sur iPad et Mac.

EXÉCUTER
• Exécution pas à pas, avec le bloc actif mis en évidence, les variables, la console et la saisie des données.
• Vitesse réglable, ou exécution jusqu'à la fin.

GÉNÉRER LE CODE
• Pseudo-code, Python et C, prêts à copier.
• Export de l'organigramme en PNG, SVG et PDF ; partage du fichier .flow.

ARDUINO
• Organigrammes avec setup() et loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay et millis().
• « Broches et carte » : dessin interactif des cartes Arduino Uno, Nano, Pro Mini, Micro et Mega 2560, avec LED, boutons et potentiomètres.
• Simulation du circuit : la LED s'allume et varie, les boutons se pressent, les potentiomètres se tournent.
• Sketch .ino prêt pour l'Arduino IDE.

EXERCICES AVEC VÉRIFICATION
• L'enseignant rédige la consigne et les cas de test (y compris cachés) et la partage sous forme de fichier.
• La personne qui résout vérifie son organigramme : la sortie est comparée à celle attendue.
• 10 exercices et 9 exemples inclus.

CONFIDENTIALITÉ
Sans compte, sans publicité, sans collecte de données. Les organigrammes restent sur l'appareil et l'app n'utilise pas le réseau. Le code est public (source-available, licence PolyForm Noncommercial) : chacun peut le vérifier.

Gratuite, pour iPhone, iPad et Mac, en français, anglais, italien, allemand et espagnol, avec thème clair et sombre.

Réalisée par le Prof. Davide Bertolino.
```

## de — Deutsch

### Name
```text
DB Flow
```

### Untertitel
```text
Ausführbare Ablaufpläne
```

### Werbetext
```text
Baue den Algorithmus aus Blöcken, führe ihn Schritt für Schritt aus und erhalte den Code in Python, C oder Arduino. Kein Konto, keine Werbung, keine Datenerhebung.
```

### Schlüsselwörter
```text
Programmablaufplan,PAP,Algorithmus,Pseudocode,Python,Arduino,Informatik,Programmieren,Aufgaben,C
```

### Beschreibung
```text
DB Flow ist ein Editor für strukturierte Programmablaufpläne, die wirklich laufen. Du baust den Algorithmus aus Blöcken, verfolgst ihn Schritt für Schritt und erhältst den Code dazu. Die App richtet sich an Lehrkräfte für Informatik, Technik und Elektronik und an alle, die programmieren lernen.

BAUEN
• Standardblöcke: Deklarationen, Eingabe und Ausgabe, Zuweisungen, Wenn/Sonst, While-, Do-While- und For-Schleifen, Kommentare.
• Tippe an der gewünschten Stelle auf „+“ und wähle den Block: Der Plan ordnet sich selbst an und ist immer sauber strukturiert.
• Fehler (nicht deklarierte Variablen, falsche Typen) werden vor der Ausführung gemeldet.
• Rückgängig und Wiederholen, automatisches Speichern, Tastaturkürzel auf iPad und Mac.

AUSFÜHREN
• Schrittweise Ausführung mit hervorgehobenem aktivem Block, Variablen, Konsole und Eingabe.
• Einstellbare Geschwindigkeit oder Ausführung bis zum Ende.

CODE ERZEUGEN
• Pseudocode, Python und C, bereit zum Kopieren.
• Export des Plans als PNG, SVG und PDF; Teilen der .flow-Datei.

ARDUINO
• Pläne mit setup() und loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay und millis().
• „Pins und Board“: interaktive Zeichnung von Arduino Uno, Nano, Pro Mini, Micro und Mega 2560, mit LEDs, Tastern und Potentiometern.
• Schaltungssimulation: Die LED leuchtet und wird gedimmt, Taster lassen sich drücken, Potentiometer drehen.
• .ino-Sketch, fertig für die Arduino IDE.

AUFGABEN MIT ÜBERPRÜFUNG
• Lehrkräfte schreiben die Aufgabenstellung und die Testfälle (auch verdeckte) und teilen sie als Datei.
• Wer sie löst, überprüft den eigenen Plan: Die Ausgabe wird mit der erwarteten verglichen.
• 10 Aufgaben und 9 Beispiele enthalten.

DATENSCHUTZ
Kein Konto, keine Werbung, keine Datenerhebung. Die Pläne bleiben auf dem Gerät und die App nutzt kein Netzwerk. Der Code ist öffentlich (source-available, Lizenz PolyForm Noncommercial): Jeder kann ihn überprüfen.

Kostenlos, für iPhone, iPad und Mac, auf Deutsch, Englisch, Italienisch, Französisch und Spanisch, mit hellem und dunklem Design.

Entwickelt von Prof. Davide Bertolino.
```

## es — Español

### Nombre
```text
DB Flow
```

### Subtítulo
```text
Diagramas de flujo ejecutables
```

### Texto promocional
```text
Construye el algoritmo con bloques, ejecútalo paso a paso y obtén el código en Python, C o Arduino. Sin cuenta, sin publicidad, sin recogida de datos.
```

### Palabras clave
```text
algoritmo,pseudocódigo,python,arduino,programación,informática,tecnología,ejercicios,código,C
```

### Descripción
```text
DB Flow es un editor de diagramas de flujo estructurados que se ejecutan de verdad. Construyes el algoritmo con bloques, lo sigues paso a paso y obtienes su código. Está pensada para docentes de informática, tecnología y electrónica y para quien aprende a programar.

CONSTRUYE
• Bloques estándar: declaraciones, lectura y escritura, asignaciones, si/sino, bucles mientras, repetir… mientras que y para, comentarios.
• Tocas «+» donde quieres el bloque y lo eliges: el diagrama se ordena solo y siempre queda bien estructurado.
• Los errores (variables no declaradas, tipos incorrectos) se señalan antes de ejecutar.
• Deshacer y rehacer, guardado automático, atajos de teclado en iPad y Mac.

EJECUTA
• Ejecución paso a paso, con el bloque activo resaltado, las variables, la consola y la entrada de datos.
• Velocidad ajustable, o hasta el final.

GENERA EL CÓDIGO
• Pseudocódigo, Python y C, listos para copiar.
• Exportación del diagrama en PNG, SVG y PDF; envío del archivo .flow.

ARDUINO
• Diagramas con setup() y loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay y millis().
• «Pines y placa»: dibujo interactivo de Arduino Uno, Nano, Pro Mini, Micro y Mega 2560, con LED, pulsadores y potenciómetros.
• Simulación del circuito: el LED se enciende y se regula, los pulsadores se presionan, los potenciómetros se giran.
• Sketch .ino listo para el Arduino IDE.

EJERCICIOS CON COMPROBACIÓN
• El docente escribe el enunciado y los casos de prueba (también ocultos) y lo comparte como archivo.
• Quien lo resuelve comprueba su diagrama: la salida se compara con la esperada.
• 10 ejercicios y 9 ejemplos incluidos.

PRIVACIDAD
Sin cuenta, sin publicidad, sin recogida de datos. Los diagramas se quedan en el dispositivo y la app no usa la red. El código es público (source-available, licencia PolyForm Noncommercial): cualquiera puede verificarlo.

Gratuita, para iPhone, iPad y Mac, en español, inglés, italiano, francés y alemán, con tema claro y oscuro.

Creada por el Prof. Davide Bertolino.
```
