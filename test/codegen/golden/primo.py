# Numero primo
# Codice generato da DB Flow

n = 0
d = 0
primo = False
n = int(input("Inserisci n: "))
primo = n >= 2
d = 2
while d * d <= n and primo:
    if n % d == 0:
        primo = False
    d = d + 1
if primo:
    print(str(n) + " è primo")
else:
    print(str(n) + " non è primo")
