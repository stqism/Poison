#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "ObjectiveTox.h"
#import "SCMainWindowing.h"
#include "tox.h"

@interface SCAppDelegate : NSObject <NSApplicationDelegate, DESToxConnectionDelegate>
@property (strong, nonatomic) NSWindowController *mainWindowController;
- (void)makeApplicationReadyForToxing:(txd_intermediate_t)userProfile
                                 name:(NSString *)profileName
                             password:(NSString *)pass;
@end
