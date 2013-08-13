#import "SCBorderedGradientView.h"

@implementation SCBorderedGradientView

- (void)awakeFromNib {
    [super awakeFromNib];
    if (!self.borderColor)
        self.borderColor = [NSColor blackColor];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self.borderColor set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, self.bounds.size.width, 1)] fill];
}

@end
