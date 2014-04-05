#include "Copyright.h"

#import <Foundation/Foundation.h>

@interface NSString (SCBase64)

- (NSString *)base64String;
- (NSString *)stringByDecodingBase64;
- (NSData *)dataByDecodingBase64;

@end