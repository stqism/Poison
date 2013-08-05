#import "NKDummyDataSerializer.h"

@implementation NKDummyDataSerializer

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error {
    return YES;
}

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error {
    if (error)
        *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": @"Key was not saved", @"silence": @YES}];
    return nil;
}

- (BOOL)hasDataForOptions:(NSDictionary *)aDict {
    return NO;
}

@end
