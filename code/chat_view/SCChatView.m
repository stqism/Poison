#include "Copyright.h"

#import "SCChatView.h"

@implementation SCChatView

- (void)viewDidMoveToWindow {
    [self.window setContentBorderThickness:self.frame.size.height forEdge:NSMinYEdge];
}

@end
