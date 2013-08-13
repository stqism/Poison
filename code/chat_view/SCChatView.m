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

- (void)drawRect:(NSRect)dirtyRect {}

@end
