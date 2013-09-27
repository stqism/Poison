#import "SCTextField.h"
#import <QuartzCore/QuartzCore.h>

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

@implementation SCTextField {
    CAShapeLayer *shadowLayer;
    CAShapeLayer *maskLayer;
    NSRange selectedRange;
}

+ (Class)cellClass {
    return [SCTextFieldCell class];
}

- (void)updateShadowLayerWithRect:(NSRect)rect {
    shadowLayer.frame = self.bounds;
    CGMutablePathRef innerPath = CGPathCreateMutable();
    CGRect innerRect = CGRectInset(rect, 4, 4);
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    CGPathMoveToPoint(innerPath, NULL, innerRect.origin.x, outside_top);
    CGPathAddLineToPoint(innerPath, NULL, inside_right, outside_top);
    CGPathAddArcToPoint(innerPath, NULL, outside_right, outside_top, outside_right, inside_top, 4);
    CGPathAddLineToPoint(innerPath, NULL, outside_right, inside_bottom);
    CGPathAddArcToPoint(innerPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, 4);
    CGPathAddLineToPoint(innerPath, NULL, innerRect.origin.x, outside_bottom);
    CGPathAddArcToPoint(innerPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, 4);
    CGPathAddLineToPoint(innerPath, NULL, outside_left, inside_top);
    CGPathAddArcToPoint(innerPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, 4);
    CGPathCloseSubpath(innerPath);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(-10, -10, self.bounds.size.width + 20, self.bounds.size.height + 20));
    CGPathAddPath(path, NULL, innerPath);
    CGPathCloseSubpath(path);
    shadowLayer.path = path;
    CGPathRelease(innerPath);
    CGPathRelease(path);
    CGMutablePathRef maskPath = CGPathCreateMutable();
    rect = CGRectMake(rect.origin.x + 1, rect.origin.y + 1, rect.size.width - 2, rect.size.height - 2);
    innerRect = CGRectInset(rect, 3.42, 3.42);
    inside_right = innerRect.origin.x + innerRect.size.width;
    outside_right = rect.origin.x + rect.size.width;
    inside_bottom = innerRect.origin.y + innerRect.size.height;
    outside_bottom = rect.origin.y + rect.size.height;
    inside_top = innerRect.origin.y;
    outside_top = rect.origin.y;
    outside_left = rect.origin.x;
    CGPathMoveToPoint(maskPath, NULL, innerRect.origin.x, outside_top);
    CGPathAddLineToPoint(maskPath, NULL, inside_right, outside_top);
    CGPathAddArcToPoint(maskPath, NULL, outside_right, outside_top, outside_right, inside_top, 3.42);
    CGPathAddLineToPoint(maskPath, NULL, outside_right, inside_bottom);
    CGPathAddArcToPoint(maskPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, 3.42);
    CGPathAddLineToPoint(maskPath, NULL, innerRect.origin.x, outside_bottom);
    CGPathAddArcToPoint(maskPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, 3.42);
    CGPathAddLineToPoint(maskPath, NULL, outside_left, inside_top);
    CGPathAddArcToPoint(maskPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, 3.42);
    CGPathCloseSubpath(maskPath);
    maskLayer.path = maskPath;
    CGPathRelease(maskPath);
}

- (void)awakeFromNib {
    self.bezeled = YES;
    self.drawsBackground = NO;
    self.wantsLayer = YES;
    self.layer.masksToBounds = YES;
    shadowLayer = [CAShapeLayer layer];
    NSColor *shadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1];
    NSInteger numberOfComponents = [shadowColor numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [shadowColor.colorSpace CGColorSpace];
    [shadowColor getComponents:components];
    CGColorRef c = CGColorCreate(colorSpace, components);
    shadowLayer.shadowColor = c;
    CGColorRelease(c);
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
        shadowLayer.shadowRadius = 1.0;
        shadowLayer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        shadowLayer.shadowOpacity = 0.3f;
    } else {
        shadowLayer.shadowRadius = 0;
        shadowLayer.shadowOffset = CGSizeMake(0.0f, -2.0f);
        shadowLayer.shadowOpacity = 0.1f;
    }
    shadowLayer.fillRule = kCAFillRuleEvenOdd;
    maskLayer = [CAShapeLayer layer];
    [self.layer addSublayer:shadowLayer];
    shadowLayer.mask = maskLayer;
    [self updateShadowLayerWithRect:self.bounds];
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

- (void)clearSelection {
    selectedRange = NSMakeRange(0, 0);
}

- (void)saveSelection {
    selectedRange = [self.window fieldEditor:YES forObject:self].selectedRange;
}

- (void)restoreSelection {
    [self.window fieldEditor:YES forObject:self].selectedRange = selectedRange;
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
