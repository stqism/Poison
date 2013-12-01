#import "SCFriendListHeaderCell.h"

@implementation SCFriendListHeaderCell {
    CGFloat textWidth;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [NSColor colorWithCalibratedWhite:0.20 alpha:1.0];
        self.shadowColor = [NSColor colorWithCalibratedWhite:0.11 alpha:1.0];
        self.textColor = [NSColor colorWithCalibratedWhite:0.60 alpha:1.0];
        textWidth = 0;
    }
    return self;
}

- (void)setStringValue:(NSString *)stringValue {
    _stringValue = [stringValue uppercaseString];
    NSFont *theFont = [NSFont boldSystemFontOfSize:10];
    CGSize theSize = [_stringValue sizeWithAttributes:@{NSFontAttributeName: theFont}];
    textWidth = theSize.width;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor set];
    [[NSBezierPath bezierPathWithRect:self.bounds] fill];
    CGPoint drawPoint = {(self.frame.size.width - textWidth) / 2, 2};
    NSRect lineRect = NSMakeRect(0, floor(self.bounds.size.height / 2), self.bounds.size.width, 1);
    [self.textColor set];
    [[NSBezierPath bezierPathWithRect:lineRect] fill];
    [self.shadowColor set];
    [[NSBezierPath bezierPathWithRect:CGRectOffset(lineRect, 0, 1)] fill];
    [self.backgroundColor set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(drawPoint.x - 3, 0, textWidth + 6, self.bounds.size.height)] fill];
    [self.stringValue drawAtPoint:(CGPoint){drawPoint.x, drawPoint.y + 1.5} withAttributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:10], NSForegroundColorAttributeName: self.shadowColor}];
    [self.stringValue drawAtPoint:drawPoint withAttributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:10], NSForegroundColorAttributeName: self.textColor}];
}

@end
