#import "SCTextField.h"

@interface NSColor (SCTFColors)

+ (NSColor *)focusedColorForTextField;
+ (NSColor *)unfocusedColorForTextField;

@end

@implementation NSColor (SCTFColors)

+ (NSColor *)focusedColorForTextField {
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
        return [NSColor colorWithCalibratedWhite:100.0 / 255.0 alpha:0.85];
    } else {
        return [NSColor colorWithCalibratedWhite:75.0 / 255.0 alpha:1.0];
    }
}

+ (NSColor *)unfocusedColorForTextField {
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
        return [NSColor colorWithCalibratedWhite:100.0 / 255.0 alpha:0.4];
    } else {
        return [NSColor colorWithCalibratedWhite:100.0 / 255.0 alpha:0.5];
    }
}

@end

@interface SCTextFieldCell : NSTextFieldCell

@end

@implementation SCTextFieldCell

- (void)drawFocusRingMaskWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1, 1, cellFrame.size.width - 2, cellFrame.size.height - 2) xRadius:3.2 yRadius:3.2] fill];
}

@end

@implementation SCTextField

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

- (void)focusChanged:(NSNotification *)notification {
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.window.isKeyWindow) {
        [[NSColor focusedColorForTextField] set];
    } else {
        [[NSColor unfocusedColorForTextField] set];
    }
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4.0 yRadius:4.0];
    [borderPath fill];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
        NSGradient *fill = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0], 0.0, [NSColor whiteColor], 1.0, nil];
        [fill drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1, 1, self.bounds.size.width - 2, self.bounds.size.height - 2) xRadius:3.42 yRadius:3.42] angle:90.0];
    } else {
        [[NSColor whiteColor] set];
        [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1, 1, self.bounds.size.width - 2, self.bounds.size.height - 2) xRadius:3.42 yRadius:3.42] fill];
    }
    [self.cell drawInteriorWithFrame:self.bounds inView:self];
}

@end
