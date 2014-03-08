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
#import "SCConnectionInspectorSheetController.h"
#import "SCNotificationManager.h"
#import "SCGroupChatSheetController.h"
#import "SCFriendListGroupCell.h"
#import "SCGroupRequestCell.h"
#import <DeepEnd/DeepEnd.h>
#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, SCListMode) {
    SCListModeFriends = 0,
    SCListModeGroups = 1,
};

@interface SCThinSplitView : NSSplitView

@end

@implementation SCThinSplitView

- (NSColor *)dividerColor {
    return [NSColor controlDarkShadowColor];
}

@end

@implementation SCMainWindowController {
    NSArray *_friendList;
    NSArray *_groupList;
    SCAddFriendSheetController *_addFriendSheet;
    SCGroupChatSheetController *_groupChatSheet;
    SCChatViewController *chatView;
    SCBootstrapSheetController *_bootstrapSheet;
    NSUInteger selectedGroup;
    NSUInteger selectedFriend;
    SCListMode listMode;
    BOOL autoBootstrapNeedsToStop;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        /* To eliminate IB warning, set fullscreen capability in code. */
        self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    self.window.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restrainSplitter:) name:NSWindowDidResizeNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadList:) name:DESFriendArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadList:) name:DESGroupRequestArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadList:) name:DESChatContextArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(confirmDeleteFriend:) name:@"deleteFriend" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(confirmDeleteGroup:) name:@"leaveGroupChat" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(joinGroupChat:) name:@"joinGroup" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rejectGroupChat:) name:@"rejectGroup" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFriendRequestCount:) name:DESFriendRequestArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    selectedGroup = -1;
    selectedFriend = -1;
    NSString *modeStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"harmonicsCurrentSelected"];
    if ([modeStr isEqualToString:@"groups"]) {
        listMode = SCListModeGroups;
        self.modeSelector.selectedSegment = 1;
    } else {
        listMode = SCListModeFriends;
        self.modeSelector.selectedSegment = 0;
    }
    self.listView.delegate = self;
    [self userInterfaceSetup];
    [self reloadList:nil];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        self.listView.scrollerKnobStyle = NSScrollerKnobStyleLight; /* Set in code to avoid IB warning. */
    [[DESSelf self] addObserver:self forKeyPath:@"userStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESSelf self] addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESSelf self] addObserver:self forKeyPath:@"statusType" options:NSKeyValueObservingOptionNew context:NULL];
    self.displayName.stringValue = [DESSelf self].displayName;
    self.userStatus.stringValue = [DESSelf self].userStatus;
    [self observeValueForKeyPath:@"statusType" ofObject:[DESSelf self] change:@{} context:NULL];
    [[DESToxNetworkConnection sharedConnection] addObserver:self forKeyPath:@"connectedNodeCount" options:NSKeyValueObservingOptionNew context:NULL];
    ((SCShinyWindow*)self.window).indicator.connectedNodes = [[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue];
    if (!chatView)
        chatView = [[SCChatViewController alloc] initWithNibName:@"ChatView" bundle:[NSBundle mainBundle]];
    [self.splitView replaceSubview:self.splitView.subviews[1] with:chatView.view];
    chatView.context = nil;
    ((SCShinyWindow*)self.window).indicator.target = self;
    ((SCShinyWindow*)self.window).indicator.action = @selector(presentInspectorOrBootstrappingSheet:);
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue] >= GOOD_CONNECTION_THRESHOLD) {
            [self checkKeyQueue];
        } else {
            [self presentBootstrapOrDoItAutomatically];
        }
    });
}

- (void)userInterfaceSetup {
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
}

- (void)presentBootstrapOrDoItAutomatically {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUseSavedBSSettings"]) {
        NSString *type = [[NSUserDefaults standardUserDefaults] stringForKey:@"bootstrapType"];
        if ([type isEqualToString:@"auto"]) {
            SCBootstrapManager *m = [[SCBootstrapManager alloc] init];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [m performAutomaticBootstrapWithSuccessCallback:^{} failureBlock:^{
                    if (autoBootstrapNeedsToStop)
                        return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentBootstrappingSheet:self];
                    });
                } stop:&autoBootstrapNeedsToStop];
            });
        } else if ([type isEqualToString:@"manual"]) {
            NSDictionary *d = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"manualBSSavedServer"];
            if (![d isKindOfClass:[NSDictionary class]] || !SCBootstrapDictIsValid(d)) {
                [self presentBootstrappingSheet:self];
                return;
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
    } else {
        [self presentBootstrappingSheet:self];
    }
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
        [_addFriendSheet revalidate];
        [NSApp beginSheet:_addFriendSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(addFriendSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
    delegate.queuedPublicKey = nil;
}

- (id<DESChatContext>)currentContext {
    return chatView.context;
}

- (void)focusContext:(id<DESChatContext>)ctx {
    [self selectContext:ctx];
}

- (void)updateFriendRequestCount:(NSNotification *)notification {
    unsigned long c = (unsigned long)[DESToxNetworkConnection sharedConnection].friendManager.requests.count;
    if (c)
        self.requestsCount.stringValue = [NSString stringWithFormat:@"%lu", c];
    else
        self.requestsCount.stringValue = @"";
}

- (void)confirmDeleteFriend:(NSNotification *)notification {
    if (self.window.attachedSheet || !notification.userInfo[@"friend"])
        return;
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you really want to delete %@ from your friends list?", @""), ((DESFriend*)notification.userInfo[@"friend"]).displayName] defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:NSLocalizedString(@"You cannot undo this, and all chat history will be lost.", @"")];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(deleteFriendConfirmDidEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)notification.userInfo[@"friend"]];
}

- (void)confirmDeleteGroup:(NSNotification *)notification {
    if (self.window.attachedSheet || !notification.userInfo[@"chat"])
        return;
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Do you really want to leave this group chat?", @"") defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:NSLocalizedString(@"You won't be able to join again without an invitation.", @"")];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(deleteGroupConfirmDidEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)notification.userInfo[@"chat"]];
}

- (void)deleteFriendConfirmDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    DESFriend *f = (__bridge DESFriend*)contextInfo;
    if (returnCode == NSOKButton) {
        [f.owner removeFriend:f];
    }
}

- (void)deleteGroupConfirmDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    id<DESChatContext> f = (__bridge id)contextInfo;
    if (returnCode == NSOKButton) {
        [f.friendManager removeGroupChat:f];
    }
}

- (void)joinGroupChat:(NSNotification *)notification {
    DESGroupChat *grp = notification.userInfo[@"invite"];
    id<DESChatContext> ret = [grp.owner joinGroupChat:grp];
    if (!ret) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to join group chat", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The group chat could not be joined because an error occurred.", @"")];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)rejectGroupChat:(NSNotification *)notification {
    DESGroupChat *grp = notification.userInfo[@"invite"];
    [grp.owner rejectGroupChatInvitation:grp];
}

- (IBAction)modeChange:(NSSegmentedControl *)sender {
    [self changeListMode:sender.selectedSegment];
}

- (void)willLogOut {
    [[DESSelf self] removeObserver:self forKeyPath:@"userStatus"];
    [[DESSelf self] removeObserver:self forKeyPath:@"displayName"];
    [[DESSelf self] removeObserver:self forKeyPath:@"statusType"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self willLogOut];
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
    _addFriendSheet = nil;
}

- (IBAction)presentGroupChatSheet:(id)sender {
    if (!_groupChatSheet)
        _groupChatSheet = [[SCGroupChatSheetController alloc] initWithWindowNibName:@"NewGroupChat"];
    [_groupChatSheet loadWindow];
    [NSApp beginSheet:_groupChatSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(groupChatSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)groupChatSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
    _groupChatSheet = nil;
}

- (IBAction)presentBootstrappingSheet:(id)sender {
    if (!_bootstrapSheet)
        _bootstrapSheet = [[SCBootstrapSheetController alloc] initWithWindowNibName:@"BootstrapSheet"];
    [NSApp beginSheet:_bootstrapSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(bootstrapSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)bootstrapSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
    [self checkKeyQueue];
    _bootstrapSheet = nil;
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
    [NSApp beginSheet:self.requestSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(closedSheet:returnCode:contextInfo:) contextInfo:NULL];
    [self.requestSheet fillFields];
}

- (IBAction)presentInspectorSheet:(id)sender {
    if (!self.inspectorSheet)
        self.inspectorSheet = [[SCConnectionInspectorSheetController alloc] initWithWindowNibName:@"ConnectionInspector"];
    [NSApp beginSheet:self.inspectorSheet.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(closedSheet:returnCode:contextInfo:) contextInfo:NULL];
    [self.inspectorSheet startTimer];
}

- (IBAction)confirmAndEndSheet:(NSButton *)sender {
    [NSApp endSheet:self.window.attachedSheet returnCode:sender.tag];
}

- (void)closedSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *proposed = nil;
    [sheet orderOut:self];
    switch (returnCode) {
        case 1: {/* Nickname was changed. */
            proposed = [self.nickSheetField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([proposed isEqualToString:@""]) return;
            if (![[DESToxNetworkConnection sharedConnection].me.displayName isEqualToString:proposed]) {
                [DESToxNetworkConnection sharedConnection].me.displayName = proposed;
            }
            break;
        }
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

- (IBAction)deleteFriendHighlightedInList:(id)sender {
    if (self.listView.selectedRow == -1)
        return;
    /* Pretend user clicked Delete Friend... in cell's menu. */
    NSNotification *dummy = nil;
    if (listMode == SCListModeFriends)
        dummy = [NSNotification notificationWithName:@"deleteFriend" object:nil userInfo:@{@"friend": [self friendInRow:self.listView.selectedRow]}];
    else
        dummy = [NSNotification notificationWithName:@"leaveGroupChat" object:nil userInfo:@{@"chat": [self groupChatInRow:self.listView.selectedRow]}];
    [self confirmDeleteFriend:dummy];
}

- (IBAction)presentInspectorOrBootstrappingSheet:(id)sender {
    if ([[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue] >= GOOD_CONNECTION_THRESHOLD) {
        [self presentInspectorSheet:sender];
    } else {
        [self presentBootstrappingSheet:sender];
    }
}

#pragma mark - NSWindow delegate

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

- (void)windowDidChangeBackingProperties:(NSNotification *)notification {
    [(SCShinyWindow*)self.window repositionDHT];
}

#pragma mark - NSSplitView delegate

- (void)restrainSplitter:(NSNotification *)notification {
    CGFloat originalPosition = ((NSView*)[self.splitView subviews][0]).frame.size.width;
    self.splitView.frame = ((NSView*)self.window.contentView).frame;
    [self.splitView setPosition:originalPosition ofDividerAtIndex:0];
}

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

/* TODO: VERY IMPORTANT: cleanup this code!!!
 * Adding the groupchat tab to it made it really messy. 
 * Maybe split the PXListViewDelegate methods off to their own
 * class? */

- (void)changeListMode:(SCListMode)mode {
    if (mode == listMode)
        return;
    self.modeSelector.selectedSegment = (mode == SCListModeGroups);
    listMode = mode;
    NSString *modeStr = (mode == SCListModeGroups) ? @"groups" : @"friends";
    [[NSUserDefaults standardUserDefaults] setObject:modeStr forKey:@"harmonicsCurrentSelected"];
    [_listView reloadData];
    _listView.selectedRow = (mode == SCListModeGroups ? selectedGroup : selectedFriend);
}

- (DESFriend *)friendInRow:(NSUInteger)row {
    if (row == -1 || row >= [_friendList count])
        return nil;
    return _friendList[row];
}

- (id<DESChatContext>)groupChatInRow:(NSUInteger)row {
    if (row == -1 || row >= [_groupList count])
        return nil;
    if ([_groupList[row] isKindOfClass:[DESGroupChat class]])
        return nil;
    else
        return _groupList[row];
}

- (void)selectContext:(id<DESChatContext>)aContext {
    if (!aContext)
        return;
    if (aContext.type == DESContextTypeOneToOne && listMode != SCListModeFriends) {
        [self changeListMode:SCListModeFriends];
    } else if (aContext.type == DESContextTypeGroupChat && listMode != SCListModeGroups) {
        [self changeListMode:SCListModeGroups];
    }
    if (aContext.type == DESContextTypeOneToOne) {
        [_friendList enumerateObjectsUsingBlock:^(DESFriend *obj, NSUInteger idx, BOOL *stop) {
            if (obj.chatContext == aContext) {
                self.listView.selectedRow = idx;
                *stop = YES;
            }
        }];
    } else {
        [_groupList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (obj == aContext) {
                self.listView.selectedRow = idx;
                *stop = YES;
            }
        }];
    }
}

- (void)reloadListModeFriends:(NSNotification *)notification {
    NSArray *fl = [[DESToxNetworkConnection sharedConnection].friendManager.friends copy];
    NSUInteger selIndex = self.listView.selectedRow;
    DESFriend *f = ((DESFriend*)notification.userInfo[DESArrayObjectKey]);
    if (!f && notification) {
        [self.listView reloadData];
        self.listView.selectedRow = selIndex;
        return;
    }
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeRemove) {
        [(SCAppDelegate*)[NSApp delegate] closeWindowsContainingDESContext:f.chatContext];
        if (f.chatContext == chatView.context) {
            chatView.context = nil;
        }
        selIndex -= 1;
    } else if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        if (selIndex == -1)
            selIndex = 0;
    }
    _friendList = fl;
    if (selIndex >= [_friendList count] && [fl count] <= 0) {
        selIndex = -1;
        selectedFriend = -1;
    } else if ([fl count] > 0) {
        selIndex = 0;
    }
    if (listMode == SCListModeFriends) {
        [self.listView reloadData];
        self.listView.selectedRow = selIndex;
    }
}

- (void)reloadListModeGroups:(NSNotification *)notification {
    DESFriendManager *fm = [DESToxNetworkConnection sharedConnection].friendManager;
    NSArray *inviteList = [fm.groupRequests copy];
    NSArray *groupContexts = [fm.chatContexts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<DESChatContext> obj, NSDictionary *bindings) {
        return [obj type] == DESContextTypeGroupChat;
    }]];
    NSMutableArray *c = [[NSMutableArray alloc] initWithCapacity:[inviteList count] + [groupContexts count]];
    [c addObjectsFromArray:groupContexts];
    [c addObjectsFromArray:inviteList];
    NSInteger numberOfGroupRequests = [inviteList count];
    if (numberOfGroupRequests) {
        [self.modeSelector setLabel:[NSString stringWithFormat:NSLocalizedString(@"Groups (%li)", @""), numberOfGroupRequests] forSegment:1];
    } else {
        [self.modeSelector setLabel:[NSString stringWithFormat:NSLocalizedString(@"Groups", @""), numberOfGroupRequests] forSegment:1];
    }
    _groupList = c;
    NSUInteger selIndex = self.listView.selectedRow;
    /* We can make the assumption that invites will never be selected,
     * so we don't have to muck around with invisible boundaries etc... */
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeRemove) {
        [(SCAppDelegate*)[NSApp delegate] closeWindowsContainingDESContext:notification.userInfo[DESArrayObjectKey]];
        if (notification.userInfo[DESArrayObjectKey] == chatView.context) {
            chatView.context = nil;
        }
        selIndex -= 1;
    } else if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        if (selIndex == -1)
            selIndex = 0;
    }
    if (selIndex >= [groupContexts count]) {
        selIndex = -1;
        selectedGroup = -1;
    }
    if (listMode == SCListModeGroups) {
        [self.listView reloadData];
        self.listView.selectedRow = selIndex;
    }
}

- (void)reloadList:(NSNotification *)notification {
    if (!notification) {
        [self reloadListModeFriends:nil];
        [self reloadListModeGroups:nil];
    } else if (notification.name == DESFriendArrayDidChangeNotification) {
        [self reloadListModeFriends:notification];
    } else {
        [self reloadListModeGroups:notification];
    }
}

- (void)listViewSelectionDidChangeModeFriends:(NSNotification *)aNotification {
    DESFriend *friend = [self friendInRow:self.listView.selectedRow];
    if (friend) {
        chatView.context = friend.chatContext;
        [(SCAppDelegate*)[NSApp delegate] clearUnreadCountForChatContext:friend.chatContext];
    }
    [(SCFriendListItemCell*)[self.listView cellForRowAtIndex:self.listView.selectedRow] changeUnreadIndicatorState:YES];
}

- (void)listViewSelectionDidChangeModeGroups:(NSNotification *)aNotification {
    id<DESChatContext> grp = [self groupChatInRow:self.listView.selectedRow];
    if (grp) {
        chatView.context = grp;
        [(SCAppDelegate*)[NSApp delegate] clearUnreadCountForChatContext:grp];
    } else {
        if ([self groupChatInRow:selectedGroup]) {
            self.listView.selectedRow = selectedGroup;
        } else {
            selectedGroup = -1;
            self.listView.selectedRow = -1;
        }
    }
}

- (void)listViewSelectionDidChange:(NSNotification *)aNotification {
    if (self.listView.selectedRow == -1) {
        if (listMode == SCListModeFriends) {
            if (selectedFriend != -1) {
                self.listView.selectedRow = selectedFriend;
            } else {
                chatView.context = nil;
            }
        } else {
            if (selectedGroup != -1) {
                self.listView.selectedRow = selectedGroup;
            } else {
                chatView.context = nil;
            }
        }
    } else {
        if (listMode == SCListModeFriends) {
            selectedFriend = self.listView.selectedRow;
            [self listViewSelectionDidChangeModeFriends:aNotification];
        } else {
            selectedGroup = self.listView.selectedRow;
            [self listViewSelectionDidChangeModeGroups:aNotification];
        }
    }
}

- (void)listView:(PXListView *)aListView rowDoubleClicked:(NSUInteger)rowIndex {
    if (self.listView.selectedRow == -1) {
        return;
    }
    SCAppDelegate *delegate = [NSApp delegate];
    [delegate newWindowWithDESContext:[self friendInRow:rowIndex].chatContext];
}

- (NSUInteger)numberOfRowsInListView:(PXListView *)aListView {
    if (listMode == SCListModeFriends)
        return [_friendList count];
    else
        return [_groupList count];
}

- (CGFloat)listView:(PXListView *)aListView heightOfRow:(NSUInteger)row {
    return 42;
}

- (PXListViewCell *)listView:(PXListView *)aListView friendModeCellForRow:(NSUInteger)row {
    SCFriendListItemCell *cell = nil;
    if (!(cell = (SCFriendListItemCell*)[aListView dequeueCellWithReusableIdentifier:@"FriendCell"])) {
        cell = [SCFriendListItemCell cellLoadedFromNibNamed:@"FriendCell" bundle:[NSBundle mainBundle] reusableIdentifier:@"FriendCell"];
    }
    DESFriend *friend = [self friendInRow:row];
    [cell bindToFriend:friend];
    return cell;
}

- (PXListViewCell *)listView:(PXListView *)aListView groupsModeCellForRow:(NSUInteger)row {
    id listobj = _groupList[row];
    if ([listobj conformsToProtocol:@protocol(DESChatContext)]) {
        SCFriendListGroupCell *cell = nil;
        if (!(cell = (SCFriendListGroupCell*)[aListView dequeueCellWithReusableIdentifier:@"GroupCell"])) {
            cell = [SCFriendListGroupCell cellLoadedFromNibNamed:@"GroupCell" bundle:[NSBundle mainBundle] reusableIdentifier:@"GroupCell"];
        }
        [cell bindToChatContext:listobj];
        return cell;
    } else if ([listobj isKindOfClass:[DESGroupChat class]]) {
        SCGroupRequestCell *cell = nil;
        if (!(cell = (SCGroupRequestCell*)[aListView dequeueCellWithReusableIdentifier:@"GroupRequestCell"])) {
            cell = [SCGroupRequestCell cellLoadedFromNibNamed:@"GroupRequestCell" bundle:[NSBundle mainBundle] reusableIdentifier:@"GroupRequestCell"];
        }
        [cell bindToGroupChat:listobj];
        return cell;
    }
    return nil;
}

- (PXListViewCell *)listView:(PXListView *)aListView cellForRow:(NSUInteger)row {
    if (listMode == SCListModeFriends)
        return [self listView:aListView friendModeCellForRow:row];
    else
        return [self listView:aListView groupsModeCellForRow:row];
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
