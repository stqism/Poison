#import "SCMainWindowController.h"
#import "SCShinyWindow.h"
#import "SCDHTStatusView.h"
#import "SCGradientView.h"
#import "PXListView.h"
#import "PXListViewCell+Private.h"
#import "SCFriendRequestsSheetController.h"
#import "SCFriendListHeaderCell.h"
#import "SCFriendListItemCell.h"
#import "SCAddFriendSheetController.h"
#import "SCChatViewController.h"
#import "SCBootstrapSheetController.h"
#import "SCAppDelegate.h"
#import "SCBootstrapManager.h"
#import <DeepEnd/DeepEnd.h>
#import <WebKit/WebKit.h>

@interface SCThinSplitView : NSSplitView

@end

@implementation SCThinSplitView

- (NSColor *)dividerColor {
    return [NSColor controlDarkShadowColor];
}

@end

@implementation SCMainWindowController {
    NSArray *_friendList;
    SCAddFriendSheetController *_addFriendSheet;
    SCChatViewController *chatView;
    SCBootstrapSheetController *_bootstrapSheet;
    NSUInteger selected;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        /* To eliminate IB warning, set fullscreen capability in code. */
        self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    self.window.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restrainSplitter:) name:NSWindowDidResizeNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadList:) name:DESFriendArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(confirmDeleteFriend:) name:@"deleteFriend" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFriendRequestCount:) name:DESFriendRequestArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    [self updateFriendRequestCount:nil];
    [(SCShinyWindow*)self.window repositionDHT];
    self.sidebarHead.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.sidebarHead.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.sidebarHead.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.sidebarHead.dragsWindow = YES;
    self.sidebarHead.needsDisplay = YES;
    self.toolbar.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.toolbar.bottomColor = [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
    self.toolbar.shadowColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.toolbar.dragsWindow = YES;
    self.toolbar.needsDisplay = YES;
    [self.displayName.cell setTextColor:[NSColor whiteColor]];
    [self.userStatus.cell setTextColor:[NSColor controlColor]];
    self.userImage.layer.cornerRadius = 2.0;
    self.userImage.layer.masksToBounds = YES;
    selected = -1;
    self.listView.delegate = self;
    [self reloadList:nil];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        self.listView.scrollerKnobStyle = NSScrollerKnobStyleLight; /* Set in code to avoid IB warning. */
    [[DESSelf self] addObserver:self forKeyPath:@"userStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESSelf self] addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESSelf self] addObserver:self forKeyPath:@"statusType" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESToxNetworkConnection sharedConnection] addObserver:self forKeyPath:@"connectedNodeCount" options:NSKeyValueObservingOptionNew context:NULL];
    ((SCShinyWindow*)self.window).indicator.connectedNodes = [[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue];
    if (!chatView)
        chatView = [[SCChatViewController alloc] initWithNibName:@"ChatView" bundle:[NSBundle mainBundle]];
    [self.splitView replaceSubview:self.splitView.subviews[1] with:chatView.view];
    ((SCShinyWindow*)self.window).indicator.target = self;
    ((SCShinyWindow*)self.window).indicator.action = @selector(presentBootstrappingSheet:);
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue] > GOOD_CONNECTION_THRESHOLD) {
            [self checkKeyQueue];
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUseSavedBSSettings"]) {
                [self presentBootstrappingSheet:self];
                return;
            }
            NSString *type = [[NSUserDefaults standardUserDefaults] stringForKey:@"bootstrapType"];
            if ([type isEqualToString:@"auto"]) {
                SCBootstrapManager *m = [[SCBootstrapManager alloc] init];
                [m performAutomaticBootstrapWithSuccessCallback:^{} failureBlock:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentBootstrappingSheet:self];
                    });
                }];
            } else if ([type isEqualToString:@"manual"]) {
                NSDictionary *d = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"manualBSSavedServer"];
                if (![d isMemberOfClass:[NSDictionary class]] || !SCBootstrapDictIsValid(d)) {
                    [self presentBootstrappingSheet:self];
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    NSHost *h = [NSHost hostWithName:d[@"host"]];
                    NSString *addr = [h address];
                    if (addr) {
                        [[DESToxNetworkConnection sharedConnection] bootstrapWithAddress:addr port:[d[@"port"] unsignedShortValue] publicKey:d[@"publicKey"]];
                    }
                    double delayInSeconds = 4.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if ([[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue] < GOOD_CONNECTION_THRESHOLD) {
                            [self presentBootstrappingSheet:self];
                        }
                    });
                });
            } else {
                [self presentBootstrappingSheet:self];
            }
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [DESSelf self]) {
        if ([keyPath isEqualToString:@"userStatus"]) {
            self.userStatus.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"displayName"]) {
            self.displayName.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"statusType"]) {
            switch ([DESSelf self].statusType) {
                case DESStatusTypeAway:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-away"];
                    break;
                case DESStatusTypeBusy:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-offline"];
                    break;
                default:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-online"];
                    break;
            }
        }
    } else if (object == [DESToxNetworkConnection sharedConnection]) {
        ((SCShinyWindow*)self.window).indicator.connectedNodes = [change[NSKeyValueChangeNewKey] integerValue];
    }
}

- (IBAction)statusLabelAction:(NSTextField *)sender {
    sender.editable = NO;
    sender.backgroundColor = [NSColor clearColor];
    if (sender == self.displayName)
        sender.textColor = [NSColor whiteColor];
    else
        sender.textColor = [NSColor controlColor];
    sender.drawsBackground = NO;
    DESSelf *me = [DESToxNetworkConnection sharedConnection].me;
    NSString *proposedChange = [sender.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (sender == self.displayName) {
        if ([me.displayName isEqualToString:proposedChange] || [proposedChange isEqualToString:@""]) {
            sender.stringValue = me.displayName;
            return;
        }
        me.displayName = proposedChange;
    } else if (sender == self.userStatus) {
        if ([me.userStatus isEqualToString:proposedChange] || [proposedChange isEqualToString:@""]) {
            sender.stringValue = me.userStatus;
            return;
        }
        me.userStatus = proposedChange;
    }
}

- (IBAction)quickChangeStatus:(NSMenuItem *)sender {
    switch (sender.tag) {
        case 0:
            [[DESToxNetworkConnection sharedConnection].me setUserStatus:@"Online" kind:DESStatusTypeOnline];
            break;
        case 1:
            [[DESToxNetworkConnection sharedConnection].me setUserStatus:@"Away" kind:DESStatusTypeAway];
            break;
        case 2:
            [[DESToxNetworkConnection sharedConnection].me setUserStatus:@"Busy" kind:DESStatusTypeBusy];
            break;
        default:
            break;
    }
}

- (void)checkKeyQueue {
    SCAppDelegate *delegate = [NSApp delegate];
    if (delegate.queuedPublicKey && !self.window.attachedSheet) {
        if (!_addFriendSheet)
            _addFriendSheet = [[SCAddFriendSheetController alloc] initWithWindowNibName:@"AddFriend"];
        [_addFriendSheet loadWindow];
        [_addFriendSheet fillFields];
        _addFriendSheet.keyField.stringValue = delegate.queuedPublicKey;
        [NSApp beginSheet:_addFriendSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(addFriendSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
    delegate.queuedPublicKey = nil;
}

- (void)updateFriendRequestCount:(NSNotification *)notification {
    unsigned long c = (unsigned long)[DESToxNetworkConnection sharedConnection].friendManager.requests.count;
    if (c)
        self.requestsCount.stringValue = [NSString stringWithFormat:@"%lu", c];
    else
        self.requestsCount.stringValue = @"";
}

- (void)confirmDeleteFriend:(NSNotification *)notification {
    if (self.window.attachedSheet)
        return;
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you really want to delete %@ from your friends list?", @""), ((DESFriend*)notification.userInfo[@"friend"]).displayName] defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:NSLocalizedString(@"You cannot undo this, and all chat history will be lost.", @"")];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(deleteFriendConfirmDidEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)notification.userInfo[@"friend"]];
}

- (void)deleteFriendConfirmDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    DESFriend *f = (__bridge DESFriend*)contextInfo;
    if (returnCode == NSOKButton) {
        [f.owner removeFriend:f];
    }
}

- (void)dealloc {
    [[DESSelf self] removeObserver:self forKeyPath:@"userStatus"];
    [[DESSelf self] removeObserver:self forKeyPath:@"displayName"];
    [[DESSelf self] removeObserver:self forKeyPath:@"statusType"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Sheets

- (IBAction)presentAddFriendSheet:(id)sender {
    if (!_addFriendSheet)
        _addFriendSheet = [[SCAddFriendSheetController alloc] initWithWindowNibName:@"AddFriend"];
    [_addFriendSheet loadWindow];
    [_addFriendSheet fillFields];
    [NSApp beginSheet:_addFriendSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(addFriendSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)addFriendSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (IBAction)presentBootstrappingSheet:(id)sender {
    if (!_bootstrapSheet)
        _bootstrapSheet = [[SCBootstrapSheetController alloc] initWithWindowNibName:@"BootstrapSheet"];
    [NSApp beginSheet:_bootstrapSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(bootstrapSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)bootstrapSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
    [self checkKeyQueue];
}

- (IBAction)presentCustomStatusSheet:(id)sender {
    self.statusSheetField.stringValue = [DESToxNetworkConnection sharedConnection].me.userStatus;
    switch ([DESSelf self].statusType) {
        case DESStatusTypeAway:
            [self.statusSheetPopUp selectItemWithTag:2];
            break;
        case DESStatusTypeBusy:
            [self.statusSheetPopUp selectItemWithTag:3];
            break;
        default:
            [self.statusSheetPopUp selectItemWithTag:1];
            break;
    }
    [NSApp beginSheet:self.statusChangeSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)presentNickChangeSheet:(id)sender {
    self.nickSheetField.stringValue = [DESToxNetworkConnection sharedConnection].me.displayName;
    [NSApp beginSheet:self.nickChangeSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)presentFriendRequestsSheet:(id)sender {
    if (!self.requestSheet)
        self.requestSheet = [[SCFriendRequestsSheetController alloc] initWithWindowNibName:@"Requests"];
    [NSApp beginSheet:self.requestSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(closeRequestsSheet:returnCode:contextInfo:) contextInfo:NULL];
    [self.requestSheet fillFields];
}

- (IBAction)confirmAndEndSheet:(NSButton *)sender {
    [NSApp endSheet:self.window.attachedSheet returnCode:sender.tag];
}

- (void)closeRequestsSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *proposed = nil;
    [sheet orderOut:self];
    switch (returnCode) {
        case 1: /* Nickname was changed. */
            proposed = [self.nickSheetField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([proposed isEqualToString:@""]) return;
            if (![[DESToxNetworkConnection sharedConnection].me.displayName isEqualToString:proposed]) {
                [DESToxNetworkConnection sharedConnection].me.displayName = proposed;
            }
            break;
        case 2: {
            proposed = [self.statusSheetField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([proposed isEqualToString:@""]) return;
            DESStatusType kind = DESStatusTypeOnline;
            switch([self.statusSheetPopUp.selectedItem tag]) {
                case 1:
                    kind = DESStatusTypeOnline; break;
                case 2:
                    kind = DESStatusTypeAway; break;
                case 3:
                    kind = DESStatusTypeBusy; break;
                default:
                    break;
            }
            DESFriend *me = [DESSelf self];
            if ((![me.userStatus isEqualToString:proposed]) || me.statusType != kind) {
                [(DESSelf*)me setUserStatus:proposed kind:kind];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - NSWindow delegate

- (void)restrainSplitter:(NSNotification *)notification {
    CGFloat originalPosition = ((NSView*)[self.splitView subviews][0]).frame.size.width;
    self.splitView.frame = ((NSView*)self.window.contentView).frame;
    [self.splitView setPosition:originalPosition ofDividerAtIndex:0];
}

- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window {
    ((SCShinyWindow*)self.window).indicator.hidden = YES;
    return nil;
}

- (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window {
    ((SCShinyWindow*)self.window).indicator.hidden = NO;
    return nil;
}

- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
    ((SCShinyWindow*)self.window).indicator.hidden = NO;
}

#pragma mark - NSSplitView delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedPosition < 150) {
        return 150;
    } else if (proposedPosition > 300) {
        return 300;
    } else {
        return proposedPosition;
    }
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

#pragma mark - PXListView delegate

- (DESFriend *)friendInRow:(NSUInteger)row {
    if (row == 0 || row == -1)
        return nil;
    return _friendList[row - 1];
}

- (void)selectFriend:(DESFriend *)aFriend {
    if (!aFriend)
        return;
    NSUInteger row = [_friendList indexOfObject:aFriend];
    if (row == NSNotFound)
        return;
    else
        self.listView.selectedRow = row + 1;
}

- (void)reloadList:(NSNotification *)notification {
    NSArray *fl = [[DESToxNetworkConnection sharedConnection].friendManager.friends copy];
    NSUInteger selIndex = self.listView.selectedRow;
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeRemove) {
        [(SCAppDelegate*)[NSApp delegate] closeWindowsContainingDESContext:[self friendInRow:selIndex].chatContext];
        if (((DESFriend*)notification.userInfo[DESArrayFriendKey]).chatContext == chatView.context) {
            chatView.context = nil;
        }
        selIndex -= 1;
    } else if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd && (selIndex == -1 || selIndex == 0)) {
        selIndex = 1;
    }
    if (selIndex == 0) {
        selIndex = -1;
        selected = 0;
    }
    _friendList = fl;
    [self.listView reloadData];
    self.listView.selectedRow = selIndex;
}

- (void)listViewSelectionDidChange:(NSNotification *)aNotification {
    if (self.listView.selectedRow == -1 || self.listView.selectedRow == 0) {
        if (selected != -1 && selected != 0) {
            self.listView.selectedRow = selected;
        } else {
            chatView.context = nil;
        }
    } else {
        selected = self.listView.selectedRow;
        chatView.context = [self friendInRow:self.listView.selectedRow].chatContext;
    }
}

- (void)listView:(PXListView *)aListView rowDoubleClicked:(NSUInteger)rowIndex {
    if (self.listView.selectedRow == -1 || self.listView.selectedRow == 0) {
        return;
    }
    SCAppDelegate *delegate = [NSApp delegate];
    [delegate newWindowWithDESContext:[self friendInRow:rowIndex].chatContext];
}

- (NSUInteger)numberOfRowsInListView:(PXListView *)aListView {
    return [_friendList count] + 1;
}

- (CGFloat)listView:(PXListView *)aListView heightOfRow:(NSUInteger)row {
    if (row == 0)
        return 17;
    else
        return 42;
}

- (PXListViewCell *)listView:(PXListView *)aListView cellForRow:(NSUInteger)row {
    if (row == 0) {
        SCFriendListHeaderCell *cell = nil;
        if (!(cell = (SCFriendListHeaderCell*)[aListView dequeueCellWithReusableIdentifier:@"SectHeader"])) {
            cell = [[SCFriendListHeaderCell alloc] initWithFrame:NSMakeRect(0, 0, 100, 17)];
            cell.reusableIdentifier = @"SectHeader";
        }
        cell.stringValue = NSLocalizedString(@"Friends", @"");
        return cell;
    } else {
        SCFriendListItemCell *cell = nil;
        if (!(cell = (SCFriendListItemCell*)[aListView dequeueCellWithReusableIdentifier:@"FriendCell"])) {
            cell = [SCFriendListItemCell cellLoadedFromNibNamed:@"FriendCell" bundle:[NSBundle mainBundle] reusableIdentifier:@"FriendCell"];
        }
        [cell bindToFriend:[self friendInRow:row]];
        return cell;
    }
}

#pragma mark - Misc.

BOOL SCBootstrapDictIsValid(NSDictionary *theDict) {
    NSHost *dns = [NSHost hostWithName:theDict[@"host"]];
    NSString *addr = [dns address];
    if (!addr) {
        return NO;
    }
    NSNumber *portobj = theDict[@"port"];
    if (!portobj || [portobj longLongValue] < 1 || [portobj longLongValue] > 65535) {
        return NO;
    }
    if (!DESPublicKeyIsValid(theDict[@"publicKey"])) {
        return NO;
    }
    return YES;
}

@end
