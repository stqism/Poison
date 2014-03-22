#include "Copyright.h"

#import <Cocoa/Cocoa.h>

@interface NSWindow (Shake)

- (void)shakeWindow:(void(^)(void))completionHandler;

@end
