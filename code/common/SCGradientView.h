#import <Cocoa/Cocoa.h>

@interface SCGradientView : NSView

@property BOOL dragsWindow;

@property (strong) NSColor *topColor;
@property (strong) NSColor *bottomColor;
@property (strong) NSColor *shadowColor;

@end
