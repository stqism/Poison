#include "Copyright.h"

#import "ObjectiveTox.h"
#import "SCMainWindowing.h"
#import "SCBuddyListController.h"
#import "SCGradientView.h"
#import "SCProfileManager.h"
#import "SCBuddyListShared.h"
#import "SCBuddyListCells.h"
#import <sodium.h>
#import <Quartz/Quartz.h>

#define SC_MAX_CACHED_ROW_COUNT (50)

@interface SCDoubleClickingImageView : NSImageView

@end

@implementation SCDoubleClickingImageView

- (void)mouseDown:(NSEvent *)theEvent {
    if (theEvent.clickCount == 2 && self.action)
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:self];
        #pragma clang diagnostic pop
    else
        [super mouseDown:theEvent];
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
@property (strong) IBOutlet NSImageView *avatarView;

@property (strong) NSMutableSet *rowCache;
#pragma mark - Change name and status
@property (strong) IBOutlet NSPanel *identityEditorSheet;
@property (strong) IBOutlet NSTextField *ieNameField;
@property (strong) IBOutlet NSTextField *ieStatusField;
@property (strong) IBOutlet NSPopUpButton *ieStatusChooser;

@property (strong) IBOutlet NSPanel *nicknameEditorSheet;
@property (strong) IBOutlet NSTextField *origNameLabel;
@property (strong) IBOutlet NSTextField *nicknameField;
@end

@implementation SCBuddyListController {
    DESToxConnection *_watchingConnection;
    NSMutableArray *_orderingList;
    NSDateFormatter *_formatter;
    NSCache *_hashCache;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.rowCache = [[NSMutableSet alloc] initWithCapacity:100];
        _orderingList = [[NSMutableArray alloc] initWithCapacity:10];
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.doesRelativeDateFormatting = YES;
        _formatter.timeStyle = NSDateFormatterShortStyle;
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

    self.avatarView.wantsLayer = YES;
    NSImage *mask = [NSImage imageNamed:@"avatar_mask"];
    CALayer *maskLayer = [CALayer layer];
    maskLayer.frame = (CGRect){CGPointZero, self.avatarView.frame.size};
    maskLayer.contents = (id)mask;
    self.avatarView.layer.mask = maskLayer;
}

- (void)detachHandlersFromConnection {
    [_watchingConnection removeObserver:self forKeyPath:@"name"];
    [_watchingConnection removeObserver:self forKeyPath:@"statusMessage"];
    [_watchingConnection removeObserver:self forKeyPath:@"status"];
    [_watchingConnection removeObserver:self forKeyPath:@"friends"];
}

- (void)attachKVOHandlersToConnection:(DESToxConnection *)tox {
    [self detachHandlersFromConnection];
    _watchingConnection = tox;
    [tox addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [tox addObserver:self forKeyPath:@"statusMessage" options:NSKeyValueObservingOptionNew context:NULL];
    [tox addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [tox addObserver:self forKeyPath:@"friends" options:NSKeyValueObservingOptionNew context:NULL];
    if (tox.isActive) {
        self.nameField.stringValue = tox.name;
        self.statusField.stringValue = tox.statusMessage;
        self.statusDot.image = SCImageForFriendStatus(tox.status);
        [self repopulateOrderingList];
        [self.friendListView reloadData];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    change = [change copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:@"name"]) {
            self.nameField.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"statusMessage"]) {
            self.statusField.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"status"]) {
            self.statusDot.image = SCImageForFriendStatus((DESFriendStatus)((NSNumber *)change[NSKeyValueChangeNewKey]).intValue);
        } else if ([keyPath isEqualToString:@"friends"]) {
            [self repopulateOrderingList];
            NSSet *changed = change[NSKeyValueChangeNewKey];
            NSMutableIndexSet *changeIndexes = [[NSMutableIndexSet alloc] init];
            for (DESFriend *obj in changed) {
                [changeIndexes addIndex:obj.peerNumber];
            }
            if ([change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeInsertion) {
                [self.friendListView insertRowsAtIndexes:changeIndexes withAnimation:NSTableViewAnimationSlideDown];
            } else if ([change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeRemoval) {
                [self.friendListView removeRowsAtIndexes:changeIndexes withAnimation:NSTableViewAnimationSlideUp];
            }
            NSLog(@"%@", change);
        }
    });
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
    [NSApp endSheet:self.view.window.attachedSheet returnCode:sender.tag];
}

#pragma mark - table

- (void)repopulateOrderingList {
    NSSet *set = _watchingConnection.friends;
    _orderingList = [[NSMutableArray alloc] initWithCapacity:set.count];
    for (DESFriend *friend in set) {
        [_orderingList addObject:@(friend.peerNumber)];
    }
    [_orderingList sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        if ([obj1 isGreaterThan:obj2])
            return NSOrderedDescending;
        else if ([obj1 isLessThan:obj2])
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _orderingList.count;
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SCFriendCellView *dequeued = [tableView makeViewWithIdentifier:@"FriendCell" owner:nil];
    dequeued.manager = self;
    [dequeued applyMaskIfRequired];
    return dequeued;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSNumber *peerNum = _orderingList[row];
    return [_watchingConnection friendWithID:[peerNum intValue]];
}

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    if ([self.rowCache count] < SC_MAX_CACHED_ROW_COUNT)
        [self.rowCache addObject:rowView];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSUInteger ci = self.friendListView.clickedRow;
    DESFriend *f = [_watchingConnection friendWithID:[_orderingList[ci] intValue]];
    [menu itemAtIndex:0].title = f.name;
}

#pragma mark - cell server

- (NSString *)formatDate:(NSDate *)date {
    if ([[NSDate date] timeIntervalSinceDate:date] > 86400)
        _formatter.dateStyle = NSDateFormatterShortStyle;
    else
        _formatter.dateStyle = NSDateFormatterNoStyle;
    return [NSString stringWithFormat:NSLocalizedString(@"Offline since: %@", nil), [_formatter stringFromDate:date]];
}

- (NSString *)lookupCustomNameForID:(NSString *)id_ {
    /* We don't want to leak friend IDs in NSUserDefaults.
     * Therefore, hash them first. */
    NSDictionary *map = [SCProfileManager privateSettingForKey:@"nicknames"];
    return map[id_];
}

- (void)dealloc {
    [self detachHandlersFromConnection];
}

#pragma mark - misc menus

- (IBAction)showAddFriend:(id)sender {
    /* kinda hacky... should have just redirected it to the appdelegate */
    if ([self.view.window.windowController respondsToSelector:@selector(displayAddFriend)]) {
        [(id<SCMainWindowing>)self.view.window.windowController displayAddFriend];
    }
}

- (IBAction)presentNicknameEditor:(id)sender {
    NSUInteger ci = self.friendListView.clickedRow;
    DESFriend *f = [_watchingConnection friendWithID:[_orderingList[ci] intValue]];

    NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *displayName = f.name;
    if ([[displayName stringByTrimmingCharactersInSet:cs] isEqualToString:@""])
        displayName = [NSString stringWithFormat:NSLocalizedString(@"Unknown (%@)", nil), [f.publicKey substringToIndex:8]];

    CGFloat frameHeightNormal = (self.nicknameEditorSheet.frame.size.height
                                 - self.origNameLabel.frame.size.height);
    CGRect bb = [displayName boundingRectWithSize:(NSSize){self.origNameLabel.frame.size.width}
                             options:NSStringDrawingUsesLineFragmentOrigin
                             attributes:@{NSFontAttributeName: self.origNameLabel.font}];
    [self.nicknameEditorSheet setFrame:(CGRect){CGPointZero, {self.nicknameEditorSheet.frame.size.width, frameHeightNormal + bb.size.height}} display:NO];

    self.origNameLabel.stringValue = displayName;
    ((NSTextFieldCell *)self.nicknameField.cell).placeholderString = displayName;
    [NSApp beginSheet:self.nicknameEditorSheet modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(commitNicknameFromSheet:returnCode:userInfo:) contextInfo:(__bridge void *)(f)];
}

- (void)commitNicknameFromSheet:(NSWindow *)sheet returnCode:(NSInteger)ret userInfo:(void *)friend {
    NSLog(@"commit %@ for %@", self.nicknameField.stringValue, (__bridge id)friend);
    DESFriend *f = (__bridge DESFriend *)friend;
    NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *dn = [self.nicknameField.stringValue stringByTrimmingCharactersInSet:cs];

    if (ret == 0) {
        [sheet orderOut:self];
        self.nicknameField.stringValue = @"";
        return;
    }
    
    if (ret == 2 || [dn isEqualToString:@""]) {
        NSMutableDictionary *map = [[SCProfileManager privateSettingForKey:@"nicknames"] mutableCopy] ?: [NSMutableDictionary dictionary];
        [map removeObjectForKey:f.publicKey];
        [SCProfileManager setPrivateSetting:map forKey:@"nicknames"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [SCProfileManager commitPrivateSettings];
        });
    } else if (ret == 1) {
        NSMutableDictionary *map = [[SCProfileManager privateSettingForKey:@"nicknames"] mutableCopy] ?: [NSMutableDictionary dictionary];
        map[f.publicKey] = dn;
        [SCProfileManager setPrivateSetting:map forKey:@"nicknames"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [SCProfileManager commitPrivateSettings];
        });
    }
    self.nicknameField.stringValue = @"";
    [sheet orderOut:self];

    [self.friendListView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[_orderingList indexOfObject:@(f.peerNumber)]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark - avatars

- (IBAction)clickAvatarImage:(id)sender {
    IKPictureTaker *taker = [IKPictureTaker pictureTaker];
    taker.inputImage = self.avatarView.image;
    [taker beginPictureTakerSheetForWindow:self.view.window withDelegate:self
                            didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:)
                               contextInfo:NULL];
}

- (void)pictureTakerDidEnd:(IKPictureTaker *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        self.avatarView.image = sheet.outputImage;
        // commit avatar change...
    }
}

@end
