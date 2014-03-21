/* It just fills, yo. */

#import "SCFillingView.h"

@implementation SCFillingView

- (void)drawRect:(NSRect)dirtyRect {
    if (self.drawColor) {
        [self.drawColor set];
        NSRectFill(dirtyRect);
    }
}

@end
