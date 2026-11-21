/* Tabelline */
/* Codice generato da DB Flow */

#include <stdio.h>

int main(void) {
    int i = 0;
    int j = 0;

    for (i = 1; i <= 10; i++) {
        for (j = 1; j <= 10; j++) {
            printf("%d x %d = %d\n", i, j, i * j);
        }
    }
    return 0;
}
