/* Media di n numeri */
/* Codice generato da DB Flow */

#include <stdio.h>

int main(void) {
    int n = 0;
    int i = 0;
    double x = 0.0;
    double somma = 0.0;

    // Chiede n finché non è positivo
    do {
        printf("Inserisci n: ");
        scanf("%d", &n);
    } while (n <= 0);
    somma = 0;
    for (i = 1; i <= n; i++) {
        printf("Inserisci x: ");
        scanf("%lf", &x);
        somma = somma + x;
    }
    printf("Media: %g\n", somma / n);
    return 0;
}
