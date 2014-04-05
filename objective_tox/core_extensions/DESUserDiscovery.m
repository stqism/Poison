#import <Foundation/Foundation.h>
#import "DESUserDiscovery.h"
#import "DESConstants.h"
#include <dns.h>

NSString *const DESUserDiscoveryCallbackDomain = @"DESUserDiscoveryErrorDomain";
NSString *const DNSSDErrorDomain = @"DNSSDErrorDomain";

NSString *const DESUserDiscoveryIDKey = @"id";
NSString *const DESUserDiscoveryPublicKey = @"pub";
NSString *const DESUserDiscoveryChecksumKey = @"check";
NSString *const DESUserDiscoveryVersionKey = @"v";

NSString *const DESUserDiscoveryRecVersion1 = @"tox1";
NSString *const DESUserDiscoveryRecVersion2 = @"tox2";

void _DESDecodeKeyValuePair(NSString *kv, NSString **kout, id *vout) {
    NSRange equals = [kv rangeOfString:@"="];
    if (equals.location == NSNotFound || equals.location + 1 == [kv length]) {
        *kout = kv;
        *vout = @"";
        return;
    } else {
        *kout = [kv substringToIndex:equals.location];
        *vout = [kv substringFromIndex:equals.location + 1];
    }
}

NSDictionary *_DESParametersForTXT(NSString *rec) {
    NSScanner *scanner = [[NSScanner alloc] initWithString:rec];
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    NSString *pair = nil;
    while (!scanner.isAtEnd) {
        pair = nil;
        [scanner scanUpToString:@";" intoString:&pair];
        if (pair) {
            NSString *key, *value;
            _DESDecodeKeyValuePair(pair, &key, &value);
            if (key && value)
                ret[key] = value;
        }
        if (scanner.scanLocation >= rec.length)
            break;
        ++scanner.scanLocation;
    }
    return ret;
}

void _DESDiscoverUser_ErrorOut(NSString *domain, NSInteger code,
                               DESUserDiscoveryCallback callback) {
    NSError *e = [NSError errorWithDomain:domain
                                     code:code
                                 userInfo:nil];
    dispatch_sync(dispatch_get_main_queue(), ^{
        callback(nil, e);
    });
}

void DESDiscoverUser(NSString *shouldBeAnEmailAddress,
                     DESUserDiscoveryCallback callback) {
    const char *buf = shouldBeAnEmailAddress.UTF8String;
    NSUInteger len = [shouldBeAnEmailAddress lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    int at_count = 0;
    for (int i = 0; i < len && at_count < 2; ++i) {
        if (buf[i] == '@')
            ++at_count;
    }
    /*  */
    if (at_count != 1 || *buf == '@' || buf[len - 1] == '@' || len > UINT32_MAX) {
        NSError *e = [NSError errorWithDomain:DESUserDiscoveryCallbackDomain
                                         code:DESUserDiscoveryErrorBadInput
                                     userInfo:nil];
        dispatch_sync(dispatch_get_main_queue(), ^{
            callback(nil, e);
        });
    }

    NSRange position = [shouldBeAnEmailAddress rangeOfString:@"@"];
    /* alloc memory for transforming @ to ._tox. */
    NSMutableString *DNSName = [NSMutableString stringWithCapacity:shouldBeAnEmailAddress.length + 5];
    [DNSName appendFormat:@"%@._tox.%@",
     [shouldBeAnEmailAddress substringToIndex:position.location],
     [shouldBeAnEmailAddress substringFromIndex:position.location + 1]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        stralloc fqdn = {0};
        uint32_t dl = (uint32_t)[DNSName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        fqdn.s = calloc(dl + 1, 1);
        fqdn.len = dl;
        memcpy(fqdn.s, DNSName.UTF8String, dl);

        stralloc finis = {0};
        errno = 0;
        int result = dns_txt(&finis, &fqdn);
        free(fqdn.s);
        if (result == -1) {
            perror("lookup fail");
            _DESDiscoverUser_ErrorOut(NSPOSIXErrorDomain, errno,
                                      callback);
        } else {
            //__builtin_trap();
            if (finis.len == 0) {
                _DESDiscoverUser_ErrorOut(DESUserDiscoveryCallbackDomain,
                                          DESUserDiscoveryErrorNoAddress,
                                          callback);
                return;
            }
            NSString *rec = [[NSString alloc] initWithBytes:finis.s
                                                     length:finis.len
                                                   encoding:NSUTF8StringEncoding];
            NSDictionary *params = _DESParametersForTXT(rec);
            if (!params[@"v"]) {
                _DESDiscoverUser_ErrorOut(DESUserDiscoveryCallbackDomain,
                                          DESUserDiscoveryErrorBadReply,
                                          callback);
                return;
            }

            if ([params[@"v"] isEqualToString:DESUserDiscoveryRecVersion1]) {
                if (((NSString *)params[@"id"]).length != DESFriendAddressSize * 2) {
                    _DESDiscoverUser_ErrorOut(DESUserDiscoveryCallbackDomain,
                                              DESUserDiscoveryErrorBadReply,
                                              callback);
                    return;
                }
            }

            if ([params[@"v"] isEqualToString:DESUserDiscoveryRecVersion2]) {
                if (((NSString *)params[@"pub"]).length != DESPublicKeySize * 2
                    || ((NSString *)params[@"check"]).length != 4) {
                    _DESDiscoverUser_ErrorOut(DESUserDiscoveryCallbackDomain,
                                              DESUserDiscoveryErrorBadReply,
                                              callback);
                    return;
                }
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                callback(params, nil);
            });
        }
    });

}
