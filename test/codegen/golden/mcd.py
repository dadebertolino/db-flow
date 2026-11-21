# MCD (algoritmo di Euclide)
# Codice generato da DB Flow

a = 0
b = 0
r = 0
a = int(input("Inserisci a: "))
b = int(input("Inserisci b: "))
while b != 0:
    r = a % b
    a = b
    b = r
print("MCD = " + str(a))
