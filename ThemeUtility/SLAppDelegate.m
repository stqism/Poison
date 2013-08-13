#import "SLAppDelegate.h"

@implementation SLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)save:(id)sender {
    [@{
      @"aiThemeBackgroundColor": @"#FFFFFF",
      @"aiThemeHumanReadableName": @"Default",
      @"aiThemeShortVersionString": @"1.0",
      @"aiThemeDescription": @"The default chat style used by Poison.",
      @"aiThemeAuthor": @"stal",
      @"aiThemeBaseTemplateName": @"themebase.html",
     } writeToFile:[NSString stringWithFormat:@"%@/theme.plist", NSHomeDirectory()] atomically:YES];
}

@end
