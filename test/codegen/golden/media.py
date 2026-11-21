# Media di n numeri
# Codice generato da DB Flow

n = 0
i = 0
x = 0.0
somma = 0.0
# Chiede n finché non è positivo
while True:
    n = int(input("Inserisci n: "))
    if not (n <= 0):
        break
somma = 0
for i in range(1, n + 1):
    x = float(input("Inserisci x: ").replace(",", "."))
    somma = somma + x
print("Media: " + str(somma / n))
