/* Fattoriale */
/* Codice generato da DB Flow */

#include <stdio.h>

int main(void) {
    int n = 0;
    int i = 0;
    int f = 0;

    printf("Inserisci n: ");
    scanf("%d", &n);
    f = 1;
    for (i = 2; i <= n; i++) {
        f = f * i;
    }
    printf("%d! = %d\n", n, f);
    return 0;
}
