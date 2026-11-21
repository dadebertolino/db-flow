# Massimo tra due numeri
# Codice generato da DB Flow

a = 0
b = 0
massimo = 0
a = int(input("Inserisci a: "))
b = int(input("Inserisci b: "))
if a > b:
    massimo = a
else:
    massimo = b
print("Il massimo è " + str(massimo))
