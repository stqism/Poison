#include <dns_sd.h>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "DESUserDiscovery.h"

NSString *const DESUserDiscoveryCallbackDomain = @"<-- well, isn't it obvious?";
NSString *const DNSSDErrorDomain = @"DNSSDErrorDomain";

/* due to ARC restrictions, we have to use an objective-c object to 
 * hold the callback */
@interface _DESDiscoveryContext : NSObject {
    @public
    DESUserDiscoveryCallback cb;
    int stopProcessing;
}
@end

@implementation _DESDiscoveryContext
- (void)dealloc {

}
@end

void _DESDecodeKeyValuePair(NSString *kv, NSString **kout, id *vout) {
    NSRange equals = [kv rangeOfString:@"="];
    if (equals.location == NSNotFound || equals.location + 1 == [kv length]) {
        *kout = kv;
        *vout = @"";
        return;
    } else {
        *kout = [[kv substringToIndex:equals.location] stringByRemovingPercentEncoding];
        *vout = [[kv substringFromIndex:equals.location + 1] stringByRemovingPercentEncoding];
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

void _DESDiscoverUserCallback(DNSServiceRef query, DNSServiceFlags flags,
                              uint32_t interface, DNSServiceErrorType errorCode,
                              const char *fullname, uint16_t rrtype,
                              uint16_t rrclass, uint16_t rdlen,
                              const void *rdata, uint32_t ttl, void *ucall) {
    _DESDiscoveryContext *ctx = (__bridge _DESDiscoveryContext *)(ucall);
    if (ctx -> stopProcessing)
        return;

    if (errorCode != kDNSServiceErr_NoError) {
        NSError *e = [NSError errorWithDomain:DNSSDErrorDomain
                                         code:errorCode
                                     userInfo:nil];
        dispatch_sync(dispatch_get_main_queue(), ^{
            ctx -> cb(nil, e);
        });
        return;
    }

    uint64_t realLen = 0;
    uint8_t *posPtr = (uint8_t *)rdata;
    NSMutableString *s = [NSMutableString stringWithCapacity:rdlen];
    while (1) {
        int blkSize = *posPtr;
        realLen += blkSize + 1;
        if (realLen > rdlen) { /* this was invalid */
            if (!(flags & kDNSServiceFlagsMoreComing)) {
                /* no more chances, so error out now */
                NSError *e = [NSError errorWithDomain:DESUserDiscoveryCallbackDomain
                                                 code:DESUserDiscoveryErrorBadReply
                                             userInfo:nil];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    ctx -> cb(nil, e);
                });
            }
            return;
        }
        NSString *frag = [[NSString alloc] initWithBytesNoCopy:posPtr + 1
                                                        length:blkSize
                                                      encoding:NSUTF8StringEncoding
                                                  freeWhenDone:NO];
        [s appendString:frag];
        posPtr += blkSize + 1;
        if (realLen >= rdlen)
            break;
    }

    NSDictionary *params = _DESParametersForTXT(s);
    if (![params[@"v"] isEqualToString:@"tox1"]
        && ((NSString *)params[@"id"]).length == 76) {
        if (!(flags & kDNSServiceFlagsMoreComing)) {
            /* no more chances, so error out now */
            NSError *e = [NSError errorWithDomain:DESUserDiscoveryCallbackDomain
                                             code:DESUserDiscoveryErrorBadReply
                                         userInfo:nil];
            dispatch_sync(dispatch_get_main_queue(), ^{
                ctx -> cb(nil, e);
            });
        }
        return;
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        ctx -> cb(params[@"id"], nil);
    });
    ctx -> stopProcessing = 1;
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
    if (at_count != 1 || *buf == '@' || buf[len - 1] == '@')
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *e = [NSError errorWithDomain:DESUserDiscoveryCallbackDomain
                                             code:DESUserDiscoveryErrorBadInput
                                         userInfo:nil];
            callback(nil, e);
        });

    NSRange position = [shouldBeAnEmailAddress rangeOfString:@"@"];
    /* alloc memory for transforming @ to ._tox. */
    NSMutableString *DNSName = [NSMutableString stringWithCapacity:shouldBeAnEmailAddress.length + 5];
    [DNSName appendFormat:@"%@._tox.%@",
     [shouldBeAnEmailAddress substringToIndex:position.location],
     [shouldBeAnEmailAddress substringFromIndex:position.location + 1]];

    _DESDiscoveryContext *context = [[_DESDiscoveryContext alloc] init];
    /* We need to keep this around until the resolution completes.
     * Use CFBridgingRetain to ensure ARC doesn't kill our context object. */
    CFTypeRef retainedContext = CFBridgingRetain(context);

    context -> cb = callback;
    context -> stopProcessing = 0;

    DNSServiceRef query;
    DNSServiceErrorType error = 0;
    error = DNSServiceQueryRecord(&query, kDNSServiceFlagsTimeout, 0,
                                  [DNSName UTF8String], kDNSServiceType_TXT,
                                  kDNSServiceClass_IN, _DESDiscoverUserCallback,
                                  (void *)retainedContext);
    if (error)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *e = [NSError errorWithDomain:DNSSDErrorDomain
                                             code:error
                                         userInfo:nil];
            callback(nil, e);
        });
    /* if (sync)
           DNSServiceProcessResult(query);
     */
    int fd = DNSServiceRefSockFD(query);

    /* send it off to GCD so our callback gets called later */
    __block dispatch_source_t src;
    src = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0,
                                 //dispatch_get_main_queue());
                                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    dispatch_source_set_event_handler(src, ^{
        DNSServiceProcessResult(query);
        DNSServiceRefDeallocate(query);
        CFBridgingRelease(retainedContext);
        dispatch_source_cancel(src);
        src = nil;
        //dispatch_release(src);
    });
    dispatch_resume(src);
}
