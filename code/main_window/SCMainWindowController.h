#import <Cocoa/Cocoa.h>

@class SCGradientView;
@interface SCMainWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate>

@property (strong) IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet NSImageView *userImage;
@property (strong) IBOutlet SCGradientView *sidebarHead;
@property (strong) IBOutlet NSTextField *displayName;
@property (strong) IBOutlet NSTextField *userStatus;

/* Sheets */
@property (strong) IBOutlet NSPanel *statusChangeSheet;
@property (strong) IBOutlet NSPanel *nickChangeSheet;
@property (strong) IBOutlet NSTextField *nickSheetField;
@property (strong) IBOutlet NSTextField *statusSheetField;

@end
