// Dimmer con potenziometro
// Codice generato da DB Flow per Arduino Uno
//
// Collegamenti:
//   POT          pin A0  (Potenziometro, ingresso analogico)
//   LED          pin 9   (LED, uscita)

const int POT = A0;
const int LED = 9;

long valore = 0;
long luminosita = 0;

void setup() {
  pinMode(LED, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  valore = analogRead(POT);
  luminosita = (long) ((float) valore / 4);
  analogWrite(LED, luminosita);
  Serial.print("Potenziometro: ");
  Serial.print(valore);
  Serial.print("  LED: ");
  Serial.println(luminosita);
  delay(100);
}
