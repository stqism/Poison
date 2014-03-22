#include "Copyright.h"

#import "SCGradientView.h"

@implementation SCGradientView

- (void)awakeFromNib {
    if (!self.topColor)
        self.topColor = [NSColor blackColor];
    if (!self.bottomColor)
        self.bottomColor = [NSColor blackColor];
    if (!self.shadowColor)
        self.shadowColor = [NSColor blackColor];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    NSGradient *chrome = [[NSGradient alloc] initWithStartingColor:self.bottomColor endingColor:self.topColor];
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:self.bounds];
    [chrome drawInBezierPath:bgPath angle:90];
    if (self.shadowColor) {
        NSBezierPath *topShadow = [NSBezierPath bezierPathWithRect:NSMakeRect(0, self.frame.size.height - 1, self.frame.size.width, 1)];
        NSColor *farPoint = nil;
        [chrome getColor:&farPoint location:NULL atIndex:1];
        NSGradient *highlightGrad = [[NSGradient alloc] initWithColors:@[farPoint, self.shadowColor, farPoint]];
        [highlightGrad drawInBezierPath:topShadow angle:0];
    }
    if (self.borderColor) {
        [self.borderColor set];
        NSRectFill((CGRect){{0, 0}, {self.frame.size.width, 1}});
    }
}

@end
