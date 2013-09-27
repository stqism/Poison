#import <Cocoa/Cocoa.h>

@interface SCGroupChatSheetController : NSWindowController <NSTableViewDataSource>

@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSTableView *friendsList;

@end
