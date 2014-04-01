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

#include "DESUserDiscovery.h"
#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    if (argc < 2) {
        puts("error: need an ID");
        return -1;
    }
    NSString *user = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    DESDiscoverUser(user, ^(NSString *result, NSError *error) {
        printf("%s\n", result? result.UTF8String : error.description.UTF8String);
        exit(0);
    });
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate distantFuture]];
    return 0;
}

