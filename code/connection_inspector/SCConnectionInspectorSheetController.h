#import <Cocoa/Cocoa.h>

@interface SCConnectionInspectorSheetController : NSWindowController <NSTableViewDataSource>

@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSTableView *otherTableView;
@property (strong) IBOutlet NSTextField *DHTCounter;
@property (strong) IBOutlet NSTextField *runLoopSpeed;
@property (strong) IBOutlet NSButton *endButton;

/* self.tableView */
@property (strong) IBOutlet NSTableColumn *nodeNumberColumn;
@property (strong) IBOutlet NSTableColumn *nodeAddressColumn;
@property (strong) IBOutlet NSTableColumn *nodeKeyColumn;
@property (strong) IBOutlet NSTableColumn *nodeRemarksColumn;

/* self.otherTableView */
@property (strong) IBOutlet NSTableColumn *knownSourceColumn;
@property (strong) IBOutlet NSTableColumn *knownAddress;
@property (strong) IBOutlet NSTableColumn *knownPublicKey;
@property (strong) IBOutlet NSTableColumn *knownTimestamp;

@property (strong) IBOutlet NSTextField *publicKey;
@property (strong) IBOutlet NSTextField *privateKey;

- (void)startTimer;
- (void)stopTimer;

@end
