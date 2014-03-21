#import "SCNonGarbageSplitView.h"

@implementation SCNonGarbageSplitView

- (NSColor *)dividerColor {
    if ([self.delegate respondsToSelector:@selector(dividerColourForSplitView:)])
        return [(id<SCNonGarbageSplitViewDelegate>)self.delegate dividerColourForSplitView:self];
    return [super dividerColor];
}

- (CGFloat)dividerThickness {
    if ([self.delegate respondsToSelector:@selector(dividerThicknessForSplitView:)])
        return [(id<SCNonGarbageSplitViewDelegate>)self.delegate dividerThicknessForSplitView:self];
    return [super dividerThickness];
}

- (void)drawDividerInRect:(NSRect)rect {
    if ([self.delegate respondsToSelector:@selector(splitView:drawDividerInRect:)])
        return [(id<SCNonGarbageSplitViewDelegate>)self.delegate splitView:self drawDividerInRect:rect];
    return [super drawDividerInRect:rect];
}

- (CGFloat)maxPossiblePositionOfDividerAtIndex:(NSInteger)dividerIndex {
    if ([self.delegate respondsToSelector:@selector(splitView:maxPossiblePositionOfDividerAtIndex:)])
        return [(id<SCNonGarbageSplitViewDelegate>)self.delegate splitView:self maxPossiblePositionOfDividerAtIndex:dividerIndex];
    return [super maxPossiblePositionOfDividerAtIndex:dividerIndex];
}

- (CGFloat)minPossiblePositionOfDividerAtIndex:(NSInteger)dividerIndex {
    if ([self.delegate respondsToSelector:@selector(splitView:minPossiblePositionOfDividerAtIndex:)])
        return [(id<SCNonGarbageSplitViewDelegate>)self.delegate splitView:self minPossiblePositionOfDividerAtIndex:dividerIndex];
    return [super minPossiblePositionOfDividerAtIndex:dividerIndex];
}

@end
