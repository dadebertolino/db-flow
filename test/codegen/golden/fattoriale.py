# Fattoriale
# Codice generato da DB Flow

n = 0
i = 0
f = 0
n = int(input("Inserisci n: "))
f = 1
for i in range(2, n + 1):
    f = f * i
print(str(n) + "! = " + str(f))
