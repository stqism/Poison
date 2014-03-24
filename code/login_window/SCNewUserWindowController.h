#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "SCGradientView.h"
#import "SCShadowedView.h"

@interface SCNewUserWindowController : NSWindowController <NSWindowDelegate, NSTextFieldDelegate>
@property (strong) IBOutlet SCGradientView *header;
@property (strong) IBOutlet SCShadowedView *footer;

- (void)tryAutomaticLogin:(NSString *)name;
@end
