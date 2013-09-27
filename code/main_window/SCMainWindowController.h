#import <Cocoa/Cocoa.h>
#import <DeepEnd/DeepEnd.h>
#import "PXListViewDelegate.h"

@class SCGradientView, PXListView, SCFriendRequestsSheetController, SCThinSplitView, WebView, SCConnectionInspectorSheetController;
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
@property (strong) IBOutlet NSSegmentedControl *modeSelector;

/* Sheets */
@property (strong) IBOutlet NSPanel *statusChangeSheet;
@property (strong) IBOutlet NSPanel *nickChangeSheet;
@property (strong) IBOutlet NSTextField *nickSheetField;
@property (strong) IBOutlet NSTextField *statusSheetField;
@property (strong) IBOutlet NSPopUpButton *statusSheetPopUp;
@property (strong) SCFriendRequestsSheetController *requestSheet;
@property (strong) SCConnectionInspectorSheetController *inspectorSheet;

- (IBAction)presentBootstrappingSheet:(id)sender;
- (IBAction)presentCustomStatusSheet:(id)sender;
- (IBAction)presentNickChangeSheet:(id)sender;
- (IBAction)presentFriendRequestsSheet:(id)sender;
- (IBAction)presentAddFriendSheet:(id)sender;
- (IBAction)presentGroupChatSheet:(id)sender;
- (IBAction)presentInspectorSheet:(id)sender;
- (void)checkKeyQueue;
- (id<DESChatContext>)currentContext;
- (void)focusContext:(id<DESChatContext>)ctx;

@end
