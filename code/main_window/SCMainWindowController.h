#import <Cocoa/Cocoa.h>

@class SCGradientView;
@interface SCMainWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate>

@property (strong) IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet NSImageView *userImage;
@property (strong) IBOutlet SCGradientView *sidebarHead;
@property (strong) IBOutlet NSTextField *displayName;
@property (strong) IBOutlet NSTextField *userStatus;
@property (strong) IBOutlet NSImageView *statusLight;

@end
