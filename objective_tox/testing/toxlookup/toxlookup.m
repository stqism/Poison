/**********************************************
 * toxlookup is a tool for testing the DNS user
 * discovery code in OTox. It should function
 * exactly like dig (user)._tox.(domain) for
 * (user)@(domain).
 *
 * Copyright (c) 2014 Zodiac Labs.
 * You are free to do whatever you want with
 * this file -- provided this notice is
 * retained.
 **********************************************/

#ifdef __OBJC__
#include "DESUserDiscovery.h"
#import <Foundation/Foundation.h>
#endif

void convert_hex2bin(const char *i, uint8_t *o, int l) {
    int j = 0, k = 0;
    char c[3] = {'\0','\0','\0'};
    unsigned long b = 0;
    while (j < l) {
        c[0] = i[j++];
        c[1] = i[j++];
        b = strtoul(c, NULL, 16);
        o[k++] = b;
    }
}

uint16_t quicksum_init(uint8_t *address, uint32_t len) {
    uint8_t checksum[2] = {0};
    uint16_t check;
    uint32_t i;

    for (i = 0; i < len; ++i)
        checksum[i % 2] ^= address[i];

    memcpy(&check, checksum, sizeof(check));
    return check;
}

uint16_t quicksum_do(uint16_t init, uint8_t *address, uint32_t len) {
    uint8_t *checksum = (uint8_t *)&init;
    uint16_t check;
    uint32_t i;

    for (i = 0; i < len; ++i)
        checksum[i % 2] ^= address[i];

    memcpy(&check, checksum, sizeof(check));
    return check;
}

int main(int argc, const char * argv[]) {
    if (argc < 3) {
        puts("error: need an ID");
        return -1;
    }
    if (!strcmp(argv[1], "-l")) {
#ifdef __OBJC__
        NSString *user = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        DESDiscoverUser(user, ^(NSDictionary *result, NSError *error) {
            printf("%s\n", result? result.description.UTF8String : error.description.UTF8String);
            exit(0);
        });
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate distantFuture]];
#else
        puts("error: -l is only supported when compiled as an Objective-C program")
#endif
    } else if (!strcmp(argv[1], "-r")) {
        uint8_t k[32];
        uint8_t c[2];
        uint16_t c_cmp = 0;

        convert_hex2bin(argv[2], k, 64);
        convert_hex2bin(argv[3], c, 4);
        memcpy(&c_cmp, c, 2);

        uint16_t quicksum = quicksum_init(k, 32);
        for (uint32_t i = 0; i < UINT32_MAX; ++i) {
            if (i % 100000 == 0) {
                printf(".");
            }
            if (quicksum_do(quicksum, (uint8_t *)&i, 4) == c_cmp) {
                uint8_t c2[36];
                memcpy(c2, k, 32);
                memcpy(c2 + 32, &i, 4);
                int check = quicksum_init(c2, 36);
                if (check == c_cmp)
                    printf("\nfound it: it was %u %hu\n", i, c_cmp);
            }
        }
    }
    return 0;
}

