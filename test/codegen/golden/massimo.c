/* Massimo tra due numeri */
/* Codice generato da DB Flow */

#include <stdio.h>

int main(void) {
    int a = 0;
    int b = 0;
    int massimo = 0;

    printf("Inserisci a: ");
    scanf("%d", &a);
    printf("Inserisci b: ");
    scanf("%d", &b);
    if (a > b) {
        massimo = a;
    } else {
        massimo = b;
    }
    printf("Il massimo è %d\n", massimo);
    return 0;
}
