#import "SLBackingView.h"

@implementation SLBackingView

- (void)drawRect:(NSRect)dirtyRect {
    [self.topLel set];
    [[NSBezierPath bezierPathWithRect:dirtyRect] fill];
}

@end
