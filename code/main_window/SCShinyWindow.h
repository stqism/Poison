#import <Cocoa/Cocoa.h>

@class SCDHTStatusView;
@interface SCShinyWindow : NSWindow

@property (strong) SCDHTStatusView *indicator;
- (void)repositionDHT;

@end
