#import "SCAboutWindowController.h"
#import "SCGradientView.h"
#import "SCShadowedView.h"
#import <Kudryavka/Kudryavka.h>
#import <DeepEnd/DeepEnd.h>

@implementation SCAboutWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.topHalf.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.topHalf.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.topHalf.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.topHalf.dragsWindow = YES;
    self.topHalf.needsDisplay = YES;
    self.shadowedView.backgroundColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.shadowedView.shadowColor = [NSColor colorWithCalibratedWhite:0.118 alpha:1.0];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"%@ (built from %@)", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], [NSBundle mainBundle].infoDictionary[@"SCGitRef"]];
    self.kVersion.stringValue = [NSBundle bundleWithIdentifier:@"ca.kirara.Kudryavka"].infoDictionary[@"CFBundleShortVersionString"];
    self.kDebug.stringValue = [NKDataSerializer isDebugBuild] ? @"YES" : @"NO";
    self.desVersion.stringValue = [NSBundle bundleWithIdentifier:@"ca.kirara.DeepEnd"].infoDictionary[@"CFBundleShortVersionString"];
    self.desDebug.stringValue = DESIsDebugBuild() ? @"YES" : @"NO";
}

- (IBAction)openGithub:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/stal888/Poison"]];
}

- (IBAction)openToxSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://tox.im"]];
}

@end
