#import "SCCapsuleContainer.h"

@implementation SCCapsuleCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSInteger count = self.segmentCount;
    NSRect segmentFrame = cellFrame;
    NSColor *baseColor = [NSColor colorWithCalibratedWhite:0.20 alpha:1.0];
    NSColor *brightColor = [NSColor colorWithCalibratedWhite:0.40 alpha:1.0];
    NSColor *topColor = [NSColor colorWithCalibratedWhite:0.30 alpha:1.0];
    NSGradient *grad2 = [[NSGradient alloc] initWithStartingColor:topColor endingColor:baseColor];
    [grad2 drawInBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, 15)] angle:90.0];
    NSGradient *grad = [[NSGradient alloc] initWithColorsAndLocations:topColor, 0.0, brightColor, 0.5, topColor, 1.0, nil];
    [grad drawInBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(segmentFrame.origin.x, segmentFrame.origin.y, segmentFrame.size.width, 1)] angle:0.0];
    [topColor set];
    [[NSBezierPath bezierPathWithRect:(NSRect){{0, cellFrame.size.height - 1}, {cellFrame.size.width, 1}}] fill];
    segmentFrame.size.height -= 1;
    for (int i = 0; i < count; i++) {
        segmentFrame.size.width = [self widthForSegment:i] + (i == count -1 ? 1 : 0);
        [self drawSegment:i inFrame:segmentFrame withView:controlView];
        [[NSColor colorWithCalibratedWhite:0.40 alpha:1.0] set];
        segmentFrame.origin.x += segmentFrame.size.width + 1;
        if (i != count - 1)
            [[NSBezierPath bezierPathWithRect:CGRectIntegral(NSMakeRect(segmentFrame.origin.x - 1, segmentFrame.origin.y + 1, 1, segmentFrame.size.height - 1))] fill];
    }
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView {
    NSColor *colour = [NSColor colorWithCalibratedWhite:0.80 alpha:1.0];
    if (segment == self.selectedSegment) {
        [[NSColor colorWithCalibratedWhite:0.11 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect:frame] fill];
    }
    NSString *title = [self labelForSegment:segment];
    NSMutableParagraphStyle *pstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    pstyle.alignment = NSCenterTextAlignment;
    NSMutableDictionary *attrs = [@{
                            NSFontAttributeName: self.font,
                            NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.10 alpha:1.0],
                            NSParagraphStyleAttributeName: pstyle,
                            } mutableCopy];
    NSSize txtSz = [title sizeWithAttributes:attrs];
    NSRect rect = (NSRect){{frame.origin.x, frame.origin.y + ((frame.size.height - txtSz.height) / 2) - 1}, frame.size};
    [title drawInRect:CGRectOffset(rect, 0, -1) withAttributes:attrs];
    attrs[NSForegroundColorAttributeName] = colour;
    [title drawInRect:rect withAttributes:attrs];
}

@end

@implementation SCCapsuleContainer

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRect:dirtyRect] fill];
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    CGSize tabControlSize = self.bounds.size;
    NSInteger sc = self.tabControl.segmentCount;
    for (int i = 0; i < sc; ++i) {
        [self.tabControl setWidth:(tabControlSize.width - sc) / sc forSegment:i];
    }
    self.tabControl.frameSize = tabControlSize;
    self.tabControl.frame = CGRectIntegral((CGRect){{(self.frame.size.width - self.tabControl.frame.size.width) / 2, (self.frame.size.height - self.tabControl.frame.size.height) / 2}, self.tabControl.frame.size});
}

@end
