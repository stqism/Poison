#import "HBAppDelegate.h"

@implementation HBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"Welcome to Hibiki. Here's a list of supported sound formats on this version of Mac OS: %@", [NSSound soundUnfilteredTypes]);
}

@end
