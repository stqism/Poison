#import <Foundation/Foundation.h>
#import "ObjectiveTox.h"

@interface ImoutoBot : NSObject <DESToxConnectionDelegate, DESConversationDelegate>
@end

@implementation ImoutoBot

- (void)connectionDidBecomeEstablished:(DESToxConnection *)connection {
    puts("Connected!");
}

@end

int main(int argc, const char * argv[]) {
    printf("DESImouto 0.0.1, (c) 2014 Zodiac Labs.\n");
    @autoreleasepool {
        DESToxConnection *tox = [[DESToxConnection alloc] init];
        NSLog(@"DESImouto's FA: %@", tox.friendAddress);
        [tox start];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate distantFuture]];
    }
    return 0;
}

