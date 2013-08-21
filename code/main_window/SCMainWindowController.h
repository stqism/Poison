#import <Cocoa/Cocoa.h>
#import "PXListViewDelegate.h"

@class SCGradientView, PXListView, SCFriendRequestsSheetController, SCThinSplitView, WebView;
@interface SCMainWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate, PXListViewDelegate>

@property (strong) IBOutlet SCThinSplitView *splitView;
@property (strong) IBOutlet NSImageView *userImage;
@property (strong) IBOutlet SCGradientView *sidebarHead;
@property (strong) IBOutlet NSTextField *displayName;
@property (strong) IBOutlet NSTextField *userStatus;
@property (strong) IBOutlet NSImageView *statusLight;
@property (strong) IBOutlet PXListView *listView;
@property (strong) IBOutlet SCGradientView *toolbar;
@property (strong) IBOutlet NSTextField *requestsCount;

/* Sheets */
@property (strong) IBOutlet NSPanel *statusChangeSheet;
@property (strong) IBOutlet NSPanel *nickChangeSheet;
@property (strong) IBOutlet NSTextField *nickSheetField;
@property (strong) IBOutlet NSTextField *statusSheetField;
@property (strong) IBOutlet NSPopUpButton *statusSheetPopUp;
@property (strong) SCFriendRequestsSheetController *requestSheet;

- (IBAction)presentBootstrappingSheet:(id)sender;
- (IBAction)presentCustomStatusSheet:(id)sender;
- (IBAction)presentNickChangeSheet:(id)sender;
- (IBAction)presentFriendRequestsSheet:(id)sender;
- (IBAction)presentAddFriendSheet:(id)sender;
- (void)checkKeyQueue;

@end
