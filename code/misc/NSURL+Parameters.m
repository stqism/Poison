#include "Copyright.h"

#import "NSURL+Parameters.h"

@implementation NSURL (Parameters)
- (NSDictionary *)parameters {
    NSScanner *scanner = [[NSScanner alloc] initWithString:self.query];
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    NSString *pair = nil;
    while (![scanner isAtEnd]) {
        pair = nil;
        [scanner scanUpToString:@"&" intoString:&pair];
        if (pair) {
            NSString *key, *value;
            [self _decodeKeyPair:pair intoKey:&key intoValue:&value];
            if (key && value)
                ret[key] = value;
        }
    }
    return ret;
}

- (void)_decodeKeyPair:(NSString *)kv
               intoKey:(NSString **)kout
             intoValue:(id *)vout {
    NSRange equals = [kv rangeOfString:@"="];
    if (equals.location == NSNotFound || equals.location + 1 == [kv length]) {
        *kout = kv;
        *vout = @(YES);
        return;
    } else {
        *kout = [[kv substringToIndex:equals.location] stringByRemovingPercentEncoding];
        *vout = [[kv substringFromIndex:equals.location + 1] stringByRemovingPercentEncoding];
    }
}
@end
