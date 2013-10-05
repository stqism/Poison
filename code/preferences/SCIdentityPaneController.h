#import <Cocoa/Cocoa.h>

@interface SCIdentityPaneController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
@property (strong) IBOutlet NSPopUpButton *identityPopup;
@property (strong) IBOutlet NSTextField *nameEditField;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSTextView *dataComment;
@property (strong) IBOutlet NSTableColumn *imageColumn;

@end
