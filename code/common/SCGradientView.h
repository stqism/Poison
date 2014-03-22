#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "SCDraggingView.h"

@interface SCGradientView : SCDraggingView

@property (strong) NSColor *topColor;
@property (strong) NSColor *bottomColor;
@property (strong) NSColor *shadowColor;
@property (strong) NSColor *borderColor;

@end
