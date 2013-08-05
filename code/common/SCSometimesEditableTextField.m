#import "SCSometimesEditableTextField.h"

@implementation SCSometimesEditableTextField

- (void)mouseUp:(NSEvent *)theEvent {
    if ([theEvent clickCount] == 2) {
        /* Make editable */
        self.editable = YES;
        self.textColor = [NSColor blackColor];
        self.backgroundColor = [NSColor whiteColor];
        self.drawsBackground = YES;
        [self selectText:self];
    }
}

@end
