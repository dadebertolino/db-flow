// LED comandato da un pulsante
// Codice generato da DB Flow per Arduino Uno
//
// Collegamenti:
//   LED          pin 13  (LED, uscita)
//   PULSANTE     pin 2   (Pulsante, ingresso con pull-up)

const int LED = 13;
const int PULSANTE = 2;

long stato = 0;

void setup() {
  pinMode(LED, OUTPUT);
  pinMode(PULSANTE, INPUT_PULLUP);
  // Pulsante tra il pin 2 e GND: premuto = LOW
}

void loop() {
  stato = digitalRead(PULSANTE);
  if (stato == LOW) {
    digitalWrite(LED, HIGH);
  } else {
    digitalWrite(LED, LOW);
  }
  delay(10);
}
