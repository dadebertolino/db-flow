# DB Flow

Diagrammi di flusso **strutturati ed eseguibili**, per insegnanti e per chi impara a programmare.
Per iPhone, iPad, Android e Mac. Gratuita, senza pubblicità, senza account, senza raccolta dati.

**Scarica**: [App Store](https://apps.apple.com/app/id6835826427) (iPhone, iPad e Mac) · [Google Play](https://play.google.com/store/apps/details?id=it.davidebertolino.dbflow) (Android) · [sito e supporto](https://www.davidebertolino.it/db-flow/). Windows in arrivo.

## Cosa fa

- **Diagrammi sempre validi**: si costruisce l'algoritmo inserendo i blocchi sulle frecce; il diagramma si dispone da solo e non può essere "rotto".
- **Esecuzione passo-passo**: blocco corrente evidenziato, tabella delle variabili, console per input e output, velocità regolabile.
- **Codice generato**: pseudocodice, Python, C e sketch Arduino. Nei test il Python e il C generati vengono eseguiti davvero, gli sketch compilati con `arduino-cli` per ogni scheda.
- **Esercizi con verifica dell'output**: il docente scrive la consegna e i casi di prova (visibili o nascosti) e condivide l'esercizio senza la soluzione; lo studente costruisce il diagramma e lo verifica. Dieci esercizi sono già inclusi.
- **Arduino**:
  - diagrammi `setup()`/`loop()` con `digitalRead`, `digitalWrite`, `analogRead`, `analogWrite`, `delay`, `millis()`;
  - schede Uno, Nano, Pro Mini, Micro e Mega 2560, con il disegno interattivo dei pin e i controlli su PWM, ingressi e pin seriali;
  - **simulazione** nell'app: LED, pulsanti, potenziometri, con i tempi reali dei `delay`;
  - sketch `.ino` pronto per l'Arduino IDE.
- **Export e condivisione**: PNG, SVG, PDF e file `.flow`, passati direttamente tra persone (AirDrop, Mail, File); i `.flow` ricevuti si aprono toccandoli.
- **Cinque lingue** (italiano, inglese, francese, tedesco, spagnolo), con la terminologia scolastica di ogni paese; tema chiaro e scuro.

## Privacy

- Nessun account, nessuna pubblicità, nessuna raccolta dati: i diagrammi restano sul dispositivo.
- L'app non usa internet. Nessun SDK di analisi, pubblicità o segnalazione degli errori: lo verifica a ogni modifica il controllo automatico in [`tool/check_denylist.sh`](tool/check_denylist.sh), e `test/privacy_test.dart` fallisce se nel codice compare un accesso alla rete.
- Il codice è pubblico: **chiunque può verificare** che l'app si comporti come descritto nell'[informativa sulla privacy](https://www.davidebertolino.it/db-flow-privacy/).

L'informativa è nell'app (Informazioni › Informativa sulla privacy) e sul sito; la pagina del sito è generata dagli stessi testi dell'app ([`tool/privacy/`](tool/privacy/)).

## Licenza

[PolyForm Noncommercial 1.0.0](LICENSE.md): il codice è pubblico (source-available) e si può usare, studiare e modificare liberamente per scopi non commerciali, come la scuola. L'app resta gratuita, senza acquisti in-app.

## Sviluppo

Guida in [SVILUPPO.md](SVILUPPO.md); stato del progetto e decisioni in [STATO.md](STATO.md).

```bash
flutter pub get
flutter test                 # i test Arduino compilano gli sketch se trovano arduino-cli
flutter run -d <dispositivo>
```

- Flutter 3.47.2; arduino-cli 1.6.0 con il core `arduino:avr` 1.8.8 (gli stessi della CI).
- `lib/model`, `lib/expr`, `lib/runtime`, `lib/codegen`, `lib/layout`, `lib/arduino` e `lib/i18n` sono Dart puro (nessun import di Flutter), testabili senza interfaccia.
- Snapshot del codice generato: `UPDATE_GOLDENS=1 flutter test test/codegen test/arduino`.
- Pagina dell'informativa per il sito: `flutter test tool/privacy/render_privacy_page_test.dart`.

## Autore

Davide Bertolino — [davidebertolino.it](https://davidebertolino.it) · info@davidebertolino.it
