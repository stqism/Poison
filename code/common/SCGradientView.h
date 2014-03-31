#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "SCDraggingView.h"

@interface SCGradientView : SCDraggingView

@property (strong, nonatomic) NSColor *topColor;
@property (strong, nonatomic) NSColor *bottomColor;
@property (strong, nonatomic) NSColor *shadowColor;
@property (strong, nonatomic) NSColor *borderColor;

@end
