#include <stdio.h>
#include <sodium.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

struct searchinfo {
    uint8_t *match;
    size_t z;
    pthread_mutex_t lk;
};

void mkdata(const char *theString, uint8_t *theOutput) {
    int i = 0, j = 0;
    size_t len = strlen(theString);
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte = 0;
    while (i < len) {
        byteChars[0] = theString[i++];
        byteChars[1] = theString[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        theOutput[j++] = wholeByte;
    }
}

char *mkstring(const uint8_t *theData) {
    char *theString = malloc(crypto_box_PUBLICKEYBYTES * 2 + 1);
    int ic = 0;
    for (int idx = 0; idx < crypto_box_PUBLICKEYBYTES; ++idx) {
        sprintf(theString + ic, "%02X", theData[idx]);
        ic += 2;
    }
    return theString;
}

void *thread_run(void *s) {
    uint8_t *temp_pub = malloc(crypto_box_PUBLICKEYBYTES);
    uint8_t *temp_priv = malloc(crypto_box_SECRETKEYBYTES);
    uint8_t *match = ((struct searchinfo*)s)->match;
    size_t z = ((struct searchinfo*)s)->z;
    pthread_mutex_t lk = ((struct searchinfo*)s)->lk;
    while (1) {
        crypto_box_keypair(temp_pub, temp_priv);
        if (!memcmp(match, temp_pub, z)) {
            char *hex = mkstring(temp_pub);
            char *hex2 = mkstring(temp_priv);
            pthread_mutex_lock(&lk);
            printf("Match. Pub:%s Priv:%s\n", hex, hex2);
            pthread_mutex_unlock(&lk);
            free(hex2);
            free(hex);
        }
    }
    free(temp_priv);
    free(temp_pub);
    return NULL;
}

int main(int argc, const char * argv[]) {
    if (argc < 3) {
        printf("Usage: %s <nthreads> <pattern>.\n", argv[0]);
        exit(1);
    }
    uint8_t *match = malloc(strlen(argv[2]) / 2);
    size_t z = strlen(argv[2]) / 2;
    int cnt = atoi(argv[1]);
    if (!cnt) {
        exit(0);
    }
    mkdata(argv[2], match);
    struct searchinfo s;
    s.match = match;
    s.z = z;
    pthread_mutex_init(&s.lk, NULL);
    pthread_t thread;
    for (int i = 0; i < cnt - 1; i++) {
        pthread_create(&thread, NULL, thread_run, &s);
        printf("Thread %i running.\n", i);
    }
    thread_run(&s);
    free(match);
    return 0;
}

