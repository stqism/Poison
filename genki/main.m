#include <stdio.h>
#include <sodium.h>
#import <Foundation/Foundation.h>

void mkdata(NSString *theString, uint8_t *theOutput) {
    const char *chars = [theString UTF8String];
    int i = 0, j = 0;
    NSUInteger len = [theString length];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte = 0;
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        theOutput[j++] = wholeByte;
    }
}

NSString *mkstring(const uint8_t *theData) {
    NSMutableString *theString = [[NSMutableString alloc] initWithCapacity:crypto_box_PUBLICKEYBYTES * 2];
    for (NSInteger idx = 0; idx < crypto_box_PUBLICKEYBYTES; ++idx) {
        [theString appendFormat:@"%02X", theData[idx]];
    }
    return (NSString*)theString;
}

int main(int argc, const char * argv[]) {
    if (argc < 2) {
        printf("Usage: %s <pattern>.\n", argv[0]);
        exit(1);
    }
    uint8_t *match = malloc(strlen(argv[1]) / 2);
    size_t z = strlen(argv[1]) / 2;
    NSString *ns = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
    mkdata(ns, match);
    [ns release];
    uint8_t *temp_pub = malloc(crypto_box_PUBLICKEYBYTES);
    uint8_t *temp_priv = malloc(crypto_box_SECRETKEYBYTES);
    while (1) {
        crypto_box_keypair(temp_pub, temp_priv);
        if (!memcmp(match, temp_pub, z)) {
            NSString *hex = mkstring(temp_pub);
            NSString *hex2 = mkstring(temp_priv);
            printf("Match. Pub:%s Priv:%s\n", [hex UTF8String], [hex2 UTF8String]);
            [hex release];
            [hex2 release];
        }
    }
    free(temp_priv);
    free(temp_pub);
    free(match);
    return 0;
}

