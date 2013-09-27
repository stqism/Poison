#import "HBAppDelegate.h"

@interface HBAppDelegate ()

@property (unsafe_unretained) IBOutlet NSButton *exportButton;

@end

@implementation HBAppDelegate {
    __unsafe_unretained NSButton *_exportButton;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"Welcome to Hibiki. Here's a list of supported sound formats on this version of Mac OS: %@", [NSSound soundUnfilteredTypes]);
    [self.window setDefaultButtonCell:_exportButton.cell];
}

@end
