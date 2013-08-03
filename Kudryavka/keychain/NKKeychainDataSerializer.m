#import <DeepEnd/DeepEnd.h>
#import <Security/Security.h>
#import "NKKeychainDataSerializer.h"

@implementation NKKeychainDataSerializer

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error {
    uint8_t *buffer = NULL;
    OSStatus ret = errSecSuccess;
    
    if (aDict[@"overwrite"]) {
        [self clearStoredKeysForUsername:aDict[@"username"]];
    }
    
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    item[(id)kSecClass] = (__bridge id)(kSecClassGenericPassword);
    item[(id)kSecAttrAccount] = aDict[@"username"];
    
    buffer = malloc(DESPrivateKeySize);
    DESConvertPrivateKeyToData(thePrivateKey, buffer);
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.privateKeyStore";
    item[(id)kSecValueData] = [NSData dataWithBytes:buffer length:DESPrivateKeySize];
    free(buffer);
    ret = SecItemAdd((__bridge CFDictionaryRef)(item), NULL);
    
    if (ret != errSecSuccess) {
        [self clearStoredKeysForUsername:aDict[@"username"]];
        if (error) {
            CFStringRef reason = SecCopyErrorMessageString(ret, NULL);
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": (__bridge NSString*)reason}];
            CFRelease(reason);
        }
        return NO;
    }
    
    buffer = malloc(DESPublicKeySize);
    DESConvertPublicKeyToData(thePublicKey, buffer);
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.publicKeyStore";
    item[(id)kSecValueData] = [NSData dataWithBytes:buffer length:DESPublicKeySize];
    free(buffer);
    ret = SecItemAdd((__bridge CFDictionaryRef)(item), NULL);
    
    if (ret != errSecSuccess) {
        [self clearStoredKeysForUsername:aDict[@"username"]];
        if (error) {
            CFStringRef reason = SecCopyErrorMessageString(ret, NULL);
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": (__bridge NSString*)reason}];
            CFRelease(reason);
        }
        return NO;
    }
    
    *error = nil;
    return YES;
}

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    OSStatus ret = errSecSuccess;
    CFDataRef rs = NULL;
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
    item[(id)kSecClass] = (__bridge id)(kSecClassGenericPassword);
    item[(id)kSecAttrAccount] = aDict[@"username"];
    item[(id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);
    
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.privateKeyStore";
    SecItemCopyMatching((__bridge CFDictionaryRef)(item), (CFTypeRef*)&rs);
    if (ret != errSecSuccess) {
        if (error) {
            CFStringRef reason = SecCopyErrorMessageString(ret, NULL);
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": (__bridge NSString*)reason}];
            CFRelease(reason);
        }
        return NO;
    }
    result[@"privateKey"] = DESConvertPrivateKeyToString([(__bridge NSData*)rs bytes]);
    
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.publicKeyStore";
    SecItemCopyMatching((__bridge CFDictionaryRef)(item), (CFTypeRef*)&rs);
    if (ret != errSecSuccess) {
        if (error) {
            CFStringRef reason = SecCopyErrorMessageString(ret, NULL);
            *error = [NSError errorWithDomain:@"ca.kirara.Kudryavka" code:9001 userInfo:@{@"cause": (__bridge NSString*)reason}];
            CFRelease(reason);
        }
        return NO;
    }
    result[@"publicKey"] = DESConvertPublicKeyToString([(__bridge NSData*)rs bytes]);
    
    if (error)
        *error = nil;
    return (NSDictionary*)result;
}

- (void)clearStoredKeysForUsername:(NSString *)theUsername {
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
    item[(id)kSecClass] = (__bridge id)(kSecClassGenericPassword);
    item[(id)kSecAttrAccount] = theUsername;
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.privateKeyStore";
    SecItemDelete((__bridge CFDictionaryRef)(item));
    item[(id)kSecAttrService] = @"ca.kirara.kudryavka.publicKeyStore";
    SecItemDelete((__bridge CFDictionaryRef)(item));
}

@end
