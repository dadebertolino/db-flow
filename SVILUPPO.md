# DB Flow — Guida di sviluppo

Editor di diagrammi di flusso **strutturati ed eseguibili** per iPhone/iPad e Android.
Uso didattico: lo studente costruisce l'algoritmo a blocchi, lo esegue passo-passo, ne genera il codice.

> Identificativi definitivi: `it.davidebertolino.dbFlow` (iOS, macOS), `it.davidebertolino.dbflow` (Android). Vedi STATO.md.

---

## 1. Principi

- **Editor strutturato**: il diagramma è un albero sintattico (AST), non un grafo di forme libere. Si inseriscono blocchi sulle frecce; il diagramma è sempre valido per costruzione.
- **Layout automatico**: nessuna posizione salvata, il layout si calcola dall'AST.
- **Offline-first, privacy by design**: nessun account, nessun backend, nessun analytics/ads/crash reporting. Tutti i dati restano sul dispositivo.
- **Licenza**: PolyForm Noncommercial 1.0.0, codice pubblico su GitHub ("codice pubblico / source-available", mai "open source").
- **Gratuita**, nessun acquisto in-app.

---

## 2. Setup ambiente (macOS + VS Code)

### Strumenti
```bash
# Flutter SDK (stable)
brew install --cask flutter          # oppure installazione manuale da flutter.dev
flutter doctor -v
```
- **Xcode** (App Store) + `sudo xcodebuild -runFirstLaunch` + `sudo gem install cocoapods` (o `brew install cocoapods`)
- **Android Studio** → SDK Manager: Android SDK, Command-line Tools, Build-Tools; creare un AVD (tablet + phone)
- `flutter doctor --android-licenses`

### Estensioni VS Code
- `Dart-Code.flutter` (installa anche `Dart-Code.dart-code`)
- `usernamehw.errorlens` (opzionale)
- `streetsidesoftware.code-spell-checker-italian` (opzionale)

### Creazione progetto
```bash
flutter create --org it.davidebertolino --platforms=ios,android --project-name db_flow db_flow
cd db_flow
code .
```

### `.vscode/settings.json`
```json
{
  "editor.formatOnSave": true,
  "editor.rulers": [100],
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "[dart]": {
    "editor.codeActionsOnSave": { "source.fixAll": "explicit", "source.organizeImports": "explicit" }
  }
}
```

### `.vscode/launch.json`
```json
{
  "version": "0.2.0",
  "configurations": [
    { "name": "debug", "request": "launch", "type": "dart" },
    { "name": "profile", "request": "launch", "type": "dart", "flutterMode": "profile" },
    { "name": "release", "request": "launch", "type": "dart", "flutterMode": "release" }
  ]
}
```

Selezione dispositivo: barra di stato in basso a destra in VS Code (simulatore iPad, emulatore Android, dispositivo fisico).

---

## 3. Dipendenze

### Ammesse
| Pacchetto | Uso |
|---|---|
| `path_provider` | cartella documenti per i file `.flow` |
| `share_plus` | condivisione file/export tramite share sheet |
| `pdf` | export PDF |
| `file_picker` | apertura file `.flow` ricevuti |
| `flutter_lints` (dev) | analisi statica |

Ogni nuova dipendenza va valutata **prima** di aggiungerla: deve essere necessaria, mantenuta, senza telemetria.

### Vietate (deny-list, controllata in CI)
`firebase_*`, `google_mobile_ads`, `sentry*`, `*analytics*`, `amplitude*`, `mixpanel*`, `appsflyer*`, `adjust*`, `facebook*`, `onesignal*`, qualsiasi SDK di tracking, ads o crash reporting.

### `tool/check_denylist.sh`
```bash
#!/usr/bin/env bash
set -e
PATTERN='firebase_|google_mobile_ads|sentry|analytics|amplitude|mixpanel|appsflyer|adjust|facebook|onesignal'
if grep -Eiq "$PATTERN" pubspec.yaml pubspec.lock; then
  echo "ERRORE: dipendenza vietata trovata"; grep -Ein "$PATTERN" pubspec.yaml pubspec.lock; exit 1
fi
echo "Deny-list OK"
```

### CI (`.github/workflows/ci.yml`)
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: bash tool/check_denylist.sh
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test
```

---

## 4. Struttura del progetto

```
lib/
  main.dart
  app.dart                  # MaterialApp, tema, routing
  model/
    stmt.dart               # AST istruzioni (sealed class)
    expr.dart               # AST espressioni
    program.dart            # Program: nome, versione formato, corpo
    serialization.dart      # JSON <-> AST
  expr/
    lexer.dart
    parser.dart             # discesa ricorsiva, testo -> Expr
    types.dart              # Value: IntV, RealV, StrV, BoolV
  layout/
    layout_engine.dart      # AST -> LayoutNode (rettangoli, porte, frecce)
    metrics.dart            # dimensioni blocchi, spaziature
  render/
    flow_canvas.dart        # InteractiveViewer + Stack
    block_widget.dart       # widget per ogni tipo di blocco
    edge_painter.dart       # CustomPainter frecce
    theme.dart              # colori per tipo blocco
  editor/
    editor_state.dart       # stato corrente + selezione
    history.dart            # undo/redo a snapshot
    commands.dart           # insert/delete/edit blocco su un path dell'AST
    block_dialogs.dart      # editing contenuto blocchi
  runtime/
    interpreter.dart        # esecuzione passo-passo
    environment.dart        # variabili
    runtime_errors.dart
  codegen/
    generator.dart          # interfaccia
    python_gen.dart
    c_gen.dart
    pseudo_gen.dart         # pseudocodice in italiano
  io/
    storage.dart            # salva/apri .flow
    export_png.dart
    export_svg.dart
    export_pdf.dart
  ui/
    home_page.dart          # elenco diagrammi
    editor_page.dart
    run_panel.dart          # variabili, console I/O, controlli esecuzione
    code_panel.dart
test/
  expr/  runtime/  codegen/  model/  layout/
tool/
  check_denylist.sh
```

Regola: `model/`, `expr/`, `runtime/`, `codegen/`, `layout/` sono **Dart puro**, senza import di `package:flutter`. Testabili senza UI.

---

## 5. Modello (AST)

```dart
sealed class Stmt { const Stmt(); }

final class Declare extends Stmt { final String name; final VarType type; }
final class Assign  extends Stmt { final String target; final Expr value; }
final class Input   extends Stmt { final String variable; }
final class Output  extends Stmt { final Expr value; }
final class If      extends Stmt { final Expr cond; final List<Stmt> then, otherwise; }
final class While   extends Stmt { final Expr cond; final List<Stmt> body; }
final class DoWhile extends Stmt { final List<Stmt> body; final Expr cond; }
final class For     extends Stmt { final String v; final Expr from, to, step; final List<Stmt> body; }
final class Comment extends Stmt { final String text; }

enum VarType { integer, real, string, boolean }
```

- Classi **immutabili** (campi `final`, liste non modificabili); ogni modifica produce un nuovo `Program`.
- Ogni blocco ha un `id` stabile (stringa) per selezione, evidenziazione in esecuzione e animazioni.
- Indirizzamento nell'albero tramite **path** (`List<int>` di indici + ramo `then/otherwise/body`).

### Formato file `.flow` (JSON)
```json
{
  "format": "db-flow",
  "version": 1,
  "name": "Massimo tra due numeri",
  "body": [
    { "id": "a1", "t": "declare", "name": "a", "type": "integer" },
    { "id": "a2", "t": "input", "var": "a" },
    { "id": "a3", "t": "if", "cond": "a > b", "then": [], "else": [] }
  ]
}
```
Le espressioni si salvano come **testo sorgente** e si riparsano in apertura. Campo `version` obbligatorio; prevedere migrazioni.

---

## 6. Linguaggio delle espressioni

| Elemento | Sintassi |
|---|---|
| Tipi | intero, reale, stringa, booleano |
| Letterali | `12`, `3.14`, `"testo"`, `vero`, `falso` |
| Aritmetici | `+ - * / %` (`/` tra interi = divisione intera? **decidere e documentare**) |
| Confronto | `== != < <= > >=` |
| Logici | `and or not` (accettare anche `&& \|\| !`) |
| Concatenazione | `&` oppure `+` tra stringhe |
| Funzioni | `abs sqrt int round len random` (lista chiusa) |
| Precedenza | `not` > `* / %` > `+ -` > confronti > `and` > `or` |

- Parser a **discesa ricorsiva** scritto a mano (nessuna dipendenza).
- Errori con posizione (colonna) e messaggio in italiano, mostrati nel dialog del blocco.
- Controllo tipi in fase di editing quando possibile (variabile non dichiarata, tipo incompatibile).

---

## 7. Layout e rendering

- **Layout engine** ricorsivo: ogni Stmt restituisce un `LayoutNode` con larghezza, altezza, porta di ingresso e di uscita.
  - Sequenza: impilamento verticale, centrato sull'asse.
  - `If`: due rami affiancati, rombo in alto, ricongiungimento in basso.
  - `While`/`For`: rombo + corpo + freccia di ritorno a sinistra.
- **Canvas**: `InteractiveViewer` (zoom 0.3–3.0, pan libero) → `Stack` con:
  1. `CustomPaint(EdgePainter)` per frecce e linee;
  2. `Positioned(BlockWidget)` per i blocchi.
- **Punti di inserimento**: piccolo "+" sul punto medio di ogni freccia → bottom sheet con i tipi di blocco.
- **Forme standard**: ovale (inizio/fine), rettangolo (assegnazione), parallelogramma (I/O), rombo (decisione), esagono (for).
- Ridisegno solo quando cambia l'AST o la selezione; evitare `setState` sul canvas intero durante il pan.

---

## 8. Editor

- Tap su blocco → selezione; doppio tap → modifica contenuto.
- Long-press → menu: modifica, elimina, duplica, sposta su/giù, commento.
- **Undo/redo**: stack di `Program` immutabili, max 100 snapshot.
- Validazione continua: variabili non dichiarate, espressioni non valide → blocco con bordo rosso + messaggio.
- Autosalvataggio con debounce (2 s) nel file corrente.

---

## 9. Runtime

- Interprete basato su **generatore** (`Iterable<StepEvent>` / `sync*`) per l'esecuzione passo-passo:
  - ogni passo emette: id blocco corrente, snapshot variabili, eventuale output o richiesta input;
  - l'input sospende l'esecuzione fino alla risposta dell'utente.
- Modalità: **Passo**, **Esegui** (velocità regolabile 0.1–2 s/passo), **Esegui tutto**, **Stop**.
- Limite di sicurezza: 10.000 passi → errore "possibile ciclo infinito".
- Errori runtime (divisione per zero, tipo non valido, variabile non inizializzata) in italiano con evidenziazione del blocco.
- Pannello: tabella variabili (nome, tipo, valore, evidenziato se appena modificato) + console I/O.

---

## 10. Generazione codice

- Visitor sull'AST, un generatore per linguaggio: **Python**, **C**, **pseudocodice italiano**.
- Mapping tipi C: intero→`int`, reale→`double`, stringa→`char[256]`, booleano→`int` (o `stdbool.h`).
- Output in pannello con font monospazio, pulsante copia e condividi.
- Test: per ogni programma di esempio, snapshot del codice generato (`test/codegen/golden/`).

---

## 11. Export e condivisione

- **PNG**: `RepaintBoundary.toImage(pixelRatio: 3)`.
- **SVG**: generato dal `LayoutNode` (nessuna dipendenza).
- **PDF**: pacchetto `pdf`, pagina A4 con titolo e diagramma scalato; opzionale seconda pagina con il codice.
- Condivisione dei file `.flow` tramite share sheet: lo studente consegna il file al docente, senza piattaforme intermedie.
- Associazione estensione `.flow` (iOS `CFBundleDocumentTypes`/`UTExportedTypeDeclarations`, Android intent-filter).

---

## 12. Test

```bash
flutter test                    # tutti
flutter test test/runtime       # solo runtime
flutter test --coverage
```
- Obiettivo coverage ≥ 80% su `expr/`, `runtime/`, `codegen/`, `model/`.
- Programmi di esempio condivisi in `test/fixtures/*.flow` (max, media, fattoriale, numeri primi, tabelline, MCD).
- Widget test minimi su editor (inserimento, undo) e run panel.

---

## 13. Roadmap

| Fase | Contenuto | Criterio di completamento |
|---|---|---|
| **M1 — Modello** | AST, serializzazione JSON, parser espressioni | round-trip JSON e test parser verdi |
| **M2 — Visualizzazione** | layout engine, canvas, forme | fixture visualizzate correttamente su iPad e phone |
| **M3 — Editor** | inserimento, modifica, eliminazione, undo/redo, salvataggio | si crea da zero "massimo tra due numeri" |
| **M4 — Esecuzione** | interprete, pannello variabili, console | fixture eseguite con output atteso |
| **M5 — Codice ed export** | Python, C, pseudocodice; PNG/SVG/PDF | golden test verdi, export apribili |
| **M6 — Pubblicazione** | icona, schermate, privacy policy, store | app approvata su App Store e Play |
| Dopo | esercizi con verifica output, sottoprogrammi, array, tema scuro | — |

---

## 14. Pubblicazione store

- Posizionamento: **per insegnanti e studenti**, categoria **Education**.
- Apple privacy label: **Data Not Collected**. Google Data safety: nessun dato raccolto né condiviso. Google target audience: 18+.
- Privacy policy su davidebertolino.it, link nel README e nelle schede store.
- Testi store ammessi: "nessun account", "nessuna pubblicità", "nessuna raccolta dati", "i dati restano sul dispositivo", "codice pubblico e verificabile".
- Screenshot con diagrammi di esempio, nessun dato reale.
- Font solo con licenza OFL, inclusi negli asset (nessun download da CDN).

---

## 15. Comandi utili

```bash
flutter pub get
flutter run -d <device>                # flutter devices per l'elenco
flutter analyze
dart format .
flutter build ipa                      # iOS (poi Transporter / Xcode Organizer)
flutter build appbundle                # Android (.aab per Play Console)
dart run flutter_launcher_icons        # se usato per le icone (dev dependency)
```
