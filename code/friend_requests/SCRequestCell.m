#import "SCRequestCell.h"

@implementation SCRequestCell

- (void)drawRect:(NSRect)dirtyRect {
    if (self.selected) {
        [[NSColor alternateSelectedControlColor] set];
        [[NSBezierPath bezierPathWithRect:self.bounds] fill];
        self.keyLabel.textColor = [NSColor whiteColor];
        self.dateReceivedLabel.textColor = [NSColor whiteColor];
    } else {
        [[NSColor whiteColor] set];
        [[NSBezierPath bezierPathWithRect:self.bounds] fill];
        self.keyLabel.textColor = [NSColor blackColor];
        self.dateReceivedLabel.textColor = [NSColor grayColor];
    }
}

@end
