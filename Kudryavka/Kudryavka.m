#import "Kudryavka.h"
#import "NKKeychainDataSerializer.h"
#import "NKCryptedFileDataSerializer.h"
#import "NKDummyDataSerializer.h"
#import "NKKeyServerSerializer.h"

@class NKKeychainDataSerializer, NKCryptedFileDataSerializer, NKDummyDataSerializer;

@implementation NKDataSerializer

+ (NKDataSerializer *)serializerUsingMethod:(NKSerializerType)method {
    NKDebug(@"start");
    switch (method) {
        case NKSerializerKeychain:
            return [[NKKeychainDataSerializer alloc] init];
        case NKSerializerCustomFile:
            return [[NKDummyDataSerializer alloc] init];
        case NKSerializerNoop:
            return [[NKDummyDataSerializer alloc] init];
        case NKSerializerKeyserver:
            return [[NKKeyServerSerializer alloc] init];
        default:
            return nil;
    }
}

+ (BOOL)isDebugBuild {
    #ifdef KUD_DEBUG
    return YES;
    #else
    return NO;
    #endif
}

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error {
    [NSException raise:@"NKAbstractClassException" format:@"You idiot."];
    return NO;
}

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error {
    [NSException raise:@"NKAbstractClassException" format:@"You idiot."];
    return nil;
}

- (BOOL)hasDataForOptions:(NSDictionary *)aDict {
    [NSException raise:@"NKAbstractClassException" format:@"You idiot."];
    return NO;
}

@end