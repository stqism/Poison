#include "Copyright.h"

#import "ObjectiveTox.h"
#import "NSString+CanonicalID.h"

@implementation NSString (CanonicalID)
- (NSString *)canonicalToxID {
    NSMutableCharacterSet *cs = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [cs addCharactersInString:@":"]; /* parses IDs like AB CD EF 01... and AB:CD:EF:01... */
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:DESFriendAddressSize * 2];
    NSUInteger sl = self.length;
    for (int i = 0; i < sl; ++i) {
        if ([cs characterIsMember:[self characterAtIndex:i]])
            continue;
        [string appendString:[self substringWithRange:NSMakeRange(i, 1)]];
        if (string.length > DESFriendAddressSize * 2)
            return nil;
    }
    if (string.length == DESFriendAddressSize * 2 || string.length == DESPublicKeySize * 2)
        return string;
    else
        return nil;
}
@end
