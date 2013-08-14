#import "SCChatView.h"

@interface SCChatView ()

@property (strong) IBOutlet NSTextField *textField;

@end

@implementation SCChatView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.dragsWindow = YES;
    }
    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [newWindow setContentBorderThickness:self.textField.frame.size.height + 19 forEdge:NSMinYEdge];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.topColor set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0, [self.window contentBorderThicknessForEdge:NSMinYEdge], self.bounds.size.width, self.bounds.size.height - [self.window contentBorderThicknessForEdge:NSMinYEdge] - 1)] fill];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.4] set];
    [[NSBezierPath bezierPathWithRoundedRect:CGRectOffset(self.textField.frame, 0, -0.7) xRadius:4.0 yRadius:4.0] fill];
}

@end
