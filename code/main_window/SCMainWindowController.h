#include "SCMainWindowing.h"

#import <Cocoa/Cocoa.h>
#import "SCWidgetedWindow.h"

@interface SCMainWindowController : NSWindowController <SCMainWindowing>
@property (strong) SCQRCodeSheetController *qrPanel;
@property (strong) SCAddFriendSheetController *addPanel;
- (NSTextField *)newStyledTextField;
@end
