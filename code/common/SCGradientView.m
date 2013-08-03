#import "SCGradientView.h"

@implementation SCGradientView {
    CGPoint initialLocation;
}

- (void)awakeFromNib {
    if (!self.topColor)
        self.topColor = [NSColor blackColor];
    if (!self.bottomColor)
        self.bottomColor = [NSColor blackColor];
    if (!self.shadowColor)
        self.shadowColor = [NSColor blackColor];
}

#pragma mark - Dragging

- (void)mouseDown:(NSEvent *)theEvent {
    initialLocation = [theEvent locationInWindow];
}

- (void)mouseUp:(NSEvent *)theEvent {
    initialLocation = CGPointZero;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (!self.dragsWindow) {
        return;
    } else {
        NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
        NSRect windowFrame = [self.window frame];
        NSPoint newOrigin = windowFrame.origin;
        NSPoint currentLocation = [theEvent locationInWindow];
        newOrigin.x += (currentLocation.x - initialLocation.x);
        newOrigin.y += (currentLocation.y - initialLocation.y);
        if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
            newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
        }
        [self.window setFrameOrigin:newOrigin];
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    NSGradient *chrome = [[NSGradient alloc] initWithStartingColor:self.bottomColor endingColor:self.topColor];
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:self.bounds];
    [chrome drawInBezierPath:bgPath angle:90];
    NSBezierPath *topShadow = [NSBezierPath bezierPathWithRect:NSMakeRect(0, self.frame.size.height - 1, self.frame.size.width, 1)];
    NSColor *farPoint = nil;
    [chrome getColor:&farPoint location:NULL atIndex:1];
    NSGradient *highlightGrad = [[NSGradient alloc] initWithColors:@[farPoint, self.shadowColor, farPoint]];
    [highlightGrad drawInBezierPath:topShadow angle:0];
}

@end
