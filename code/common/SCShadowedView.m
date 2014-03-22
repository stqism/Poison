#include "Copyright.h"

#import "SCShadowedView.h"

@implementation SCShadowedView

- (void)awakeFromNib {
    if (!self.backgroundColor)
        self.backgroundColor = [NSColor blackColor];
    if (!self.shadowColor)
        self.shadowColor = [NSColor blackColor];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor set];
    [[NSBezierPath bezierPathWithRect:self.bounds] fill];
    NSGradient *shadow = [[NSGradient alloc] initWithStartingColor:[NSColor clearColor] endingColor:self.shadowColor];
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, self.bounds.size.height - 4, self.bounds.size.width, 8)];
    [shadow drawInBezierPath:shadowPath angle:90.0];
}

@end
