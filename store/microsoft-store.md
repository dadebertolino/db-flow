# DB Flow — scheda Microsoft Store (Windows)

Testi e risposte da copiare in Partner Center. Ogni campo è in un blocco
`text`: `test/microsoft_store_texts_test.dart` controlla i limiti di Microsoft e
le parole vietate dallo standard privacy (niente «open source», «GDPR», né un
pubblico di minori: il frame è adulto, «per insegnanti e chi impara a
programmare»).

Limiti: descrizione 10.000 caratteri; funzionalità del prodotto fino a 20 righe
da 200 caratteri; termini di ricerca fino a 7, ciascuno di 30 caratteri al
massimo e 21 parole in tutto. Le descrizioni sono quelle di
[play-store.md](play-store.md), con Windows al posto di Android.

## Dati comuni (non tradotti)

| Campo | Valore |
|---|---|
| Nome prenotato | DB Flow |
| Package/Identity/Name | `DavideBertolino.DBFlow` |
| Package/Identity/Publisher | `CN=D690F6A5-53AB-468E-9581-1266A41A362B` |
| PublisherDisplayName | Davide Bertolino |
| Store ID | `9P8H3SD0HM5V` (link dopo la pubblicazione: https://apps.microsoft.com/detail/9P8H3SD0HM5V) |
| Pacchetto | `db_flow.msix` (x64), dalla CI (artefatto `db-flow-msix`) o da `dart run msix:create --store` sul PC |

L'identità è anche in `msix_config` di `pubspec.yaml`: non è un segreto,
compare in ogni pacchetto pubblicato.

## Invio (Submission)

### Prezzi e disponibilità
| Campo | Valore |
|---|---|
| Mercati | Tutti |
| Visibilità | Pubblica |
| Prezzo | Gratuita |
| Versione di prova / acquisti nell'app | No |

### Proprietà
| Campo | Valore |
|---|---|
| Categoria | Istruzione (Education); sottocategoria, se richiesta: Strumenti didattici / Reference (la più vicina) |
| Informativa sulla privacy | https://www.davidebertolino.it/db-flow-privacy/ |
| Sito web | https://www.davidebertolino.it/db-flow/ |
| Contatto per il supporto | info@davidebertolino.it |
| «Il prodotto accede, raccoglie o trasmette informazioni personali?» | **No** |
| Requisiti di sistema | Tastiera e mouse consigliati; tocco supportato. Nessun requisito minimo particolare |
| Dichiarazioni sul prodotto | Nessuna (non è un gioco, nessun DLC, nessuna dipendenza esterna). Lasciare abilitato il backup e il trasferimento dei dati da parte di Windows, se proposto |

### Classificazioni per età (IARC)
Categoria «App» (non gioco, non browser). Tutte le risposte **No**: nessuna
violenza, nessun contenuto sessuale, nessun linguaggio volgare, nessuna
interazione tra utenti, nessuna condivisione della posizione, nessun acquisto
digitale, nessun contenuto generato e condiviso online. Risultato atteso: 3+ /
Tutti.

### Pacchetti
Caricare `db_flow.msix`. Famiglie di dispositivi: solo **Windows Desktop**.

### Note per la certificazione (in inglese, le legge il revisore)

```text
DB Flow is an offline editor for structured, runnable flowcharts, for teachers and people learning to program. No sign-in, no network access, no in-app purchases, no data collection.

How to try it:
1. On the home screen, open an item under "Examples" (e.g. "Prime number"): an editable copy is created.
2. Click Run, then "One step" to execute block by block; variables and console are shown.
3. Menu (…) > Code shows the generated pseudocode, Python and C.
4. Arduino examples (e.g. "Dimmer with potentiometer"): "Pins and board" shows an interactive board; Run simulates the circuit (LED, buttons, potentiometer). No hardware or connection is needed.
5. "Exercises": open one (e.g. "Largest of three numbers"), build the flowchart and click "Check" to compare its output with the expected one.

Flowcharts are stored only in the app's local data folder, which Windows removes when the app is uninstalled. They can be saved as .flow files with "Save as" and opened again by double-clicking them. The app declares only the runFullTrust capability required by desktop apps.
```

## it — Italiano

### Descrizione
```text
DB Flow è un editor di diagrammi di flusso strutturati che si eseguono davvero. Si costruisce l'algoritmo a blocchi, lo si segue passo passo e se ne ottiene il codice. È pensata per insegnanti di informatica, tecnologia ed elettronica e per chi impara a programmare.

COSTRUISCI
• Blocchi standard: dichiarazioni, lettura e scrittura, assegnazioni, se/altrimenti, cicli while, do-while e for, commenti.
• Si fa clic su «+» nel punto giusto e si sceglie il blocco: il diagramma si dispone da solo ed è sempre ben strutturato.
• Gli errori (variabili non dichiarate, tipi sbagliati) sono segnalati prima di eseguire.
• Annulla e ripeti, salvataggio automatico, scorciatoie da tastiera (Ctrl+Z, Ctrl+Y, Ctrl+D, Canc).

ESEGUI
• Esecuzione passo passo, con il blocco attivo evidenziato, le variabili, la console e l'inserimento dei dati.
• Velocità regolabile, oppure fino alla fine.

GENERA IL CODICE
• Pseudocodice, Python e C, pronti da copiare.
• Esportazione del diagramma in PNG, SVG e PDF; file .flow da salvare e riaprire con un doppio clic.

ARDUINO
• Diagrammi con setup() e loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay e millis().
• «Pin e scheda»: disegno interattivo di Arduino Uno, Nano, Pro Mini, Micro e Mega 2560, con LED, pulsanti e potenziometri.
• Simulazione del circuito: il LED si accende e si regola, i pulsanti si premono, i potenziometri si girano.
• Sketch .ino pronto per l'Arduino IDE.

ESERCIZI CON VERIFICA
• L'insegnante scrive la consegna e i casi di prova (anche nascosti) e la salva come file.
• Chi risolve verifica il proprio diagramma: l'output viene confrontato con quello atteso.
• 10 esercizi e 9 esempi inclusi.

PRIVACY
Nessun account, nessuna pubblicità, nessuna raccolta dati. I diagrammi restano sul computer e l'app non usa la rete. Il codice è pubblico (source-available, licenza PolyForm Noncommercial): chiunque può verificarlo.

Gratuita, per PC Windows, in italiano, inglese, francese, tedesco e spagnolo, con tema chiaro e scuro. Disponibile anche per iPhone, iPad, Mac e Android.

Realizzata dal Prof. Davide Bertolino.
```

### Funzionalità del prodotto
```text
Diagrammi di flusso a blocchi, sempre ben strutturati
Esecuzione passo passo con variabili, console e input
Codice generato in pseudocodice, Python e C
Diagrammi Arduino con simulazione del circuito e sketch .ino
Esercizi con verifica automatica dell'output
Esportazione in PNG, SVG e PDF
Nessun account, nessuna pubblicità, nessuna raccolta dati
```

### Termini di ricerca
```text
diagrammi di flusso, flowchart, algoritmi, pseudocodice, Python, Arduino, programmazione
```

## en — English

### Description
```text
DB Flow is an editor for structured flowcharts that really run. Build the algorithm from blocks, follow it step by step and get its code. It is designed for computing, technology and electronics teachers and for anyone learning to program.

BUILD
• Standard blocks: declarations, input and output, assignments, if/else, while, do-while and for loops, comments.
• Click "+" where you want a block and pick it: the flowchart lays itself out and is always well structured.
• Errors (undeclared variables, wrong types) are flagged before running.
• Undo and redo, automatic saving, keyboard shortcuts (Ctrl+Z, Ctrl+Y, Ctrl+D, Delete).

RUN
• Step-by-step execution, with the active block highlighted, variables, console and input.
• Adjustable speed, or run to the end.

GENERATE CODE
• Pseudocode, Python and C, ready to copy.
• Export the flowchart as PNG, SVG or PDF; .flow files to save and reopen with a double-click.

ARDUINO
• Flowcharts with setup() and loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay and millis().
• "Pins and board": interactive drawing of Arduino Uno, Nano, Pro Mini, Micro and Mega 2560, with LEDs, buttons and potentiometers.
• Circuit simulation: the LED lights up and dims, buttons can be pressed, potentiometers turned.
• .ino sketch ready for the Arduino IDE.

EXERCISES WITH CHECKING
• Teachers write the task and the test cases (hidden ones too) and save it as a file.
• Learners check their flowchart: its output is compared with the expected one.
• 10 exercises and 9 examples included.

PRIVACY
No account, no ads, no data collection. Flowcharts stay on the computer and the app does not use the network. The code is public (source-available, PolyForm Noncommercial licence): anyone can verify it.

Free, for Windows PCs, in English, Italian, French, German and Spanish, with light and dark themes. Also available for iPhone, iPad, Mac and Android.

Made by Prof. Davide Bertolino.
```

### Product features
```text
Block-based flowcharts that are always well structured
Step-by-step execution with variables, console and input
Generated code in pseudocode, Python and C
Arduino flowcharts with circuit simulation and .ino sketch
Exercises with automatic output checking
Export as PNG, SVG and PDF
No account, no ads, no data collection
```

### Search terms
```text
flowchart, algorithm, pseudocode, Python, Arduino, programming, computer science
```

## fr — Français

### Description
```text
DB Flow est un éditeur d'organigrammes structurés qui s'exécutent vraiment. On construit l'algorithme avec des blocs, on le suit pas à pas et on en obtient le code. L'app est pensée pour les enseignants d'informatique, de technologie et d'électronique et pour toute personne qui apprend à programmer.

CONSTRUIRE
• Blocs standard : déclarations, lecture et écriture, affectations, si/sinon, boucles tant que, répéter… tant que et pour, commentaires.
• On clique sur « + » à l'endroit voulu et on choisit le bloc : l'organigramme se dispose tout seul et reste toujours bien structuré.
• Les erreurs (variables non déclarées, types incorrects) sont signalées avant l'exécution.
• Annuler et rétablir, enregistrement automatique, raccourcis clavier (Ctrl+Z, Ctrl+Y, Ctrl+D, Suppr).

EXÉCUTER
• Exécution pas à pas, avec le bloc actif mis en évidence, les variables, la console et la saisie des données.
• Vitesse réglable, ou exécution jusqu'à la fin.

GÉNÉRER LE CODE
• Pseudo-code, Python et C, prêts à copier.
• Export de l'organigramme en PNG, SVG et PDF ; fichiers .flow à enregistrer et à rouvrir d'un double-clic.

ARDUINO
• Organigrammes avec setup() et loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay et millis().
• « Broches et carte » : dessin interactif des cartes Arduino Uno, Nano, Pro Mini, Micro et Mega 2560, avec LED, boutons et potentiomètres.
• Simulation du circuit : la LED s'allume et varie, les boutons se pressent, les potentiomètres se tournent.
• Sketch .ino prêt pour l'Arduino IDE.

EXERCICES AVEC VÉRIFICATION
• L'enseignant rédige la consigne et les cas de test (y compris cachés) et l'enregistre sous forme de fichier.
• La personne qui résout vérifie son organigramme : la sortie est comparée à celle attendue.
• 10 exercices et 9 exemples inclus.

CONFIDENTIALITÉ
Sans compte, sans publicité, sans collecte de données. Les organigrammes restent sur l'ordinateur et l'app n'utilise pas le réseau. Le code est public (source-available, licence PolyForm Noncommercial) : chacun peut le vérifier.

Gratuite, pour PC Windows, en français, anglais, italien, allemand et espagnol, avec thème clair et sombre. Disponible aussi pour iPhone, iPad, Mac et Android.

Réalisée par le Prof. Davide Bertolino.
```

### Fonctionnalités du produit
```text
Organigrammes par blocs, toujours bien structurés
Exécution pas à pas avec variables, console et saisie
Code généré en pseudo-code, Python et C
Organigrammes Arduino avec simulation du circuit et sketch .ino
Exercices avec vérification automatique de la sortie
Export en PNG, SVG et PDF
Sans compte, sans publicité, sans collecte de données
```

### Termes de recherche
```text
organigramme, algorigramme, algorithme, pseudo-code, Python, Arduino, programmation
```

## de — Deutsch

### Beschreibung
```text
DB Flow ist ein Editor für strukturierte Programmablaufpläne, die wirklich laufen. Du baust den Algorithmus aus Blöcken, verfolgst ihn Schritt für Schritt und erhältst den Code dazu. Die App richtet sich an Lehrkräfte für Informatik, Technik und Elektronik und an alle, die programmieren lernen.

BAUEN
• Standardblöcke: Deklarationen, Eingabe und Ausgabe, Zuweisungen, Wenn/Sonst, While-, Do-While- und For-Schleifen, Kommentare.
• Klicke an der gewünschten Stelle auf „+“ und wähle den Block: Der Plan ordnet sich selbst an und ist immer sauber strukturiert.
• Fehler (nicht deklarierte Variablen, falsche Typen) werden vor der Ausführung gemeldet.
• Rückgängig und Wiederholen, automatisches Speichern, Tastaturkürzel (Strg+Z, Strg+Y, Strg+D, Entf).

AUSFÜHREN
• Schrittweise Ausführung mit hervorgehobenem aktivem Block, Variablen, Konsole und Eingabe.
• Einstellbare Geschwindigkeit oder Ausführung bis zum Ende.

CODE ERZEUGEN
• Pseudocode, Python und C, bereit zum Kopieren.
• Export des Plans als PNG, SVG und PDF; .flow-Dateien zum Speichern und Öffnen per Doppelklick.

ARDUINO
• Pläne mit setup() und loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay und millis().
• „Pins und Board“: interaktive Zeichnung von Arduino Uno, Nano, Pro Mini, Micro und Mega 2560, mit LEDs, Tastern und Potentiometern.
• Schaltungssimulation: Die LED leuchtet und wird gedimmt, Taster lassen sich drücken, Potentiometer drehen.
• .ino-Sketch, fertig für die Arduino IDE.

AUFGABEN MIT ÜBERPRÜFUNG
• Lehrkräfte schreiben die Aufgabenstellung und die Testfälle (auch verdeckte) und speichern sie als Datei.
• Wer sie löst, überprüft den eigenen Plan: Die Ausgabe wird mit der erwarteten verglichen.
• 10 Aufgaben und 9 Beispiele enthalten.

DATENSCHUTZ
Kein Konto, keine Werbung, keine Datenerhebung. Die Pläne bleiben auf dem Computer und die App nutzt kein Netzwerk. Der Code ist öffentlich (source-available, Lizenz PolyForm Noncommercial): Jeder kann ihn überprüfen.

Kostenlos, für Windows-PCs, auf Deutsch, Englisch, Italienisch, Französisch und Spanisch, mit hellem und dunklem Design. Auch für iPhone, iPad, Mac und Android erhältlich.

Entwickelt von Prof. Davide Bertolino.
```

### Produktfunktionen
```text
Programmablaufpläne aus Blöcken, immer sauber strukturiert
Schrittweise Ausführung mit Variablen, Konsole und Eingabe
Erzeugter Code in Pseudocode, Python und C
Arduino-Pläne mit Schaltungssimulation und .ino-Sketch
Aufgaben mit automatischer Überprüfung der Ausgabe
Export als PNG, SVG und PDF
Kein Konto, keine Werbung, keine Datenerhebung
```

### Suchbegriffe
```text
Programmablaufplan, PAP, Algorithmus, Pseudocode, Python, Arduino, Programmieren
```

## es — Español

### Descripción
```text
DB Flow es un editor de diagramas de flujo estructurados que se ejecutan de verdad. Construyes el algoritmo con bloques, lo sigues paso a paso y obtienes su código. Está pensada para docentes de informática, tecnología y electrónica y para quien aprende a programar.

CONSTRUYE
• Bloques estándar: declaraciones, lectura y escritura, asignaciones, si/sino, bucles mientras, repetir… mientras que y para, comentarios.
• Haces clic en «+» donde quieres el bloque y lo eliges: el diagrama se ordena solo y siempre queda bien estructurado.
• Los errores (variables no declaradas, tipos incorrectos) se señalan antes de ejecutar.
• Deshacer y rehacer, guardado automático, atajos de teclado (Ctrl+Z, Ctrl+Y, Ctrl+D, Supr).

EJECUTA
• Ejecución paso a paso, con el bloque activo resaltado, las variables, la consola y la entrada de datos.
• Velocidad ajustable, o hasta el final.

GENERA EL CÓDIGO
• Pseudocódigo, Python y C, listos para copiar.
• Exportación del diagrama en PNG, SVG y PDF; archivos .flow para guardar y volver a abrir con doble clic.

ARDUINO
• Diagramas con setup() y loop(), digitalWrite, analogWrite, digitalRead, analogRead, delay y millis().
• «Pines y placa»: dibujo interactivo de Arduino Uno, Nano, Pro Mini, Micro y Mega 2560, con LED, pulsadores y potenciómetros.
• Simulación del circuito: el LED se enciende y se regula, los pulsadores se presionan, los potenciómetros se giran.
• Sketch .ino listo para el Arduino IDE.

EJERCICIOS CON COMPROBACIÓN
• El docente escribe el enunciado y los casos de prueba (también ocultos) y lo guarda como archivo.
• Quien lo resuelve comprueba su diagrama: la salida se compara con la esperada.
• 10 ejercicios y 9 ejemplos incluidos.

PRIVACIDAD
Sin cuenta, sin publicidad, sin recogida de datos. Los diagramas se quedan en el ordenador y la app no usa la red. El código es público (source-available, licencia PolyForm Noncommercial): cualquiera puede verificarlo.

Gratuita, para PC con Windows, en español, inglés, italiano, francés y alemán, con tema claro y oscuro. También disponible para iPhone, iPad, Mac y Android.

Creada por el Prof. Davide Bertolino.
```

### Características del producto
```text
Diagramas de flujo con bloques, siempre bien estructurados
Ejecución paso a paso con variables, consola y entrada de datos
Código generado en pseudocódigo, Python y C
Diagramas Arduino con simulación del circuito y sketch .ino
Ejercicios con comprobación automática de la salida
Exportación en PNG, SVG y PDF
Sin cuenta, sin publicidad, sin recogida de datos
```

### Términos de búsqueda
```text
diagrama de flujo, algoritmo, pseudocódigo, Python, Arduino, programación, informática
```
