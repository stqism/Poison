#import "SCChatView.h"
#import "SCTextField.h"

@interface SCChatView ()

@property (strong) IBOutlet NSView *textField;
@property (strong) IBOutlet NSResponder *proxyResponder;

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
    CGFloat yo = [self.window contentBorderThicknessForEdge:NSMinYEdge];
    [[NSBezierPath bezierPathWithRect:(NSRect){{0, yo}, {self.bounds.size.width, self.bounds.size.height - yo}}] fill];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.4] set];
    [[NSBezierPath bezierPathWithRoundedRect:CGRectOffset(CGRectInset(self.textField.frame, 5, 5), 0, -0.7) xRadius:4.0 yRadius:4.0] fill];
}

- (void)keyDown:(NSEvent *)theEvent {
    [self.window makeFirstResponder:self.proxyResponder];
    /* When the text field loses focus, we have to save the selection
     * beforehand so we can restore it here. See SCChatViewController,
     * controlTextDidEndEditing. */
    [(SCTextField*)self.proxyResponder restoreSelection];
    /* Now that the text field has been focused, send the event again.
     * It should go to the textfield now. */
    [NSApp sendEvent:theEvent];
}

@end
