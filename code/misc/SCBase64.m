#include "Copyright.h"

#import "SCBase64.h"

@implementation NSString (SCBase64)
- (NSString *)base64String {
    CFDataRef input = CFDataCreate(kCFAllocatorDefault, (uint8_t *)self.UTF8String,
                                   [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    SecTransformRef transform = SecEncodeTransformCreate(kSecBase64Encoding, NULL);
    SecTransformSetAttribute(transform, kSecTransformInputAttributeName,
                             input, NULL);
    CFDataRef encoded = SecTransformExecute(transform, NULL);
    NSString *ret = [[NSString alloc] initWithBytes:CFDataGetBytePtr(encoded)
                                             length:CFDataGetLength(encoded)
                                           encoding:NSASCIIStringEncoding];
    CFRelease(input);
    CFRelease(transform);
    CFRelease(encoded);
    return ret;
}

- (NSString *)stringByDecodingBase64 {
    CFDataRef input = CFDataCreate(kCFAllocatorDefault, (uint8_t *)self.UTF8String,
                                   [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
    SecTransformSetAttribute(transform, kSecTransformInputAttributeName,
                             input, NULL);
    CFDataRef encoded = SecTransformExecute(transform, NULL);
    if (!encoded) {
        CFRelease(input);
        CFRelease(transform);
        return nil;
    }
    
    NSString *ret = [[NSString alloc] initWithBytes:CFDataGetBytePtr(encoded)
                                             length:CFDataGetLength(encoded)
                                           encoding:NSASCIIStringEncoding];
    CFRelease(input);
    CFRelease(transform);
    CFRelease(encoded);
    return ret;
}

- (NSData *)dataByDecodingBase64 {
    CFDataRef input = CFDataCreate(kCFAllocatorDefault, (uint8_t *)self.UTF8String,
                                   [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
    SecTransformSetAttribute(transform, kSecTransformInputAttributeName,
                             input, NULL);
    CFDataRef encoded = SecTransformExecute(transform, NULL);
    if (!encoded) {
        CFRelease(input);
        CFRelease(transform);
        return nil;
    }

    CFRelease(input);
    CFRelease(transform);
    return CFBridgingRelease(encoded);
}
@end