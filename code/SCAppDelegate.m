#import "SCAppDelegate.h"
#import "SCLoginWindowController.h"

@implementation SCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.loginWindow = [[SCLoginWindowController alloc] initWithWindowNibName:@"SCLoginWindowController"];
    [self.loginWindow showWindow:self];
}

@end
