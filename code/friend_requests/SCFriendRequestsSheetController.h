#import <Cocoa/Cocoa.h>
#import "PXListViewDelegate.h"

@class PXListView, SCGradientView;
@interface SCFriendRequestsSheetController : NSWindowController <NSWindowDelegate, PXListViewDelegate>
@property (strong) IBOutlet PXListView *listView;
@property (strong) IBOutlet NSView *requestPane;
@property (strong) IBOutlet SCGradientView *headerView;

@property (strong) IBOutlet NSTextView *dataField;
@property (strong) IBOutlet NSTextField *keyField;
@property (strong) IBOutlet NSTextField *dateField;

@property (strong) IBOutlet NSButton *acceptButton;
@property (strong) IBOutlet NSButton *rejectButton;
@end
