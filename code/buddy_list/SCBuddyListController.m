#include "Copyright.h"

#import "ObjectiveTox.h"
#import "SCBuddyListController.h"
#import "SCGradientView.h"

#define SC_MAX_CACHED_ROW_COUNT (50)

NS_INLINE NSImage *SCImageForFriendStatus(DESFriendStatus s) {
    switch (s) {
        case DESFriendStatusAvailable:
            return [NSImage imageNamed:@"status-light-online"];
        case DESFriendStatusAway:
            return [NSImage imageNamed:@"status-light-away"];
        case DESFriendStatusBusy:
            return [NSImage imageNamed:@"status-light-offline"];
        default:
            return [NSImage imageNamed:@"status-light-missing"];
    }
}

@interface SCFriendRowView : NSTableRowView

@end

@implementation SCFriendRowView

- (void)drawRect:(NSRect)dirtyRect {
//    if (self.isSelected) {
//        [[NSColor colorWithCalibratedWhite:0.04 alpha:1.0] set];
//        [[NSBezierPath bezierPathWithRect:NSMakeRect(-2, 0, self.bounds.size.width + 2, self.bounds.size.height)] stroke];
//        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.35] set];
//        [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 1, self.bounds.size.width, 1)] fill];
//        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.20] set];
//        [[NSBezierPath bezierPathWithRect:NSMakeRect(0, self.bounds.size.height - 2, self.bounds.size.width, 1)] fill];
//        NSGradient *bodyGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.10] endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.20]];
//        [bodyGrad drawInBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(-2, 2, self.bounds.size.width + 2, self.bounds.size.height - 4)] angle:-90.0];
//    }
    if (self.isSelected) {
        NSGradient *shadowGrad = [[NSGradient alloc] initWithStartingColor:[NSColor clearColor] endingColor:[NSColor colorWithCalibratedWhite:0.071 alpha:0.3]];
        [[NSColor colorWithCalibratedWhite:0.118 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect:self.bounds] fill];
        [shadowGrad drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, -4, self.bounds.size.width, 8)] angle:-90.0];
        [shadowGrad drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, self.bounds.size.height - 4, self.bounds.size.width, 8)] angle:90.0];
    }
}

@end

@interface SCBuddyListController ()
@property (strong) IBOutlet SCGradientView *userInfo;
@property (strong) IBOutlet SCGradientView *toolbar;
@property (strong) IBOutlet SCGradientView *auxiliaryView;
@property (strong) IBOutlet NSTableView *friendListView;
@property (strong) IBOutlet NSMenu *friendMenu;
@property (strong) IBOutlet NSMenu *selfMenu;
@property (strong) IBOutlet NSSearchField *filterField;
#pragma mark - self info
@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSTextField *statusField;
@property (strong) IBOutlet NSImageView *statusDot;

@property (strong) NSMutableSet *rowCache;
#pragma mark - Change name and status
@property (strong) IBOutlet NSPanel *identityEditorSheet;
@property (strong) IBOutlet NSTextField *ieNameField;
@property (strong) IBOutlet NSTextField *ieStatusField;
@property (strong) IBOutlet NSPopUpButton *ieStatusChooser;
@end

@implementation SCBuddyListController {
    DESToxConnection *_watchingConnection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.rowCache = [[NSMutableSet alloc] initWithCapacity:10];
    }
    return self;
}

- (void)awakeFromNib {
    self.userInfo.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.userInfo.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.userInfo.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.userInfo.dragsWindow = YES;
    self.toolbar.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.toolbar.bottomColor = [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
    self.toolbar.shadowColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.toolbar.dragsWindow = YES;
    self.auxiliaryView.topColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
    self.auxiliaryView.bottomColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.auxiliaryView.borderColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
    self.auxiliaryView.shadowColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.auxiliaryView.dragsWindow = YES;
    self.friendListView.dataSource = self;
    self.friendListView.delegate = self;
}

- (void)detachHandlersFromConnection {
    [_watchingConnection removeObserver:self forKeyPath:@"name"];
    [_watchingConnection removeObserver:self forKeyPath:@"statusMessage"];
    [_watchingConnection removeObserver:self forKeyPath:@"status"];
}

- (void)attachKVOHandlersToConnection:(DESToxConnection *)tox {
    [self detachHandlersFromConnection];
    _watchingConnection = tox;
    [tox addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [tox addObserver:self forKeyPath:@"statusMessage" options:NSKeyValueObservingOptionNew context:NULL];
    [tox addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    if (tox.isActive) {
        self.nameField.stringValue = tox.name;
        self.statusField.stringValue = tox.statusMessage;
        self.statusDot.image = SCImageForFriendStatus(tox.status);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"name"]) {
        self.nameField.stringValue = change[NSKeyValueChangeNewKey];
    } else if ([keyPath isEqualToString:@"statusMessage"]) {
        self.statusField.stringValue = change[NSKeyValueChangeNewKey];
    } else if ([keyPath isEqualToString:@"status"]) {
        self.statusDot.image = SCImageForFriendStatus((DESFriendStatus)((NSNumber *)change[NSKeyValueChangeNewKey]).intValue);
    }
}

#pragma mark - ui crap

- (IBAction)changeName:(id)sender {
    [self presentChangeSheetHighlightingField:0];
}

- (IBAction)changeStatus:(id)sender {
    [self presentChangeSheetHighlightingField:1];
}

- (void)presentChangeSheetHighlightingField:(NSInteger)field {
    self.ieNameField.stringValue = _watchingConnection.name;
    self.ieStatusField.stringValue = _watchingConnection.statusMessage;
    [self.ieStatusChooser selectItemAtIndex:(NSInteger)_watchingConnection.status];

    [NSApp beginSheet:self.identityEditorSheet
       modalForWindow:self.view.window
        modalDelegate:self
       didEndSelector:@selector(commitIdentityChangesFromSheet:returnCode:userInfo:)
          contextInfo:NULL];

    switch (field) {
        case 0:
            [self.ieNameField selectText:self];
            [self.ieNameField becomeFirstResponder];
            break;
        case 1:
            [self.ieStatusField selectText:self];
            [self.ieStatusField becomeFirstResponder];
            break;
        default:
            break;
    }
}

- (void)commitIdentityChangesFromSheet:(NSWindow *)sheet returnCode:(NSInteger)ret userInfo:(void *)ignored {
    [sheet orderOut:self];
    if (!ret)
        return;
    if (![self.ieNameField.stringValue isEqualToString:_watchingConnection.name]) {
        _watchingConnection.name = self.ieNameField.stringValue;
    }
    if (![self.ieStatusField.stringValue isEqualToString:_watchingConnection.statusMessage]) {
        _watchingConnection.statusMessage = self.ieStatusField.stringValue;
    }
    if (self.ieStatusChooser.selectedTag != _watchingConnection.status) {
        _watchingConnection.status = self.ieStatusChooser.selectedTag;
    }
}

- (IBAction)finishAndCommit:(NSButton *)sender {
    [NSApp endSheet:self.identityEditorSheet returnCode:sender.tag];
}

#pragma mark - table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 1000;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    id rowView = [self.rowCache anyObject];
    if (!rowView) {
        rowView = [[SCFriendRowView alloc] initWithFrame:CGRectZero];
    } else {
        [self.rowCache removeObject:rowView];
    }
    return rowView;
}

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    if ([self.rowCache count] < SC_MAX_CACHED_ROW_COUNT)
        [self.rowCache addObject:rowView];
}

- (void)dealloc {
    [self detachHandlersFromConnection];
}

@end
