#import "SCHoldingSplitView.h"

@implementation SCHoldingSplitView

- (CGFloat)minPossiblePositionOfDividerAtIndex:(NSInteger)dividerIndex {
    return 150.0;
}

- (CGFloat)maxPossiblePositionOfDividerAtIndex:(NSInteger)dividerIndex {
    return 300.0;
}

@end
