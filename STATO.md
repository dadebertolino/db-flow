# DB Flow — Stato del progetto (per riprendere in una nuova sessione)

Aggiornato al 21 novembre 2026. Guida di sviluppo originale: [SVILUPPO.md](SVILUPPO.md).

## In breve

App Flutter (iOS, iPadOS, Android e macOS) per insegnanti e studenti: diagrammi di flusso strutturati ed eseguibili, generazione di codice, diagrammi Arduino. Offline, nessun account, nessuna raccolta dati.

- **Repository**: https://github.com/dadebertolino/db-flow, **pubblico dal 21 novembre 2026**, branch `main`. CI GitHub Actions verde: deny-list, formattazione, analisi, test.
- **Pubblicata** (21 novembre 2026): **Google Play** (Android) e **Mac App Store** (macOS). anche **iPhone e iPad** (stessa scheda Apple, acquisto universale). Link: App Store https://apps.apple.com/app/id6835826427, Google Play https://play.google.com/store/apps/details?id=it.davidebertolino.dbflow. Windows: dopo (vedi «Da fare»).
- Essendo pubblico, nel repository non vanno **mai** informazioni private: percorsi del computer, identificativi di dispositivi o simulatori, dettagli dei certificati, password. I commit di questo repository usano `info@davidebertolino.it`.
- **Flutter 3.47.2 / Dart 3.13.2**, fissati anche in CI (`.github/workflows/ci.yml`). Vanno aggiornati insieme.
- **arduino-cli 1.6.0 e core `arduino:avr` 1.8.8**, come nell'Arduino IDE del Mac, installati anche in CI: lì i test compilano davvero gli sketch per tutte le schede. Vanno aggiornati insieme.
- **Test**: 497, tutti verdi. Comando: `flutter test`.
- **Versione**: **1.0.0+1** (per l'uscita), definita in `pubspec.yaml` e in `lib/app_info.dart`; un test controlla che coincidano. A ogni nuovo caricamento su App Store Connect va aumentato almeno il numero di build (`+2`, `+3`…).
- Tutto è pushato su GitHub, CI verde. **Cronologia riscritta il 21 novembre 2026 («step zero»)**: un unico commit iniziale, senza informazioni private (percorsi del computer, dispositivi, dettagli dei certificati), prima di rendere pubblico il repository. Il backup della cronologia precedente resta solo sul computer dell'autore.

## ▶ Windows e Microsoft Store (avviata il 21 novembre 2026)

### Fatto
- **Piattaforma** `windows/` (21 novembre 2026): titolo «DB Flow», finestra 1200×800 (minima 720×560) come sul Mac, icona del Mac (`windows:` in `flutter_launcher_icons`), dati dell'exe a nome «Davide Bertolino» / «DB Flow».
- **Diagrammi** nella cartella dati dell'app (`defaultFlowBaseDir()` in `lib/io/storage.dart`: su Windows `getApplicationSupportDirectory`, cioè `AppData\Roaming\Davide Bertolino\DB Flow`), non nei Documenti dell'utente. Con MSIX Windows reindirizza AppData nel pacchetto e la **elimina alla disinstallazione**. Informativa aggiornata (21 novembre 2026, cinque lingue, «… iPhone, iPad, Android o Windows …»): **pagina del sito da ripubblicare** (`tool/privacy/informativa-privacy.html`).
- **Istanza unica**: `windows/runner/main.cpp` (mutex `Local\DavideBertolino.DBFlow`); con l'app già aperta, il doppio clic su un `.flow` manda il percorso alla finestra esistente (`WM_COPYDATA`, classe `DB_FLOW_WINDOW`), che legge il file e lo passa a Dart sul canale `dbflow/files` (`open`), come Mac e iPhone. Al primo avvio il percorso arriva come argomento (`main(args)`).
- **Pacchetto MSIX**: `msix` (solo sviluppo, MIT) con `msix_config` in `pubspec.yaml`: identità di Partner Center (`DavideBertolino.DBFlow`, `CN=D690F6A5-53AB-468E-9581-1266A41A362B`, editore «Davide Bertolino»), associazione `.flow`, cinque lingue, nessuna capability oltre a `runFullTrust`. Store ID `9P8H3SD0HM5V`.
- **CI**: job `windows` (windows-latest) che compila e crea `db_flow.msix`, scaricabile dagli artefatti (`db-flow-msix`). Verificato il manifest: identità, x64, `.flow`, nessun permesso di rete, non firmato (lo firma lo Store).
- **Testi della scheda** in cinque lingue: [store/microsoft-store.md](store/microsoft-store.md) (descrizione, funzionalità, termini di ricerca, risposte di Partner Center, note per la certificazione); `test/microsoft_store_texts_test.dart`.

### Sul PC Windows (l'utente)
1. Una volta: Git, **Visual Studio 2022** con «Sviluppo di applicazioni desktop con C++», **Flutter 3.47.2** nel PATH, `flutter doctor` verde.
2. `git clone https://github.com/dadebertolino/db-flow.git`, `flutter pub get`, `flutter run -d windows`.
3. Provare: esempi, esecuzione, freccia «←», monospazio (Consolas), «Salva con nome», export PNG/SVG/PDF, tema scuro.
4. Pacchetto di prova installabile: `dart run msix:create` (certificato di prova). Poi **doppio clic su un `.flow`** ad app chiusa e ad app aperta (deve aprirsi nella stessa finestra); disinstallazione (i diagrammi devono sparire).
5. **Screenshot** per lo Store (almeno 1366×768, ideale 1920×1080 o 2560×1440), negli stessi 7 soggetti degli altri store.

### In Partner Center (l'utente)
1. ~~Account aziendale verificato~~, ~~nome «DB Flow» prenotato~~ (21 novembre 2026).
2. Invio: prezzi e disponibilità, proprietà, classificazione IARC, pacchetto (`db_flow.msix` dalla CI o dal PC), schede in cinque lingue con screenshot, note per la certificazione. Tutto in `store/microsoft-store.md`.
3. A ogni nuovo invio: `msix_version` più alta in `pubspec.yaml` (ultima cifra sempre 0).
4. Dopo la pubblicazione: link https://apps.microsoft.com/detail/9P8H3SD0HM5V nella pagina di supporto e nel README.

## App Store (iOS e macOS): pubblicata

Obiettivo: creare la scheda in App Store Connect con **iOS e macOS insieme** (stesso bundle `it.davidebertolino.dbFlow` = un'unica app, acquisto universale) e arrivare a **TestFlight** e poi alla **revisione**. Android e Windows dopo.

### Già pronto
- Privacy: nessun dato raccolto, nessuna rete, nessun SDK di terze parti → etichetta **«Data Not Collected»**.
- `ITSAppUsesNonExemptEncryption = false` negli `Info.plist` (niente domanda sull'esportazione a ogni build).
- macOS: sandbox, categoria `public.app-category.education`, icona Mac.
- Informativa pubblicata: **https://www.davidebertolino.it/db-flow-privacy/** (cinque lingue).
- `LICENSE.md` (PolyForm Noncommercial 1.0.0), README aggiornato.
- Team di sviluppo nel progetto **iOS**: `62H5WTMFP8`.

### Lavoro tecnico (fatto il 16 novembre 2026)
1. Versione **1.0.0+1**.
2. **macOS firmato con il team** `62H5WTMFP8`: `DEVELOPMENT_TEAM` e `"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Apple Development"` sul target Runner (Debug, Profile, Release). Prima la build era firmata solo «ad-hoc» (`-`, ereditato dal progetto). Verificato con `codesign -dvv`: TeamIdentifier `62H5WTMFP8`; l'app firmata si avvia con la sandbox. Il `get-task-allow` della firma di sviluppo sparisce quando Xcode ri-firma per l'App Store.
3. **Screenshot** — `bash tool/screenshots/take.sh [iphone|ipad|mac|all] [it,en,…]` → `build/screenshots/<dispositivo>/<lingua>/N_nome.png` (non in git):
   - 7 schermate per dispositivo e lingua, in chiaro, nell'ordine della scheda: 1 editor (Numero primo), 2 esecuzione passo passo (MCD con 84 e 36), 3 codice Python, 4 simulazione Arduino (Dimmer, LED al 50%), 5 Pin e scheda, 6 esercizio verificato (5/5), 7 home;
   - misure: iPhone 6,3" **1206×2622** (cartella `iphone`, simulatore iPhone 17: è il formato che App Store Connect chiede dal 17 novembre 2026, «iPhone con Dynamic Island, display medio»), iPhone 6,9" 1320×2868 (`iphone69`, di riserva), iPad 13" **2064×2752**, Mac **2880×1800**. App Store Connect mostra anche una scheda «iPhone Duo»: misure da verificare;
   - `integration_test/screenshots_test.dart` (pacchetto `integration_test` dell'SDK, solo sviluppo; **non** gira con `flutter test` né in CI) guida l'app con diagrammi e preferenze in una cartella temporanea: i dati veri non vengono toccati, nemmeno sul Mac (stesso contenitore);
   - iPhone: simulatori iPhone 17 e iPhone 17 Pro Max; il test stampa `DBFLOW_SHOT`, lo script cattura con `simctl io screenshot` (barra di stato fissata alle 9:41, batteria piena);
   - iPad e Mac: **resi dal test sul Mac** (`--dart-define=SHOT_DEVICE=ipad|mac`), che disegna l'app alla misura voluta e salva il PNG. Lo schermo di sviluppo (1280×832 punti) è più piccolo di 1440×900; il simulatore iPad senza finestra (Xcode 27) era lentissimo e si bloccava. Per l'iPad la piattaforma è forzata a iOS (menu «Condividi», non «Salva») e c'è lo spazio vuoto della barra di stato, senza orologio; il Mac è il contenuto della finestra, senza barra del titolo;
   - **Mac: la finestra dell'app deve restare in primo piano** (lo script la riporta davanti ogni 3 s): se è coperta macOS rallenta i frame e il test si blocca. Durante il Mac non usare il computer.
4. **Testi della scheda** in cinque lingue: [store/app-store.md](store/app-store.md) (nome, sottotitolo, testo promozionale, parole chiave, descrizione, note per la revisione in inglese, dati comuni). `test/store_texts_test.dart` controlla limiti di Apple, parole chiave, frame adulto e parole vietate.
5. **Pagina progetto / supporto**: [tool/site/db-flow.html](tool/site/db-flow.html) (blocco Gutenberg, stile `.db-pro` come l'informativa, cinque lingue, contatto, FAQ). **Da pubblicare** su https://www.davidebertolino.it/db-flow/ prima di creare la scheda (è l'URL di supporto obbligatorio). All'uscita: sostituire «In arrivo su App Store» con il link alla scheda.
6. Correzioni trovate facendo gli screenshot:
   - sul telefono il pulsante ▶ «Esegui» nella barra aveva l'icona scura sul fondo blu (il tema delle icone dell'AppBar copriva il colore del pulsante pieno): ora `onPrimary`, con un test in `test/ui/theme_test.dart`;
   - «Pin e scheda» su schermi larghi (Mac, iPad): il disegno della scheda è limitato a 720 punti e centrato, prima occupava tutta la finestra e usciva dallo schermo.

### Da fare in App Store Connect (le fa l'utente, Claude guida)
1. **Nuova app** → piattaforme **iOS + macOS**; nome «DB Flow» (verificare che sia libero: alternative tipo «DB Flow – Diagrammi di flusso»); lingua principale italiano; bundle `it.davidebertolino.dbFlow`; SKU a scelta (es. `dbflow`).
2. **Informazioni app**: categoria **Istruzione** (secondaria: Strumenti per sviluppatori); classificazione età **4+** (tutte le risposte «No»); **prezzo gratuito**; paesi.
3. **Privacy dell'app**: URL dell'informativa sopra; «Data Not Collected».
4. **URL di supporto (obbligatorio)**: https://www.davidebertolino.it/db-flow/ — pagina pronta in `tool/site/db-flow.html`, da pubblicare.
5. Per **ogni piattaforma** (iOS e macOS hanno pagine di versione separate): testi e note da `store/app-store.md`, screenshot da `build/screenshots/` (iPhone 6,9" e iPad 13" nella pagina iOS, Mac nella pagina macOS), build.
6. **Build**:
   - iOS: `flutter build ipa --release` → caricare `build/ios/ipa/*.ipa` con Transporter (o Xcode Organizer).
   - macOS: `flutter build macos --release`, poi `open macos/Runner.xcworkspace` → Product › Archive → Distribute App › App Store Connect.
7. **TestFlight** interno (iPhone, iPad, Mac) con qualche collega, poi **invio in revisione**.
8. All'uscita: repository GitHub reso **pubblico** (non prima) e push finale.

### In sospeso, fuori da questo repository
- **Tema del sito** (repository `tema-davidebertolino-it`, a parte): ramo locale `pagine-intestazione-propria`, commit `358135e`, versione 2.4.0, **non pushato**. Le pagine `.db-pro` (come l'informativa) non mostrano più titolo del tema e barra laterale. Va portato avanti in una sessione aperta su quel repository: push del ramo → CI → merge → tag `v2.4.0` (il tag aggiorna il sito). Il vecchio `starter-didattica` (1.0.0) non va usato.

## Google Play: pubblicata (preparata dal 19 novembre 2026)

Obiettivo: scheda in Play Console, **test interno**, poi produzione. Account aziendale: nessun obbligo di test chiuso con 12 tester.

### Fatto il 19 novembre 2026
1. **Build di rilascio provata**: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` (~60 MB; Play scarica sul telefono solo l'architettura giusta). `targetSdk` 36, `minSdk` 24, **nessun permesso** nel manifesto di rilascio.
2. **Prima esecuzione su Android** (emulatore Pixel 10): tutto il percorso degli screenshot funziona. Due difetti di resa trovati e corretti, solo su Android:
   - la freccia «←» dell'assegnazione era minuscola (Roboto non ce l'ha, il ripiego Noto Sans Symbols la disegna piccola). Ora `arrowSpan()` in `lib/render/theme.dart` disegna ogni «←» con **DBFlowArrow**, un font di un solo glifo disegnato da noi (`assets/fonts/DBFlowArrow.ttf`, generato da `tool/fonts/make_arrow_font.py` con fonttools). Usato in blocchi, misura dei blocchi, PNG, codice e console. Metterlo solo in `fontFamilyFallback` **non funziona** (Android sceglie il proprio ripiego) e cambiava il font di tutta l'app. Su iOS e macOS non cambia nulla;
   - il monospazio (variabili, codice, console) usciva in Cutive Mono, da macchina da scrivere: in Android «Courier New» è un alias di quel font. Ora `monospace` viene prima di Courier in `monoStyle`.
3. **Testi della scheda** in cinque lingue: [store/play-store.md](store/play-store.md) (nome con «diagrammi di flusso», perché Play non ha parole chiave; breve descrizione; descrizione completa derivata da quella Apple, con Android al posto di iPhone/iPad/Mac), più tutte le risposte dei questionari. `test/play_store_texts_test.dart` controlla limiti, frame adulto, parole vietate e assenza di dispositivi Apple.
4. **Grafica**: icona 512 e grafica in primo piano 1024×500 per lingua (`flutter test tool/store/render_play_graphics_test.dart` → `build/store/play/`); screenshot telefono 1080×1920 e tablet 1600×2560 (`bash tool/screenshots/take.sh play`, emulatore con risoluzione forzata e barra di stato in modalità demo).

### Bundle firmato (19 novembre 2026)
`build/app/outputs/bundle/release/app-release.aab`, 1.0.0 (versionCode 1), firmato con la chiave di caricamento dell'autore, con il font DBFlowArrow incluso. A ogni nuovo caricamento su Play va aumentato il versionCode (`+2`, `+3`… in `pubspec.yaml` e `lib/app_info.dart`).

### Da fare (le fa l'utente, Claude guida)
1. ~~Chiave di caricamento~~ fatta: file `.jks` fuori dal progetto, nella cartella delle chiavi dell'autore, alias `upload` (stessa convenzione delle altre app; tenerne una copia di sicurezza). `android/key.properties` (ignorato da git) punta a quel file con `storeFile`, `storePassword`, `keyAlias=upload`, `keyPassword`.
2. ~~Bundle firmato~~ fatto (vedi sopra). Per i successivi: `flutter build appbundle --release` e controllare che sia firmato con la chiave giusta (`keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`).
3. Play Console → **Crea app**: nome, lingua predefinita italiano, App, Gratuita, dichiarazioni.
4. **Contenuti dell'app**: le risposte sono in `store/play-store.md` (pubblico 18+, sicurezza dei dati: nessun dato, nessun annuncio, nessun ID pubblicità, classificazione IARC).
5. **Scheda dello Store principale** + traduzioni (en-US o en-GB, fr-FR, de-DE, es-ES): testi, icona, grafica, screenshot.
6. **Test interno**: caricare l'AAB, aggiungere i tester (email), provare su **telefoni Android veri**, anche l'apertura dei `.flow` da Gmail/File/Drive (mai provata).
7. Paesi, poi **produzione** → revisione di Google.

## Fatto (roadmap di SVILUPPO.md)

| Fase | Stato |
|---|---|
| M1 Modello (AST, `.flow` v2 con migrazione da v1, parser, tipi, validatore) | ✅ |
| M2 Layout automatico e canvas (zoom, pan, forme standard) | ✅ |
| M3 Editor (inserimento su "+", dialog, undo/redo, salvataggio automatico, esempi) | ✅ |
| M4 Esecuzione passo-passo (variabili, console, input, velocità) | ✅ |
| M5 Codice (pseudocodice, Python, C, Arduino) ed export (PNG, SVG, PDF, `.flow`) | ✅ |
| M6 Pubblicazione store | ✅ iPhone, iPad, Mac e Android pubblicate; repository pubblico (21 novembre 2026). Resta Windows |

### Aggiunte oltre la roadmap

- **Diagrammi Arduino**:
  - struttura `setup()`/`loop()`;
  - blocchi `digitalRead`/`analogRead` (I/O, parallelogramma), `digitalWrite`/`analogWrite` (parallelogramma) e `delay` (rettangolo);
  - funzioni `digitalRead()`, `analogRead()`, `millis()`, costanti `HIGH`/`LOW`/`A0…`;
  - helper **«Pin e scheda»**: disegno interattivo della scheda, componente collegato (LED, pulsante, potenziometro, altro), scelta del pin a tasti con scambio dei pin occupati, proposte dei pin dedotte dal diagramma, anteprima di `setup()`;
  - validazione dei pin: PWM, A0–A5, pin seriali, modi;
  - sketch `.ino` verificato **compilando** con l'`arduino-cli` dell'Arduino IDE (nei test, saltato se manca).
  - **Schede** (15 novembre 2026): Uno, Nano, Pro Mini, Micro, Mega 2560 (`boards` in `lib/arduino/board.dart`).
    - Nano e Pro Mini: A6/A7 solo analogici (`analogOnlyPins`): niente `pinMode`, `digitalRead`/`digitalWrite` segnalati dal validatore.
    - Micro: USB nativa (nessun pin seriale riservato), A0–A5 = 18–23, PWM anche sul 13. A6–A11 (24–29) sono i pin 4, 6, 8, 9, 10, 12 (`analogAliases`): con il nome analogico solo `analogRead`; i controlli (pin doppi, occupanti, spostamenti, proposte, disegno) confrontano il pin fisico (`Board.physical`/`samePin`); sul disegno le etichette sono doppie («~9/A9»). Disegnata più alta del vero (22 mm) per farle stare.
    - Mega: pin 0–53, A0–A15 (54–69), PWM 2–13 e 44–46.
    - Disegno: ogni fila di pin ha un lato (`Side`) per i richiami; file verticali per il doppio connettore della Mega (colonna interna verso sinistra, esterna verso destra) e per il connettore di programmazione della Pro Mini. Fori, nome, titoli, USB e jack sono facoltativi per scheda. La Pro Mini è disegnata più alta del vero (22 mm invece di 18) per far stare le etichette.
    - PWM e ingressi (15 novembre 2026): i pin usati **per nome** con `analogWrite` (`pwmPinNames`, e `PinSuggestion.pwm` per le proposte) si possono mettere solo su pin PWM, nella finestra del pin e negli spostamenti automatici (`planPin(pwmNames:)`); un numero fisso nel diagramma non si sposta e lo segnala il validatore. I pin letti con `digitalRead` sono proposti come pulsante con `INPUT_PULLUP`; la finestra del pin spiega che premuto = LOW.
  - **Simulazione** (15 novembre 2026): «Esegui» anche nei diagrammi Arduino.
    - `lib/runtime/sim_board.dart` (`SimBoard`, Dart puro): livelli e PWM delle uscite, pulsanti (con `INPUT_PULLUP` premuto = LOW), ingressi HIGH/LOW, valori analogici (potenziometro a 512 all'avvio), `millis()`.
    - Interprete: `setup()` una volta poi `loop()` per sempre (evento `LoopStart`); variabili globali con valore iniziale come nello sketch generato (i blocchi «dichiara» non le azzerano); costanti `HIGH`, `LOW`, `A0…`, nomi dei pin; limite di 10000 passi **per giro** di `loop()`; 1 ms simulato per blocco più i `delay`.
    - `RunController`: in esecuzione automatica un `delay` dura almeno il suo tempo reale; «fino alla fine» = fino alla fine del giro di `loop()`; console limitata alle ultime 500 righe; reset che mantiene pulsanti e potenziometri.
    - Pannello «Circuito» (`lib/ui/sim_circuit.dart`): LED (luminosità con il PWM), pulsanti da toccare, cursori per i potenziometri, interruttori per gli ingressi, valore delle altre uscite. Sul telefono è la prima di tre schede.
    - Test: `test/runtime/arduino_sim_test.dart`, `test/ui/arduino_sim_ui_test.dart` (anche i tempi reali dei delay).
  - **Sketch per l'Arduino IDE**: voce di menu «Sketch Arduino (.ino)»; su computer crea `<nome>/<nome>.ino` nella cartella scelta (`saveArduinoSketch`, nome da `sketchName`).
    - `test/arduino/boards_test.dart`: per ogni scheda posizione e tocco di ogni pin, disegno con tutti i pin configurati, sketch compilato con `arduino-cli`.
- **Cinque lingue** (it, en, fr, de, es), con terminologia scolastica per paese (vedi sotto).
- **Tema scuro**:
  - colori del diagramma in `DiagramColors` (ThemeExtension in `lib/render/theme.dart`), varianti chiara e scura; gli export PNG/SVG/PDF restano sempre chiari;
  - scelta del tema (come il dispositivo, chiaro, scuro) dal menu nella home, salvata in `impostazioni.json` (`lib/io/settings.dart`);
  - un test controlla il contrasto (WCAG) di testi, bordi e stati in entrambi i temi.
- **Esercizi con verifica dell'output** (solo diagrammi algoritmo):
  - campo opzionale `exercise` nel `.flow` (consegna, casi di prova con `in`/`out`/`hidden`, `locked`); formato sempre v2;
  - modello in `lib/model/exercise.dart`, verifica in `lib/runtime/exercise_check.dart`;
  - confronto tollerante, riga per riga: maiuscole, spazi, righe vuote e punteggiatura `. , ; : ! ?` non contano; numeri per valore (`5` = `5.0`, `2,5` = `2.5`); vero/falso in ogni lingua;
  - docente: menu "Crea esercizio", casi visibili o nascosti, "Calcola dal diagramma" (l'output atteso si ricava dalla propria soluzione), "Condividi come esercizio" (corpo vuoto, `locked`);
  - studente: riquadro della consegna in cima all'editor con "Verifica"; risultati con dettagli solo per i casi visibili; consegna ricevuta in sola lettura, casi nascosti non mostrati (restano leggibili aprendo il file come testo);
  - 10 esercizi inclusi in `assets/exercises/` (+ en/ fr/ de/ es/), output solo numeri o vero/falso; `test/runtime/builtin_exercises_test.dart` ha una soluzione di riferimento per ciascuno.
- **Icona, splash e schermate**:
  - icona e splash generati da codice (`tool/icons/render_icons_test.dart`);
  - schermata di avvio Flutter di almeno 1 s con nome, versione e autore;
  - schermata Informazioni (guida rapida, licenze);
  - Informativa privacy nell'app.

### Identificativi e firma (15 novembre 2026, definitivi)

- **iOS e macOS**: `it.davidebertolino.dbFlow` (tenuto per non perdere i diagrammi già salvati sui dispositivi di prova).
- **Android**: `applicationId` `it.davidebertolino.dbflow`; il namespace del codice Kotlin resta `it.davidebertolino.db_flow`.
- Non si cambiano dopo la prima pubblicazione.
- **Firma Android**: `android/key.properties` (ignorato da git) con `storeFile`, `storePassword`, `keyAlias`, `keyPassword`; la chiave `.jks` sta fuori dal progetto. Senza il file la release è firmata con la chiave di debug (Google Play la rifiuta). Google Play App Signing gestisce la chiave di firma finale; quella di caricamento, se persa, si può far reimpostare.
- **Account Google Play aziendale**: niente obbligo di test chiuso con 12 tester.
- Ordine: iOS, macOS e Android; Windows dopo la loro pubblicazione.

### Apertura dei `.flow` dall'esterno (15 novembre 2026)

- Tipo dichiarato `it.davidebertolino.dbflow.flow` (estensione `.flow`, MIME `application/x-dbflow`) negli `Info.plist` di iOS e macOS; la condivisione dei `.flow` usa quel MIME.
- Canale `dbflow/files` (`lib/io/incoming.dart`): il nativo legge il file e passa il testo; `pending` restituisce quelli arrivati prima che Dart fosse pronto, `open` consegna quelli successivi. La home torna in primo piano e salva una copia, come «Apri un file .flow».
- **iOS**: plugin `FlowFilesPlugin` in `ios/Runner/AppDelegate.swift`, registrato come scene delegate (avvio e app aperta); cancella la copia in `Documents/Inbox`.
- **macOS**: `application(_:open:)` in `macos/Runner/AppDelegate.swift`; verificato con Finder (`open file.flow`) ad app chiusa e aperta.
- **Android**: `MainActivity.kt`, intent `VIEW` e `SEND` con MIME `application/x-dbflow`, `application/json`, `application/octet-stream` (le app di posta non conoscono `.flow`); compilato ma **non ancora provato su un dispositivo**.
- **Windows**: `main(args)` legge i percorsi `.flow` passati come argomento; manca l'associazione dell'estensione (installer/registro).
- Test con archivio in memoria (`test/io/incoming_test.dart`): nei test di widget l'I/O reale avviato dall'app non termina.

### macOS (aggiunto il 15 novembre 2026)

- Cartella `macos/` (bundle `it.davidebertolino.dbFlow`, nome «DB Flow», macOS 12+).
- Sandbox attiva; permesso solo sui file scelti dall'utente (`files.user-selected.read-write`). In Release nessun accesso alla rete; `network.server` c'è solo in Debug, per gli strumenti di sviluppo.
- Finestra iniziale 1200×800, minima 720×560 (`macos/Runner/MainFlutterWindow.swift`).
- Su computer (`isDesktop` in `lib/io/share.dart`, basato su `defaultTargetPlatform`) la condivisione diventa «Salva con nome…».
- Clic destro su un blocco = pressione lunga.
- Scorciatoie nell'editor, valide anche su iPad con tastiera: ⌘/Ctrl+Z annulla, ⌘/Ctrl+⇧+Z o Ctrl+Y ripete, ⌘/Ctrl+D duplica, Canc/⌫ elimina, Invio modifica, Esc deseleziona.
- Icona Mac a parte (`assets/icon/icon_macos.png`, quadrato arrotondato con margine), generata dallo stesso strumento delle altre icone.
- Compilare: `flutter build macos --release` → `build/macos/Build/Products/Release/DB Flow.app`.
- **Windows**: prossimo passo, da compilare su un PC Windows (Flutter compila per Windows solo su Windows). Font monospazio di riserva già impostato (`Consolas`).

## Architettura

```
lib/
  model/      AST (stmt, expr, program), file .flow, validatore, slot      ← Dart puro
  expr/       lexer, parser, controllo tipi, funzioni, valori             ← Dart puro
  runtime/    interprete a generatore, ambiente, valutazione              ← Dart puro
  codegen/    pseudo, python, c, arduino                                  ← Dart puro
  layout/     motore di layout, etichette, palette e geometria forme      ← Dart puro
  arduino/    profilo schede (+ disegno), assegnazione pin, proposte      ← Dart puro
  i18n/       catalogo testi: tr.dart (astratta) + tr_it/en/fr/de/es      ← Dart puro
  editor/     comandi sull'albero, undo/redo, stato editor, dialog blocchi
  render/     canvas, blocchi, frecce, disegno scheda, tema
  io/         salvataggio, export PNG/SVG/PDF, condivisione
  ui/         home, editor, esecuzione, codice, pin e scheda, info, privacy, splash
  app.dart, app_info.dart (nome/versione/autore), main.dart
assets/examples/          esempi italiani (+ en/ fr/ de/ es/ tradotti)
assets/icon/              sorgenti di icona e splash
test/                     model, expr, runtime, codegen (golden + esecuzione python3/cc),
                          arduino (golden + compilazione), layout, editor, io, ui, i18n, privacy
```

## Regole e convenzioni (importanti)

- **Privacy** (standard dei progetti dell'autore):
  - niente rete, SDK di analytics/ads/crash reporting, account;
  - `tool/check_denylist.sh` in CI; `test/privacy_test.dart` fallisce se compare codice di rete o la parola "open source"/"GDPR" nei testi;
  - nei testi si scrive "codice pubblico/source-available", mai "open source".
- **Testi**: mai stringhe fisse nel codice. Ogni testo va in `lib/i18n/tr.dart` (astratta) e in **tutte e cinque** le lingue; se manca, il compilatore lo segnala. La lingua corrente è il global `tr` (`setLanguage`).
- **vero/falso** sono accettati in tutte le lingue (`trueWords`/`falseWords` in `tr.dart`).
- **Dipendenze**:
  - runtime: `path_provider`, `share_plus`, `pdf`, `file_picker`, `flutter_localizations` (SDK);
  - solo sviluppo: `flutter_lints`, `fake_async`, `flutter_launcher_icons`, `flutter_native_splash`, `integration_test` (SDK, per gli screenshot);
  - ogni nuova dipendenza va valutata prima di aggiungerla.
- **Snapshot del codice generato**: `UPDATE_GOLDENS=1 flutter test test/codegen test/arduino`.
- **Semantica del linguaggio**:
  - `/` dà sempre un reale; `%` ha il segno del dividendo;
  - `&` concatena qualunque valore;
  - confronti non concatenabili;
  - contatore del `for` solo intero.
- **Commit**: in italiano, con riga `Co-Authored-By`.

## Informativa privacy

- Testo unico in `lib/i18n` (`privacySections`, `privacyUpdated`), mostrato nell'app e trasformato nella pagina del sito da `tool/privacy/privacy_page.dart`. Se cambia, aggiornare la data in tutte le lingue e rigenerare la pagina.
- Ogni frase deve restare vera: per esempio sul Mac disinstallare l'app non cancella i diagrammi (restano in Libreria › Containers), e oltre ai diagrammi l'app salva solo la scelta del tema (`impostazioni.json` nella cartella di supporto, non in Documenti).
- iOS: `UIFileSharingEnabled` e `LSSupportsOpeningDocumentsInPlace` a `true` rendono i diagrammi visibili nell'app File.

## Comandi utili

```bash
flutter test                                   # tutti i test
flutter analyze && dart format .               # come in CI
bash tool/check_denylist.sh
flutter test tool/icons/render_icons_test.dart && dart run flutter_launcher_icons \
  && dart run flutter_native_splash:create     # rigenerare icona e splash
```

### Installare su un iPhone di prova (anche in Wi‑Fi)

```bash
flutter build ios --release
xcrun devicectl list devices                    # identificativo del dispositivo
xcrun devicectl device install app --device <identificativo> build/ios/iphoneos/Runner.app
```

- **MAI `flutter install`**: disinstalla l'app e **cancella i diagrammi salvati**. È già successo una volta.
- `devicectl install` aggiorna l'app sul posto e conserva i dati.
- L'errore generico "Could not run … Error running application" di `flutter run` significa quasi sempre **iPhone bloccato**: l'app risulta comunque installata.
- **Simulatore**: Xcode 27 non ha `Simulator.app`. I simulatori funzionano senza finestra (`xcrun simctl list devices` per gli identificativi); per vederli si usa DeviceHub.

## Da fare / idee aperte

0. **Windows**: vedi la sezione «▶ Windows e Microsoft Store» in cima.
1. **Revisione delle traduzioni** da parte di insegnanti madrelingua. Le bozze sono state scritte da agenti; i punti dubbi:
   - **EN**: ortografia britannica ("analogue", "Centre").
   - **FR**: "organigramme" o "algorigramme"; `DÉCLARER x : ENTIER`.
   - **DE**: `VARIABLE x : GANZZAHL`; "Kommazahl"; la voce "Verzweigung" della guida, usata anche per i cicli.
   - **ES**: "lógico"; "Definir"; alcune scelte più latinoamericane.
2. **Simulazione Arduino, sviluppi**: mostrare lo stato dei pin anche sul disegno della scheda; componenti nuovi (servo, buzzer) con la loro resa nel circuito.
3. **Nuovi componenti Arduino**: servo, buzzer (`tone`), sensori. Si aggiungono a `Component` in `lib/arduino/board.dart` e ai testi.
4. **Altre schede**: si aggiunge un profilo `Board` (con `BoardDrawing`) in `board.dart` e una voce in `boards`; i test in `boards_test.dart` la coprono da soli.
5. **Apertura dei `.flow` da Mail/File**: fatta (vedi sopra); da provare su Android e da completare su Windows con l'associazione dell'estensione.
6. **Aggiornare Flutter**: nelle versioni nuove `package:flutter/material.dart` è deprecato a favore di `material_ui`. Va migrato insieme alla versione fissata in CI.
7. **M6 Pubblicazione** (vedi «Prossima sessione» in cima):
   - ~~file `LICENSE`~~: fatto, `LICENSE.md` con il testo ufficiale (tag 1.0.0 del repository PolyForm) e la riga `Required Notice`;
   - informativa privacy su davidebertolino.it: la pagina è pronta in `tool/privacy/informativa-privacy.html` (blocco Gutenberg, cinque lingue, generato dai testi dell'app; `test/privacy_page_test.dart` controlla che sia aggiornata). pubblicata il 16 novembre 2026 su https://www.davidebertolino.it/db-flow-privacy/ (indirizzo da usare anche nelle schede degli store);
   - questionari degli store: Apple "Data Not Collected"; Google senza dati, target 18+, nessuna funzione salute, nessun contenuto online;
   - schede degli store e screenshot senza dati reali;
   - chiave di caricamento Android (la crea l'utente con `keytool`, fuori dal progetto) e `android/key.properties`;
   - prove su dispositivi veri: **Android mai provato su un telefono** (anche l'apertura dei `.flow`), iPad, Mac;
   - beta chiusa di 1-2 settimane (TestFlight, test interno di Play): senza crash reporting, i bug si scoprono solo così;
   - repository reso pubblico all'uscita.
8. **Idee dalla guida**: sottoprogrammi, array.
9. **Esercizi, possibili sviluppi**: segnare gli esercizi inclusi già risolti; la traduzione degli esercizi inclusi va rivista insieme alle altre.

## Repository pubblico (fatto il 21 novembre 2026)

Preparato il 16 novembre 2026:
- nessun segreto né nel contenuto né nella cronologia (chiavi, `key.properties`, `local.properties` esclusi da git); nessun identificativo personale di dispositivi, nemmeno nella cronologia (riscritta in un unico commit);
- descrizione, sito (informativa) e argomenti impostati su GitHub; wiki e progetti disattivati;
- `LICENSE.md`: GitHub la mostra come «Other» (PolyForm non è nel suo elenco), è normale.

Fatto il 21 novembre 2026, dopo lo step zero (cronologia ripartita da un commit ripulito, vecchie esecuzioni della CI cancellate):
1. ~~Visibilità pubblica~~ (`gh repo edit … --visibility public`).
2. ~~Link al codice nell'informativa~~: https://github.com/dadebertolino/db-flow risponde.
3. ~~Link agli store~~ nella pagina di supporto (`tool/site/db-flow.html`, pulsanti App Store e Google Play in cinque lingue) e nel README. **Da ripubblicare sul sito.**
4. Facoltativo: protezione del ramo `main` (CI obbligatoria prima del merge).

## Scelte di progetto

- Ogni modifica si prova subito su un iPhone vero, oltre che nei test.
- Simbologia corretta dei diagrammi: ingressi e uscite (anche sui pin) nel parallelogramma.
- Arduino: nomi originali (`digitalWrite`, `HIGH`/`LOW`); schede Uno, Nano, Pro Mini, Micro, Mega; componenti base prima di tutto.
- Niente funzioni nuove fino alla 1.0: prima un'app curata (sottoprogrammi, array, servo/buzzer e Windows vengono dopo).
- Google Play: account aziendale; pubblico 18+, come da standard privacy dell'autore. Apple: frame adulto («per insegnanti e chi impara a programmare»), mai «per ragazzi».
- Autore: «Prof. Davide Bertolino», con la preposizione articolata ("Realizzato **dal** Prof.").
- Splash: almeno 1 secondo, con nome dell'app, versione e nome dell'autore, presi da costanti nel codice.
