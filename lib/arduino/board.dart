/// Schede Arduino supportate. Dart puro.
///
/// Per aggiungere una scheda basta descriverla con un nuovo [Board] e
/// registrarla in [boards]: validazione, helper e generatore la usano da qui.
library;

import '../i18n/tr.dart';

/// Modo di un pin, come in `pinMode` (più l'ingresso analogico, che non ne ha bisogno).
enum PinMode {
  output('OUTPUT'),
  input('INPUT'),
  inputPullup('INPUT_PULLUP'),
  analogInput(null);

  const PinMode(this.arduino);

  /// Costante Arduino per `pinMode`, `null` se non serve.
  final String? arduino;

  /// Descrizione nella lingua corrente.
  String get label => switch (this) {
    output => tr.pinModeOutput,
    input => tr.pinModeInput,
    inputPullup => tr.pinModeInputPullup,
    analogInput => tr.pinModeAnalogInput,
  };

  bool get isInput => this != output;

  static PinMode? fromName(String n) {
    for (final m in values) {
      if (m.name == n) return m;
    }
    return null;
  }
}

final class Board {
  const Board({
    required this.id,
    required this.name,
    required this.fqbn,
    required this.digitalPins,
    required this.analogPins,
    required this.pwmPins,
    required this.serialPins,
    required this.analogBase,
    this.analogOnlyPins = const {},
    this.analogAliases = const {},
    this.ledBuiltin = '13',
    this.analogMax = 1023,
    this.pwmMax = 255,
    this.drawing,
  });

  /// Identificativo salvato nel file.
  final String id;

  /// Nome mostrato.
  final String name;

  /// Fully Qualified Board Name per arduino-cli (usato nei test di compilazione).
  final String fqbn;

  /// Pin digitali, come si scrivono nel codice (`"2"`, `"13"`).
  final List<String> digitalPins;

  /// Ingressi analogici (`"A0"` …). Sulla Uno valgono anche come pin digitali.
  final List<String> analogPins;

  /// Pin che supportano `analogWrite` (PWM).
  final Set<String> pwmPins;

  /// Pin usati dalla comunicazione seriale (USB).
  final Set<String> serialPins;

  /// Numero del pin A0 (A1 = A0 + 1 …).
  final int analogBase;

  /// Ingressi solo analogici (A6 e A7 su Nano e Pro Mini): niente
  /// `digitalRead`/`digitalWrite` né `pinMode`.
  final Set<String> analogOnlyPins;

  /// Ingressi analogici che sono anche pin digitali con un altro nome (Micro:
  /// A6 è il pin 4, …). Nome analogico → nome digitale.
  final Map<String, String> analogAliases;

  final String ledBuiltin;
  final int analogMax;
  final int pwmMax;

  /// Geometria per il disegno della scheda (`null` se non disponibile).
  final BoardDrawing? drawing;

  List<String> get allPins => [...digitalPins, ...analogPins];

  bool isValidPin(String pin) => digitalPins.contains(pin) || analogPins.contains(pin);

  bool isAnalog(String pin) => analogPins.contains(pin);

  /// Numero del pin (`"A0"` → 14 sulla Uno), `null` se non esiste.
  int? pinNumber(String pin) {
    if (digitalPins.contains(pin)) return int.parse(pin);
    final i = analogPins.indexOf(pin);
    return i < 0 ? null : analogBase + i;
  }

  /// Nome del pin dato il numero (14 → `"A0"`).
  String? pinName(int n) {
    if (digitalPins.contains('$n')) return '$n';
    final i = n - analogBase;
    return i >= 0 && i < analogPins.length ? analogPins[i] : null;
  }

  bool isAnalogOnly(String pin) => analogOnlyPins.contains(pin);

  /// Nome del pin fisico: per gli alias analogici il pin digitale (A6 → 4).
  String physical(String pin) => analogAliases[pin] ?? pin;

  /// Stesso pin fisico (es. 4 e A6 sulla Micro).
  bool samePin(String a, String b) => physical(a) == physical(b);

  /// Nome analogico di un pin digitale, se ne ha uno (4 → A6).
  String? analogNameOf(String digital) {
    for (final MapEntry(:key, :value) in analogAliases.entries) {
      if (value == digital) return key;
    }
    return null;
  }

  /// Pin fisici, senza gli alias analogici (per il disegno).
  List<String> get physicalPins => [
    for (final p in allPins)
      if (!analogAliases.containsKey(p)) p,
  ];

  /// Modi ammessi per un pin.
  List<PinMode> modesFor(String pin) => [
    if (!isAnalogOnly(pin)) ...[PinMode.output, PinMode.input, PinMode.inputPullup],
    if (isAnalog(pin)) PinMode.analogInput,
  ];
}

const arduinoUno = Board(
  id: 'uno',
  name: 'Arduino Uno',
  fqbn: 'arduino:avr:uno',
  digitalPins: _d14,
  analogPins: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'],
  pwmPins: {'3', '5', '6', '9', '10', '11'},
  serialPins: {'0', '1'},
  analogBase: 14,
  drawing: BoardDrawing(
    width: 68.6,
    height: 53.3,
    headers: [
      HeaderStrip(
        x: 18.0,
        y: 2.54,
        side: Side.top,
        labels: ['SCL', 'SDA', 'AREF', 'GND', '13', '12', '11', '10', '9', '8'],
      ),
      HeaderStrip(
        x: 45.0,
        y: 2.54,
        side: Side.top,
        labels: ['7', '6', '5', '4', '3', '2', '1', '0'],
      ),
      HeaderStrip(
        x: 27.9,
        y: 50.8,
        side: Side.bottom,
        labels: ['', 'IOREF', 'RESET', '3.3V', '5V', 'GND', 'GND', 'VIN'],
      ),
      HeaderStrip(
        x: 50.8,
        y: 50.8,
        side: Side.bottom,
        labels: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'],
      ),
    ],
    holes: [(x: 14.0, y: 2.5), (x: 15.3, y: 50.8), (x: 66.0, y: 7.6), (x: 66.0, y: 35.5)],
    usb: (x: -6.2, y: 9.5, w: 16.0, h: 12.0),
    jack: (x: -1.8, y: 38.5, w: 13.5, h: 9.0),
    chip: (x: 29.0, y: 33.0, w: 35.0, h: 8.0),
    ledL: (x: 26.0, y: 9.0),
    title: (x: 12.5, y: 27.0, size: 3.2),
    digitalTitle: (x: 40.0, y: 13.5),
    analogTitle: (x: 57.0, y: 44.5),
  ),
);

const _d14 = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13'];

/// Nano: piedinatura della Uno più A6 e A7, che sono solo analogici.
const arduinoNano = Board(
  id: 'nano',
  name: 'Arduino Nano',
  fqbn: 'arduino:avr:nano',
  digitalPins: _d14,
  analogPins: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'],
  analogOnlyPins: {'A6', 'A7'},
  pwmPins: {'3', '5', '6', '9', '10', '11'},
  serialPins: {'0', '1'},
  analogBase: 14,
  drawing: BoardDrawing(
    width: 43.2,
    height: 18.5,
    headers: [
      HeaderStrip(
        x: 4.6,
        y: 1.5,
        side: Side.top,
        labels: ['12', '11', '10', '9', '8', '7', '6', '5', '4', '3', '2', 'GND', 'RST', '0', '1'],
      ),
      HeaderStrip(
        x: 4.6,
        y: 17.0,
        side: Side.bottom,
        labels: [
          '13', '3.3V', 'AREF', 'A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', '5V', 'RST', //
          'GND', 'VIN',
        ],
      ),
    ],
    usb: (x: -1.8, y: 5.5, w: 7.5, h: 7.5),
    chip: (x: 21.0, y: 6.1, w: 6.4, h: 6.4),
    ledL: (x: 11.0, y: 9.25),
    title: (x: 29.0, y: 9.25, size: 1.8),
  ),
);

/// Pro Mini (5 V, 16 MHz): senza USB, si programma con un adattatore seriale
/// sul connettore a sinistra, che usa i pin 0 e 1.
const arduinoProMini = Board(
  id: 'promini',
  name: 'Arduino Pro Mini',
  fqbn: 'arduino:avr:pro',
  digitalPins: _d14,
  analogPins: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'],
  analogOnlyPins: {'A6', 'A7'},
  pwmPins: {'3', '5', '6', '9', '10', '11'},
  serialPins: {'0', '1'},
  analogBase: 14,
  // Disegno più alto della scheda vera (18 mm), altrimenti le etichette non ci stanno.
  drawing: BoardDrawing(
    width: 33.0,
    height: 22.0,
    headers: [
      HeaderStrip(
        x: 4.4,
        y: 1.4,
        side: Side.top,
        labels: ['1', '0', 'RST', 'GND', '2', '3', '4', '5', '6', '7', '8', '9'],
      ),
      HeaderStrip(
        x: 4.4,
        y: 20.6,
        side: Side.bottom,
        labels: ['RAW', 'GND', 'RST', 'VCC', 'A3', 'A2', 'A1', 'A0', '13', '12', '11', '10'],
      ),
      // piazzole interne, raccolte in una colonna
      HeaderStrip(x: 29.6, y: 7.2, side: Side.right, labels: ['A4', 'A5', 'A6', 'A7']),
      // connettore per l'adattatore seriale (GND, CTS, VCC, RXI, TXO, DTR): niente da configurare
      HeaderStrip(x: 1.4, y: 4.65, side: Side.left, labels: ['', '', '', '', '', '']),
    ],
    chip: (x: 10.0, y: 7.8, w: 6.4, h: 6.4),
    ledL: (x: 20.5, y: 9.0),
  ),
);

/// Micro (ATmega32U4): USB nativa, quindi i pin 0 e 1 restano liberi; A0–A5
/// sono i pin 18–23. A6–A11 (24–29) sono i pin digitali 4, 6, 8, 9, 10, 12
/// letti come ingressi analogici: con quel nome si usano solo con analogRead.
const arduinoMicro = Board(
  id: 'micro',
  name: 'Arduino Micro',
  fqbn: 'arduino:avr:micro',
  digitalPins: _d14,
  analogPins: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9', 'A10', 'A11'],
  analogOnlyPins: {'A6', 'A7', 'A8', 'A9', 'A10', 'A11'},
  analogAliases: {'A6': '4', 'A7': '6', 'A8': '8', 'A9': '9', 'A10': '10', 'A11': '12'},
  pwmPins: {'3', '5', '6', '9', '10', '11', '13'},
  serialPins: {},
  analogBase: 18,
  // Disegno più alto della scheda vera (18 mm), per le etichette doppie (~9/A9).
  drawing: BoardDrawing(
    width: 48.0,
    height: 22.0,
    headers: [
      HeaderStrip(
        x: 4.0,
        y: 1.4,
        side: Side.top,
        labels: [
          '12', '11', '10', '9', '8', '7', '6', '5', '4', '3', '2', 'GND', 'RST', '0', '1', //
          'SS', 'MOSI',
        ],
      ),
      HeaderStrip(
        x: 4.0,
        y: 20.6,
        side: Side.bottom,
        labels: [
          '13', '3.3V', 'AREF', 'A0', 'A1', 'A2', 'A3', 'A4', 'A5', '', '', '5V', 'RST', //
          'GND', 'VIN', 'MISO', 'SCK',
        ],
      ),
    ],
    usb: (x: -1.0, y: 9.0, w: 6.0, h: 6.0),
    chip: (x: 19.5, y: 9.6, w: 6.4, h: 6.4),
    ledL: (x: 10.0, y: 12.5),
    title: (x: 28.5, y: 12.8, size: 1.8),
  ),
);

/// Mega 2560: 54 pin digitali (PWM 2–13 e 44–46), 16 ingressi analogici.
const arduinoMega = Board(
  id: 'mega',
  name: 'Arduino Mega 2560',
  fqbn: 'arduino:avr:mega',
  digitalPins: [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46',
    '47',
    '48',
    '49',
    '50',
    '51',
    '52',
    '53',
  ],
  analogPins: [
    'A0',
    'A1',
    'A2',
    'A3',
    'A4',
    'A5',
    'A6',
    'A7',
    'A8',
    'A9',
    'A10',
    'A11',
    'A12',
    'A13',
    'A14',
    'A15',
  ],
  pwmPins: {'2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '44', '45', '46'},
  serialPins: {'0', '1'},
  analogBase: 54,
  drawing: BoardDrawing(
    width: 101.6,
    height: 53.3,
    headers: [
      HeaderStrip(
        x: 18.0,
        y: 2.54,
        side: Side.top,
        labels: ['SCL', 'SDA', 'AREF', 'GND', '13', '12', '11', '10', '9', '8'],
      ),
      HeaderStrip(
        x: 45.0,
        y: 2.54,
        side: Side.top,
        labels: ['7', '6', '5', '4', '3', '2', '1', '0'],
      ),
      HeaderStrip(
        x: 66.04,
        y: 2.54,
        side: Side.top,
        labels: ['14', '15', '16', '17', '18', '19', '20', '21'],
      ),
      HeaderStrip(
        x: 27.9,
        y: 50.8,
        side: Side.bottom,
        labels: ['', 'IOREF', 'RESET', '3.3V', '5V', 'GND', 'GND', 'VIN'],
      ),
      HeaderStrip(
        x: 50.8,
        y: 50.8,
        side: Side.bottom,
        labels: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7'],
      ),
      HeaderStrip(
        x: 73.66,
        y: 50.8,
        side: Side.bottom,
        labels: ['A8', 'A9', 'A10', 'A11', 'A12', 'A13', 'A14', 'A15'],
      ),
      // doppio connettore: colonna interna (pari) verso sinistra, esterna (dispari) verso destra
      HeaderStrip(
        x: 95.0,
        y: 4.0,
        side: Side.left,
        labels: [
          '',
          '22',
          '24',
          '26',
          '28',
          '30',
          '32',
          '34',
          '36',
          '38',
          '40',
          '42',
          '44',
          '46',
          '48',
          '50',
          '52',
          '',
        ],
      ),
      HeaderStrip(
        x: 97.54,
        y: 4.0,
        side: Side.right,
        labels: [
          '5V',
          '23',
          '25',
          '27',
          '29',
          '31',
          '33',
          '35',
          '37',
          '39',
          '41',
          '43',
          '45',
          '47',
          '49',
          '51',
          '53',
          'GND',
        ],
      ),
    ],
    holes: [(x: 14.0, y: 2.5), (x: 15.3, y: 50.8), (x: 66.0, y: 35.5), (x: 90.2, y: 2.5)],
    usb: (x: -6.2, y: 9.5, w: 16.0, h: 12.0),
    jack: (x: -1.8, y: 38.5, w: 13.5, h: 9.0),
    chip: (x: 42.0, y: 22.0, w: 14.0, h: 14.0),
    ledL: (x: 26.0, y: 9.0),
    title: (x: 12.5, y: 27.0, size: 3.2),
    digitalTitle: (x: 50.0, y: 13.5),
    analogTitle: (x: 71.0, y: 44.5),
  ),
);

/// Schede disponibili, nell'ordine del menu.
const boards = {
  'uno': arduinoUno,
  'nano': arduinoNano,
  'promini': arduinoProMini,
  'micro': arduinoMicro,
  'mega': arduinoMega,
};

Board boardById(String id) => boards[id] ?? arduinoUno;

/// Velocità della seriale proposte.
const baudRates = [9600, 19200, 38400, 57600, 115200];

/// Componente collegato a un pin. Determina il modo proposto e i pin adatti.
/// Per aggiungerne uno (servo, buzzer…) basta una nuova voce qui e in [Tr].
enum Component {
  led,
  button,
  potentiometer,
  other;

  /// Nome nella lingua corrente.
  String get label => switch (this) {
    led => tr.componentLed,
    button => tr.componentButton,
    potentiometer => tr.componentPotentiometer,
    other => tr.componentOther,
  };

  /// Modo proposto quando si sceglie il componente.
  PinMode get defaultMode => switch (this) {
    led => PinMode.output,
    button => PinMode.inputPullup,
    potentiometer => PinMode.analogInput,
    other => PinMode.output,
  };

  /// Modi sensati per il componente.
  List<PinMode> get modes => switch (this) {
    led => const [PinMode.output],
    button => const [PinMode.inputPullup, PinMode.input],
    potentiometer => const [PinMode.analogInput],
    other => PinMode.values,
  };

  /// Il componente si può collegare a [pin] di [board] con il modo [mode]?
  bool fits(Board board, String pin, PinMode mode) =>
      board.isValidPin(pin) && modes.contains(mode) && board.modesFor(pin).contains(mode);

  static Component fromName(String? n) {
    for (final c in values) {
      if (c.name == n) return c;
    }
    return other;
  }
}

/// Un pin con nome, come `const int LED = 13;`, e il componente collegato.
final class PinConfig {
  const PinConfig({
    required this.name,
    required this.pin,
    required this.mode,
    this.component = Component.other,
  });
  final String name;
  final String pin;
  final PinMode mode;
  final Component component;

  PinConfig copyWith({String? name, String? pin, PinMode? mode, Component? component}) => PinConfig(
    name: name ?? this.name,
    pin: pin ?? this.pin,
    mode: mode ?? this.mode,
    component: component ?? this.component,
  );
}

/// Configurazione hardware di un diagramma Arduino.
final class ArduinoConfig {
  ArduinoConfig({this.boardId = 'uno', this.baud = 9600, List<PinConfig> pins = const []})
    : pins = List.unmodifiable(pins);

  final String boardId;
  final int baud;
  final List<PinConfig> pins;

  Board get board => boardById(boardId);

  PinConfig? pinNamed(String name) {
    for (final p in pins) {
      if (p.name == name) return p;
    }
    return null;
  }

  ArduinoConfig copyWith({String? boardId, int? baud, List<PinConfig>? pins}) => ArduinoConfig(
    boardId: boardId ?? this.boardId,
    baud: baud ?? this.baud,
    pins: pins ?? this.pins,
  );
}

// ---------------------------------------------------------------- disegno

typedef MmRect = ({double x, double y, double w, double h});
typedef MmPoint = ({double x, double y});

/// Lato verso cui escono i richiami (linea, icona e nome) dei pin di una fila.
enum Side {
  top,
  bottom,
  left,
  right;

  bool get vertical => this == left || this == right;
}

/// Fila di pin: centro del primo pin in ([x], [y]) mm, gli altri ogni 2,54 mm
/// verso destra (file orizzontali, [side] sopra o sotto) o verso il basso (file
/// verticali, [side] a sinistra o a destra). [labels] vuote = pin non usabile.
final class HeaderStrip {
  const HeaderStrip({required this.x, required this.y, required this.labels, required this.side});
  final double x;
  final double y;
  final List<String> labels;
  final Side side;

  static const pitch = 2.54;

  /// Centro del pin [i].
  MmPoint pin(int i) => side.vertical ? (x: x, y: y + i * pitch) : (x: x + i * pitch, y: y);
}

/// Geometria semplificata di una scheda, in millimetri, con l'origine in alto
/// a sinistra e il connettore USB (o di programmazione) a sinistra.
final class BoardDrawing {
  const BoardDrawing({
    required this.width,
    required this.height,
    required this.headers,
    required this.chip,
    required this.ledL,
    this.holes = const [],
    this.usb,
    this.jack,
    this.title,
    this.digitalTitle,
    this.analogTitle,
  });

  final double width;
  final double height;
  final List<HeaderStrip> headers;
  final MmRect chip;

  /// LED "L" collegato al pin del LED integrato.
  final MmPoint ledL;

  /// Fori di fissaggio.
  final List<MmPoint> holes;
  final MmRect? usb;

  /// Presa di alimentazione (non c'è sulle schede piccole).
  final MmRect? jack;

  /// Nome della scheda stampato sul circuito (`null`: non c'è spazio).
  final ({double x, double y, double size})? title;
  final MmPoint? digitalTitle;
  final MmPoint? analogTitle;

  /// Centro del pin con etichetta [label] e lato dei richiami.
  ({double x, double y, Side side})? pinCenter(String label) {
    for (final h in headers) {
      final i = h.labels.indexOf(label);
      if (i >= 0) {
        final p = h.pin(i);
        return (x: p.x, y: p.y, side: h.side);
      }
    }
    return null;
  }

  /// Richiami a sinistra fuori dalla scheda (servono margini più larghi).
  bool get hasLeftCallouts => headers.any(
    (h) => h.side == Side.left && h.x < width / 2 && h.labels.any((l) => l.isNotEmpty),
  );
  bool get hasRightCallouts => headers.any((h) => h.side == Side.right);
}
