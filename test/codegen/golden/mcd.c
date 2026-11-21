/* MCD (algoritmo di Euclide) */
/* Codice generato da DB Flow */

#include <stdio.h>

int main(void) {
    int a = 0;
    int b = 0;
    int r = 0;

    printf("Inserisci a: ");
    scanf("%d", &a);
    printf("Inserisci b: ");
    scanf("%d", &b);
    while (b != 0) {
        r = a % b;
        a = b;
        b = r;
    }
    printf("MCD = %d\n", a);
    return 0;
}
