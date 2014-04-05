#include "Copyright.h"

#import "SCSelectiveMenuTableView.h"

@implementation SCSelectiveMenuTableView {
    NSInteger _clickedRow;
}

- (NSInteger)clickedRow {
    return _clickedRow;
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    NSPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
    NSInteger row = [self rowAtPoint:loc];
    if (row == -1)
        return nil;
    if ([self.delegate respondsToSelector:@selector(tableView:menuForRow:)]) {
        _clickedRow = row;
        return [(id<SCSelectiveMenuTableViewing>)self.delegate tableView:self menuForRow:row];
    }
    return nil;
}

@end
