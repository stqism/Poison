#import "SCTextField.h"
#import <QuartzCore/QuartzCore.h>

@interface SCTextFieldCell : NSTextFieldCell

@end

@implementation SCTextFieldCell

- (void)drawFocusRingMaskWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1, 1, cellFrame.size.width - 2, cellFrame.size.height - 2) xRadius:3.2 yRadius:3.2] fill];
}

@end

@implementation SCTextField {
    NSRange _selectedRange;
    NSColor *_focusedCachedColour;
    NSColor *_unfocusedCachedColour;
    NSGradient *_cachedGradient;
    NSShadow *_innerShadow;
}

+ (Class)cellClass {
    return [SCTextFieldCell class];
}

- (void)awakeFromNib {
    self.bezeled = YES;
    self.drawsBackground = NO;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusChanged:) name:NSWindowDidBecomeKeyNotification object:newWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusChanged:) name:NSWindowDidResignKeyNotification object:newWindow];
}

- (NSColor *)focusedColorForTextField {
    if (!_focusedCachedColour)
        _focusedCachedColour = [NSColor colorWithCalibratedWhite:87.0 / 255.0 alpha:0.85];
    return _focusedCachedColour;
}

- (NSColor *)unfocusedColorForTextField {
    if (!_unfocusedCachedColour)
        _unfocusedCachedColour = [NSColor colorWithCalibratedWhite:100.0 / 255.0 alpha:0.4];
    return _unfocusedCachedColour;
}

- (NSGradient *)gradientOfTextField {
    if (!_cachedGradient)
        _cachedGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0], 0.0, [NSColor whiteColor], 1.0, nil];
    return _cachedGradient;
}

- (NSShadow *)innerShadowOfTextField {
    if (!_innerShadow) {
        _innerShadow = [[NSShadow alloc] init];
        [_innerShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
        [_innerShadow setShadowBlurRadius:3.0];
        [_innerShadow setShadowOffset:(NSSize){0, -1.0}];
    }
    return _innerShadow;
}

- (CGRect)actualBounds {
    return CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - 1);
}

- (void)focusChanged:(NSNotification *)notification {
    self.needsDisplay = YES;
}

- (void)clearSelection {
    _selectedRange = NSMakeRange(0, 0);
}

- (void)saveSelection {
    _selectedRange = [self.window fieldEditor:YES forObject:self].selectedRange;
}

- (void)restoreSelection {
    [self.window fieldEditor:YES forObject:self].selectedRange = _selectedRange;
}

- (void)drawRect:(NSRect)dirtyRect {
    /*[[NSColor colorWithCalibratedWhite:1.0 alpha:0.34] set];
    NSBezierPath *outerShadowPath = [NSBezierPath bezierPathWithRoundedRect:CGRectOffset(self.actualBounds, 0, 1) xRadius:4.0 yRadius:4.0];
    [outerShadowPath fill];*/

    [NSGraphicsContext saveGraphicsState];
    NSShadow *test = [[NSShadow alloc] init];
    test.shadowBlurRadius = 1.0;
    test.shadowOffset = (CGSize){0, -0.7};
    test.shadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.34];
    [test set];

    if (self.window.isKeyWindow) {
        [[self focusedColorForTextField] set];
    } else {
        [[self unfocusedColorForTextField] set];
    }
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:self.actualBounds xRadius:4.0 yRadius:4.0];
    [borderPath fill];
    [NSGraphicsContext restoreGraphicsState];

    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1, 1, self.actualBounds.size.width - 2, self.actualBounds.size.height - 2) xRadius:3.42 yRadius:3.42];
    NSGradient *fill = [self gradientOfTextField];
    [fill drawInBezierPath:innerPath angle:90.0];

    [NSGraphicsContext saveGraphicsState];
    [innerPath addClip];
    NSBezierPath *shadowDraw = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.actualBounds, -1, -1) xRadius:3.42 yRadius:3.42];
    NSShadow *shadow = [self innerShadowOfTextField];
    [shadow set];
    [shadowDraw stroke];
    // Restore the graphics state
    [NSGraphicsContext restoreGraphicsState];

    [self.cell drawInteriorWithFrame:self.actualBounds inView:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
