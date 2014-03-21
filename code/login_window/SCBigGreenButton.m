// You will not find the licensing jibber-jabber here.
// Go read it elsewhere.

#import "SCBigGreenButton.h"

@implementation SCBigGreenButton

- (void)drawRect:(NSRect)dirtyRect {
    // draw background
    NSBezierPath *bodyPath = [NSBezierPath bezierPathWithRect:self.bounds];
    NSArray *colours = @[
                         [NSColor colorWithCalibratedRed:0.0 green:136.0 / 255.0 blue:58.0 / 255.0 alpha:1.0],
                         [NSColor colorWithCalibratedRed:0.0 green:148.0 / 255.0 blue:66.0 / 255.0 alpha:1.0],
                         [NSColor colorWithCalibratedRed:25.0 / 255.0 green:160.0 / 255.0 blue:76.0 / 255.0 alpha:1.0],
                         [NSColor colorWithCalibratedRed:0.0 green:185.0 / 255.0 blue:96.0 / 255.0 alpha:1.0],
                         ];
    CGFloat locations[] = {1.0, 0.5000001, 0.5000000, 0.0};
    NSGradient *button = [[NSGradient alloc] initWithColors:colours atLocations:locations colorSpace:[NSColorSpace deviceRGBColorSpace]];
    [button drawInBezierPath:bodyPath angle:90.0];
    // draw stroke
    [[NSColor colorWithCalibratedRed:73.0 / 255.0 green:155.0 / 255.0 blue:93.0 / 255.0 alpha:1.0] set];
    [bodyPath stroke];
    NSBezierPath *topShadow = [NSBezierPath bezierPathWithRect:NSMakeRect(1, 0, self.bounds.size.width - 1, 1)];
    NSColor *farPoint = nil;
    [button getColor:&farPoint location:NULL atIndex:1];
    // draw top highlight
    NSGradient *highlightGrad = [[NSGradient alloc] initWithColors:@[farPoint, [NSColor colorWithCalibratedWhite:1.0 alpha:0.6], farPoint]];
    [highlightGrad drawInBezierPath:topShadow angle:0];
    // draw text
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSFont *theFont = [NSFont systemFontOfSize:16.0];
    NSMutableDictionary *attributes = [@{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: theFont, NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.0 alpha:0.3]} mutableCopy];
    CGSize size = [[((NSButtonCell*)self.cell) title] sizeWithAttributes:attributes];
    CGFloat y = (self.bounds.size.height - size.height) / 2.0;
    [[((NSButtonCell*)self.cell) title] drawInRect:NSMakeRect(0, y - 2, self.bounds.size.width, size.height - 1) withAttributes:attributes];
    attributes[NSForegroundColorAttributeName] = [NSColor whiteColor];
    [[((NSButtonCell*)self.cell) title] drawInRect:NSMakeRect(0, y - 1, self.bounds.size.width, size.height - 1) withAttributes:attributes];
}

@end
