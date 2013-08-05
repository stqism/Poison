#import "SCDHTStatusView.h"

@implementation SCDHTStatusView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)setConnectedNodes:(NSInteger)connectedNodes {
    _connectedNodes = connectedNodes;
    [self setNeedsDisplay:YES];
    NSString *drawString = nil;
    if (self.connectedNodes)
        drawString = [NSString stringWithFormat:@"DHT: %ld", (long)self.connectedNodes];
    else
        drawString = NSLocalizedString(@"Disconnected", @"");
    NSFont *theFont = [NSFont boldSystemFontOfSize:self.frame.size.height - 4];
    CGSize theSize = [drawString sizeWithAttributes:@{NSFontAttributeName: theFont}];
    [self setFrameSize:(NSSize){theSize.width + 10, self.frame.size.height}];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRoundedRect:(NSRect){CGPointZero, {self.bounds.size.width, self.bounds.size.height - 1}} xRadius:2.0 yRadius:2.0];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.56] set];
    [shadowPath fill];
    NSBezierPath *bodyPath = [NSBezierPath bezierPathWithRoundedRect:(NSRect){{0, 1}, {self.bounds.size.width, self.bounds.size.height - 1}} xRadius:2.0 yRadius:2.0];
    NSGradient *bodyGradient = nil;
    switch (self.connectedNodes) {
        case 0: bodyGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:225.0 / 255.0 green:0.0 blue:25.0 / 255.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:159.0 / 255.0 green:0.0 blue:0.0 alpha:1.0]]; break;
        case 1: bodyGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:180.0 / 255.0 blue:0.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:209.0 / 255.0 green:148.0 / 255.0 blue:0.0 alpha:1.0]]; break;
        default: bodyGradient = bodyGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:177.0 / 255.0 blue:8.0 / 255.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:142.0 / 255.0 blue:40.0 / 255.0 alpha:1.0]]; break;
    }
    [bodyGradient drawInBezierPath:bodyPath angle:90.0];
    NSString *drawString = nil;
    if (self.connectedNodes)
        drawString = [NSString stringWithFormat:@"DHT: %ld", (long)self.connectedNodes];
    else
        drawString = NSLocalizedString(@"Disconnected", @"");
    NSFont *theFont = [NSFont boldSystemFontOfSize:self.frame.size.height - 4];
    [drawString drawAtPoint:(NSPoint){5, 0} withAttributes:@{NSFontAttributeName: theFont, NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.0 alpha:0.3]}];

    [drawString drawAtPoint:(NSPoint){5, 1} withAttributes:@{NSFontAttributeName: theFont, NSForegroundColorAttributeName: [NSColor whiteColor]}];
}

@end
