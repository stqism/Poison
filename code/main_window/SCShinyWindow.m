#import "SCShinyWindow.h"
#import "SCDHTStatusView.h"
#import <objc/runtime.h>

@implementation SCShinyWindow

- (void)awakeFromNib {
    self.indicator = [[SCDHTStatusView alloc] initWithFrame:(NSRect){{0, 0}, {16, 15}}];
    self.indicator.connectedNodes = 0;
    self.indicator.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    [[self.contentView superview] setAutoresizesSubviews:YES];
    [[self.contentView superview] addSubview:self.indicator];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositionDHT:) name:NSViewFrameDidChangeNotification object:self.indicator];
    [self repositionDHT:nil];
}

- (void)repositionDHT {
    [self repositionDHT:nil];
}

- (void)repositionDHT:(NSNotification *)notification {
    CGFloat y = floor(self.frame.size.height - self.indicator.bounds.size.height - ((22 - self.indicator.bounds.size.height) / 2));
    if ([self.screen respondsToSelector:@selector(backingScaleFactor)] && self.screen.backingScaleFactor > 1.0)
        y -= 0.5; /* Small alignment fix for HiDPI to match the fullscreen widget */
    CGFloat fullScreenOffset = [self collectionBehavior] == NSWindowCollectionBehaviorFullScreenPrimary ? 20 : 0;
    self.indicator.frameOrigin = (NSPoint){self.frame.size.width - 4 - fullScreenOffset - self.indicator.bounds.size.width, y};
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
