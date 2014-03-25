#include "Copyright.h"

#import <Cocoa/Cocoa.h>

@interface SCAddFriendSheetController : NSWindowController <NSTextFieldDelegate>
- (void)resetFields;

- (NSString *)toxID;
- (NSString *)message;
- (void)setToxID:(NSString *)theID;
- (void)setMessage:(NSString *)theMessage;
@end
