#import "SCShinyWindow.h"
#import "SCDHTStatusView.h"

@implementation SCShinyWindow

- (void)awakeFromNib {
    self.indicator = [[SCDHTStatusView alloc] initWithFrame:(NSRect){CGPointZero, 16, 15}];
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
    CGFloat fullScreenOffset = [self collectionBehavior] == NSWindowCollectionBehaviorFullScreenPrimary ? 20 : 0;
    self.indicator.frameOrigin = (NSPoint){self.frame.size.width - 4 - fullScreenOffset - self.indicator.bounds.size.width, floor(self.frame.size.height - self.indicator.bounds.size.height - ((22 - self.indicator.bounds.size.height) / 2))};
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
