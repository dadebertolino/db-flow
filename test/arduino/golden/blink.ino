// Blink: LED lampeggiante
// Codice generato da DB Flow per Arduino Uno
//
// Collegamenti:
//   LED          pin 13  (LED, uscita)

const int LED = 13;

void setup() {
  pinMode(LED, OUTPUT);
}

void loop() {
  digitalWrite(LED, HIGH);
  delay(500);
  digitalWrite(LED, LOW);
  delay(500);
}
