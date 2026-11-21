# DB Flow — scheda Google Play

Testi e risposte da copiare in Google Play Console. Ogni campo è in un blocco
`text`: `test/play_store_texts_test.dart` controlla i limiti di Google e le
parole vietate dallo standard privacy (niente «open source», «GDPR», né un
pubblico di minori: il frame è adulto, «per insegnanti e chi impara a
programmare»).

Limiti: nome 30 caratteri, breve descrizione 80, descrizione completa 4000.
Google Play non ha un campo per le parole chiave: le cerca nel nome e nelle
descrizioni, per questo il nome porta anche «diagrammi di flusso». Le
descrizioni sono quelle di [app-store.md](app-store.md), con Android al posto
di iPhone, iPad e Mac.

## Dati comuni (non tradotti)

| Campo | Valore |
|---|---|
| Nome del pacchetto | `it.davidebertolino.dbflow` (definitivo dopo il primo caricamento) |
| Lingua predefinita | Italiano – it-IT |
| App o gioco | App |
| Gratuita o a pagamento | Gratuita (definitivo: un'app gratuita non può diventare a pagamento) |
| Categoria | Istruzione |
| Tag | Istruzione, Programmazione/Strumenti per sviluppatori (scegliere i più vicini proposti) |
| Email di contatto | quella pubblica dello sviluppatore, come nella pagina di supporto |
| Sito web | https://www.davidebertolino.it/db-flow/ |
| Informativa privacy | https://www.davidebertolino.it/db-flow-privacy/ |

## Contenuti dell'app (questionari)

| Sezione | Risposta |
|---|---|
| Norme sulla privacy | URL dell'informativa sopra |
| Annunci | No, l'app non contiene annunci |
| Accesso all'app | Tutte le funzionalità sono disponibili senza restrizioni (nessun account) |
| Classificazione dei contenuti (IARC) | Categoria «Tutte le altre app» (Utility, produttività, comunicazione o altro); tutte le risposte «No»; nessuna interazione tra utenti, nessuna condivisione della posizione, nessun acquisto digitale |
| Pubblico di destinazione | **Solo 18 anni e più**. L'app non è progettata per i minori (non è «targeted»: si rivolge a insegnanti e adulti che imparano). Non aderire al programma Famiglie |
| App di notizie | No |
| App governativa | No |
| Funzionalità finanziarie | Nessuna |
| Salute | Nessuna funzionalità relativa alla salute |
| Sicurezza dei dati | Raccolta: **No** (l'app non raccoglie né condivide nessuno dei tipi di dati richiesti). Di conseguenza non si compilano crittografia in transito né richiesta di eliminazione |
| ID pubblicità | No, l'app non usa l'ID pubblicità (nessun SDK, nessun permesso `AD_ID`) |
| Contenuti online / app di istruzione | No: l'app non usa la rete; è uno strumento, non eroga contenuti didattici |

Permessi dell'app: nessuno nella versione di rilascio (Flutter aggiunge
`INTERNET` solo in debug). I file si aprono con il selettore di sistema e la
condivisione di Android, senza permessi di archiviazione.

### Istruzioni per la revisione (se richieste, in inglese)

Le stesse delle note per Apple in [app-store.md](app-store.md), sezione «Note per la revisione».

## Grafica

Tutto in `build/` (non in git), da rigenerare con i comandi indicati.

| Elemento | Misura | File | Comando |
|---|---|---|---|
| Icona | 512×512 PNG | `build/store/play/icon-512.png` | `flutter test tool/store/render_play_graphics_test.dart` |
| Grafica in primo piano | 1024×500 PNG, una per lingua | `build/store/play/feature-graphic-<lingua>.png` | come sopra |
| Screenshot telefono | 1080×1920, 7 per lingua | `build/screenshots/android/<lingua>/` | `bash tool/screenshots/take.sh android` |
| Screenshot tablet 7" e 10" | 1600×2560, 7 per lingua (le stesse per 7" e 10") | `build/screenshots/tablet/<lingua>/` | `bash tool/screenshots/take.sh tablet` |

Google Play rifiuta le immagini con un lato più del doppio dell'altro: per
questo l'emulatore (Pixel 10, 1080×2424) viene portato a 1080×1920 durante la
cattura.

## it — Italiano

### Nome dell'app
```text
DB Flow: diagrammi di flusso
```

### Breve descrizione
```text
Diagrammi di flusso eseguibili passo passo, con codice Python, C e Arduino.
```

### Descrizione completa
```text
DB Flow è un editor di diagrammi di flusso strutturati che si eseguono davvero. Si costruisce l'algoritmo a blocchi, lo si segue passo passo e se ne ottiene il codice. È pensata per insegnanti di informatica, tecnologia ed elettronica e per chi impara a programmare.

COSTRUISCI
• Blocchi standard: dichiarazioni, lettura e scrittura, assegnazioni, se/altrimenti, cicli while, do-while e for, commenti.
• Si tocca «+» nel punto giusto e si sceglie il blocco: il diagramma si dispone da solo ed è sempre ben strutturato.
• Gli errori (variabili non dichiarate, tipi sbagliati) sono segnalati prima di eseguire.
• Annulla e ripeti, salvataggio automatico, scorciatoie con una tastiera fisica.

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

Gratuita, per telefoni e tablet Android, in italiano, inglese, francese, tedesco e spagnolo, con tema chiaro e scuro.

Realizzata dal Prof. Davide Bertolino.
```

## en — English

### App name
```text
DB Flow: runnable flowcharts
```

### Short description
```text
Flowcharts you run step by step, with Python, C and Arduino code.
```

### Full description
```text
DB Flow is an editor for structured flowcharts that really run. Build the algorithm from blocks, follow it step by step and get its code. It is designed for computing, technology and electronics teachers and for anyone learning to program.

BUILD
• Standard blocks: declarations, input and output, assignments, if/else, while, do-while and for loops, comments.
• Tap "+" where you want a block and pick it: the flowchart lays itself out and is always well structured.
• Errors (undeclared variables, wrong types) are flagged before running.
• Undo and redo, automatic saving, shortcuts with a physical keyboard.

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

Free, for Android phones and tablets, in English, Italian, French, German and Spanish, with light and dark themes.

Made by Prof. Davide Bertolino.
```

## fr — Français

### Nom de l'application
```text
DB Flow : organigrammes
```

### Brève description
```text
Organigrammes exécutables pas à pas, avec code Python, C et Arduino.
```

### Description complète
```text
DB Flow est un éditeur d'organigrammes structurés qui s'exécutent vraiment. On construit l'algorithme avec des blocs, on le suit pas à pas et on en obtient le code. L'app est pensée pour les enseignants d'informatique, de technologie et d'électronique et pour toute personne qui apprend à programmer.

CONSTRUIRE
• Blocs standard : déclarations, lecture et écriture, affectations, si/sinon, boucles tant que, répéter… tant que et pour, commentaires.
• On touche « + » à l'endroit voulu et on choisit le bloc : l'organigramme se dispose tout seul et reste toujours bien structuré.
• Les erreurs (variables non déclarées, types incorrects) sont signalées avant l'exécution.
• Annuler et rétablir, enregistrement automatique, raccourcis avec un clavier physique.

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

Gratuite, pour téléphones et tablettes Android, en français, anglais, italien, allemand et espagnol, avec thème clair et sombre.

Réalisée par le Prof. Davide Bertolino.
```

## de — Deutsch

### App-Name
```text
DB Flow: Ablaufpläne
```

### Kurzbeschreibung
```text
Ablaufpläne Schritt für Schritt ausführen, mit Python-, C- und Arduino-Code.
```

### Vollständige Beschreibung
```text
DB Flow ist ein Editor für strukturierte Programmablaufpläne, die wirklich laufen. Du baust den Algorithmus aus Blöcken, verfolgst ihn Schritt für Schritt und erhältst den Code dazu. Die App richtet sich an Lehrkräfte für Informatik, Technik und Elektronik und an alle, die programmieren lernen.

BAUEN
• Standardblöcke: Deklarationen, Eingabe und Ausgabe, Zuweisungen, Wenn/Sonst, While-, Do-While- und For-Schleifen, Kommentare.
• Tippe an der gewünschten Stelle auf „+“ und wähle den Block: Der Plan ordnet sich selbst an und ist immer sauber strukturiert.
• Fehler (nicht deklarierte Variablen, falsche Typen) werden vor der Ausführung gemeldet.
• Rückgängig und Wiederholen, automatisches Speichern, Tastaturkürzel mit einer physischen Tastatur.

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

Kostenlos, für Android-Smartphones und -Tablets, auf Deutsch, Englisch, Italienisch, Französisch und Spanisch, mit hellem und dunklem Design.

Entwickelt von Prof. Davide Bertolino.
```

## es — Español

### Nombre de la aplicación
```text
DB Flow: diagramas de flujo
```

### Descripción breve
```text
Diagramas de flujo ejecutables paso a paso, con código Python, C y Arduino.
```

### Descripción completa
```text
DB Flow es un editor de diagramas de flujo estructurados que se ejecutan de verdad. Construyes el algoritmo con bloques, lo sigues paso a paso y obtienes su código. Está pensada para docentes de informática, tecnología y electrónica y para quien aprende a programar.

CONSTRUYE
• Bloques estándar: declaraciones, lectura y escritura, asignaciones, si/sino, bucles mientras, repetir… mientras que y para, comentarios.
• Tocas «+» donde quieres el bloque y lo eliges: el diagrama se ordena solo y siempre queda bien estructurado.
• Los errores (variables no declaradas, tipos incorrectos) se señalan antes de ejecutar.
• Deshacer y rehacer, guardado automático, atajos con un teclado físico.

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

Gratuita, para teléfonos y tablets Android, en español, inglés, italiano, francés y alemán, con tema claro y oscuro.

Creada por el Prof. Davide Bertolino.
```
