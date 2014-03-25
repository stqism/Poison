#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "SCMainWindowing.h"
#import "SCNonGarbageSplitView.h"
#import "SCMainWindowController.h"

@interface SCUnifiedWindowController : SCMainWindowController <SCMainWindowing, SCNonGarbageSplitViewDelegate, NSWindowDelegate>

@end
