#include "SCMainWindowing.h"

#import <Cocoa/Cocoa.h>

@interface SCMainWindowController : NSWindowController <SCMainWindowing>
@property (strong) SCQRCodeSheetController *qrPanel;
@property (strong) SCAddFriendSheetController *addPanel;
@end
