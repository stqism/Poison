#include "Copyright.h"

#import <Cocoa/Cocoa.h>

@interface SCAddFriendSheetController : NSWindowController
- (void)setToxID:(NSString *)theID;
- (void)setMessage:(NSString *)theMessage;
@end
