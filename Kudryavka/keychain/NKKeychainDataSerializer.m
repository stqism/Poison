#import <DeepEnd/DeepEnd.h>
#import <Security/Security.h>
#import "NKKeychainDataSerializer.h"

@implementation NKKeychainDataSerializer

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error {
    if (aDict[@"overwrite"]) {
        [self clearStoredKeysForUsername:aDict[@"username"]];
    }
    
    uint8_t *buffer = malloc(DESPrivateKeySize + DESPublicKeySize);
    DESConvertPrivateKeyToData(thePrivateKey, buffer);
    DESConvertPublicKeyToData(thePublicKey, buffer + DESPrivateKeySize);
    NSString *theService = @"ca.kirara.kudryavka.unifiedKeyStore";
    OSStatus ret = SecKeychainAddGenericPassword(NULL, (UInt32)[theService lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [theService UTF8String], (UInt32)[aDict[@"username"] lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [aDict[@"username"] UTF8String], (UInt32)(DESPrivateKeySize + DESPublicKeySize), buffer, NULL);
    free(buffer);
    if (ret != errSecSuccess) {
        NKDebug(@"Kudryavka (serialize): ret is %i", ret);
        [self clearStoredKeysForUsername:aDict[@"username"]];
        if (error) {
            CFStringRef reason = SecCopyErrorMessageString(ret, NULL);
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": (__bridge NSString*)reason}];
            CFRelease(reason);
        }
        return NO;
    }
    if (error)
        *error = nil;
    return YES;
}

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    UInt32 length = 0;
    uint8_t *buffer;
    NSString *theService = @"ca.kirara.kudryavka.unifiedKeyStore";
    OSStatus ret = SecKeychainFindGenericPassword(NULL, (UInt32)[theService lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [theService UTF8String], (UInt32)[aDict[@"username"] lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [aDict[@"username"] UTF8String], &length, (void**)&buffer, NULL);
    if (ret != errSecSuccess) {
        NKDebug(@"Kudryavka (load): ret is %i", ret);
        [self clearStoredKeysForUsername:aDict[@"username"]];
        if (error) {
            CFStringRef reason = SecCopyErrorMessageString(ret, NULL);
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": (__bridge NSString*)reason}];
            CFRelease(reason);
        }
        return nil;
    }
    
    if (length != (DESPrivateKeySize + DESPublicKeySize)) {
        SecKeychainItemFreeContent(NULL, buffer);
        [self clearStoredKeysForUsername:aDict[@"username"]];
        if (error) {
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": @"The keychain data is corrupt."}];
        }
        return nil;
    }
    uint8_t *temp_pub = malloc(DESPublicKeySize);
    memcpy(temp_pub, buffer + DESPrivateKeySize, DESPublicKeySize);
    uint8_t *temp_priv = malloc(DESPrivateKeySize);
    memcpy(temp_priv, buffer, DESPrivateKeySize);
    SecKeychainItemFreeContent(NULL, buffer);
    if (!DESValidateKeyPair(temp_priv, temp_pub)) {
        free(temp_pub);
        free(temp_priv);
        [self clearStoredKeysForUsername:aDict[@"username"]];
        if (error) {
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": @"The keys stored do not match."}];
        }
        return nil;
    }
    
    result[@"privateKey"] = DESConvertPrivateKeyToString(temp_priv);
    result[@"publicKey"] = DESConvertPublicKeyToString(temp_pub);
    free(temp_pub);
    free(temp_priv);
    if (error)
        *error = nil;
    return (NSDictionary*)result;
}

- (BOOL)hasDataForOptions:(NSDictionary *)aDict {
    return [self loadKeysWithOptions:aDict error:nil] ? YES : NO;
}

- (void)clearStoredKeysForUsername:(NSString *)theUsername {
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
    item[(id)kSecClass] = (__bridge id)(kSecClassGenericPassword);
    item[(id)kSecAttrAccount] = theUsername;
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.unifiedKeyStore";
    SecItemDelete((__bridge CFDictionaryRef)(item));
}

@end
