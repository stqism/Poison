#import "Copyright.h"

#import "SCMessageTextFieldCell.h"

@implementation SCMessageTextFieldCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [self.stringValue drawInRect:CGRectInset(cellFrame, 3, 2.5) withAttributes:
     @{NSFontAttributeName: self.font}];
}

@end
