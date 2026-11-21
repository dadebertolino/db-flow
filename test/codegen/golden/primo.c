/* Numero primo */
/* Codice generato da DB Flow */

#include <stdio.h>
#include <stdbool.h>

int main(void) {
    int n = 0;
    int d = 0;
    bool primo = false;

    printf("Inserisci n: ");
    scanf("%d", &n);
    primo = n >= 2;
    d = 2;
    while (d * d <= n && primo) {
        if (n % d == 0) {
            primo = false;
        }
        d = d + 1;
    }
    if (primo) {
        printf("%d è primo\n", n);
    } else {
        printf("%d non è primo\n", n);
    }
    return 0;
}
