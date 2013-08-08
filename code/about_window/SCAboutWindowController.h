#import <Cocoa/Cocoa.h>

@class SCGradientView, SCShadowedView;
@interface SCAboutWindowController : NSWindowController

@property (strong) IBOutlet SCGradientView *topHalf;
@property (strong) IBOutlet NSTextField *versionLabel;
@property (strong) IBOutlet SCShadowedView *shadowedView;
@property (strong) IBOutlet NSTextField *kVersion;
@property (strong) IBOutlet NSTextField *kDebug;
@property (strong) IBOutlet NSTextField *desVersion;
@property (strong) IBOutlet NSTextField *desDebug;

@end
