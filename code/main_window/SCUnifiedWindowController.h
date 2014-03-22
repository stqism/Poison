#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "SCMainWindowing.h"
#import "SCNonGarbageSplitView.h"

@interface SCUnifiedWindowController : NSWindowController <SCMainWindowing, SCNonGarbageSplitViewDelegate, NSWindowDelegate>

@end
