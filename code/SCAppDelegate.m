#import "SCAppDelegate.h"
#import "SCAboutWindowController.h"
#import "SCPreferencesWindowController.h"
#import "SCLoginWindowController.h"
#import "SCMainWindowController.h"
#import "SCChatViewController.h"
#import "SCThemeManager.h"
#import "SCStandaloneWindowController.h"
#import "SCNotificationManager.h"
#import <objc/runtime.h>

#import <DeepEnd/DeepEnd.h>
#import <Kudryavka/Kudryavka.h>

char *const SCUnreadCountStoreKey = "";

@interface SCAppDelegate ()

@property (strong) IBOutlet NSMenuItem *networkMenu;

@end

@implementation SCAppDelegate {
    NKSerializerType saveMode;
    NSString *originalUsername;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _standaloneWindows = [[NSMutableArray alloc] initWithCapacity:5];
    if (OS_VERSION_IS_BETTER_THAN_LION) {
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = [SCNotificationManager sharedManager];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"rememberUserName"] && !([NSEvent modifierFlags] & NSAlternateKeyMask)) {
        NSString *rememberedUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberedName"];
        NSLog(@"%@", rememberedUsername);
        NSDictionary *saveOptions = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"nicknameSaveOptions"];
        if (!saveOptions[rememberedUsername] || ![saveOptions[rememberedUsername] isKindOfClass:[NSNumber class]]) {
            self.loginWindow = [[SCLoginWindowController alloc] initWithWindowNibName:@"LoginWindow"];
            [self.loginWindow showWindow:self];
        } else {
            saveOptions = saveOptions[rememberedUsername];
        }
        if (rememberedUsername && ![[rememberedUsername stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            [self beginConnectionWithUsername:rememberedUsername saveMethod:[saveOptions[@"saveOption"] integerValue]];
        }
    } else {
        self.loginWindow = [[SCLoginWindowController alloc] initWithWindowNibName:@"LoginWindow"];
        [self.loginWindow showWindow:self];
    }
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    NSLog(@"%@", filenames);
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *url = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
    NSString *publicKey = [[url substringFromIndex:6] uppercaseString];
    if (!DESFriendAddressIsValid(publicKey))
        return;
    NSLog(@"%@", publicKey);
    self.queuedPublicKey = publicKey; /* We'll look at this later. */
    if (_mainWindow)
        [_mainWindow checkKeyQueue];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (self.mainWindow) {
        [self.mainWindow showWindow:self];
    } else if (self.loginWindow) {
        [self.loginWindow showWindow:self];
    }
    return YES;
}

- (void)showMainWindow {
    if (!self.mainWindow)
        self.mainWindow = [[SCMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    [self.mainWindow showWindow:self];
}

- (void)beginConnectionWithUsername:(NSString *)theUsername saveMethod:(NKSerializerType)method {
    saveMode = method;
    originalUsername = theUsername;
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionInitialized:) name:DESConnectionDidInitNotification object:connection];
    NSInteger speed = [[NSUserDefaults standardUserDefaults] integerForKey:@"DESRunLoopSpeed"];
    if (!speed) {
        speed = (NSInteger)(1 / DEFAULT_MESSENGER_TICK_RATE);
        [[NSUserDefaults standardUserDefaults] setInteger:speed forKey:@"DESRunLoopSpeed"];
    }
    connection.runLoopSpeed = (1.0 / (double)speed);
    [connection connect];
}

- (void)saveKeys {
    NKDataSerializer *kud = [NKDataSerializer serializerUsingMethod:saveMode];
    NSError *error = nil;
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    NSDictionary *options = @{@"username": originalUsername, @"overwrite": @YES};
    if (![kud hasDataForOptions:options]) {
        BOOL ok = [kud serializePrivateKey:connection.me.privateKey publicKey:connection.me.publicKey options:options error:&error];
        if (!ok && ![error.userInfo[@"silent"] boolValue]) {
            NSRunAlertPanel(NSLocalizedString(@"Save error", @""), NSLocalizedString(@"Failed to save key: %@ Sorry about that.", @""), @"OK", nil, nil, error.userInfo[@"cause"]);
        }
    } else {
        /* There are keys saved. */
        NSDictionary *keys = [kud loadKeysWithOptions:options error:&error];
        if (!keys) {
            NSRunAlertPanel(NSLocalizedString(@"Load error", @""), NSLocalizedString(@"Failed to load keys: %@ Sorry about that.", @""), @"OK", nil, nil, error.userInfo[@"cause"]);
        } else {
            [connection setPrivateKey:keys[@"privateKey"] publicKey:keys[@"publicKey"]];
        }
    }
}

- (id<DESChatContext>)currentChatContext {
    NSWindow *keyWindow = [NSApp keyWindow];
    if (!keyWindow)
        return nil;
    if (keyWindow == self.mainWindow.window) {
        return self.mainWindow.currentContext;
    } else {
        for (SCStandaloneWindowController *win in self.standaloneWindows) {
            if (win.window == keyWindow) {
                return win.chatController.context;
            }
        }
    }
    return nil;
}

- (void)giveFocusToChatContext:(id<DESChatContext>)ctx {
    NSWindow *keyWindow = [NSApp keyWindow];
    if (keyWindow == self.mainWindow.window) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow focusContext:ctx];
    } else {
        for (SCStandaloneWindowController *win in self.standaloneWindows) {
            if (win.chatController.context == ctx) {
                [win.window makeKeyAndOrderFront:self];
                return;
            }
        }
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow focusContext:ctx];
    }
}

#pragma mark - Notifications

- (void)connectionInitialized:(NSNotification *)notification {
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    connection.me.displayName = originalUsername;
    connection.me.userStatus = @"Online";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postFriendRequestNotificationIfNeeded:) name:DESFriendRequestArrayDidChangeNotification object:connection.friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeToFriend:) name:DESFriendArrayDidChangeNotification object:connection.friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeToContext:) name:DESChatContextArrayDidChangeNotification object:connection.friendManager];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        [[NSProcessInfo processInfo] disableAutomaticTermination:@"The connection is connected."];
    [self saveKeys];
    if (self.loginWindow)
        [self.loginWindow.window close];
    [self showMainWindow];
    self.networkMenu.enabled = YES;
    for (NSMenuItem *item in self.networkMenu.submenu.itemArray) {
        item.enabled = YES;
    }
}

- (void)subscribeToFriend:(NSNotification *)notification {
    NSObject<DESChatContext> *f = notification.userInfo[DESArrayObjectKey];
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        [f addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    } else {
        [f removeObserver:self forKeyPath:@"status"];
    }
}

- (void)subscribeToContext:(NSNotification *)notification {
    NSObject<DESChatContext> *f = notification.userInfo[DESArrayObjectKey];
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatContextHadMessagePosted:) name:DESDidPushMessageToContextNotification object:f];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:DESDidPushMessageToContextNotification object:f];
    }
}

#pragma mark - Working with Chat Contexts

- (void)clearUnreadCountForChatContext:(id<DESChatContext>)ctx {
    objc_setAssociatedObject(ctx, SCUnreadCountStoreKey, @(0), OBJC_ASSOCIATION_RETAIN);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"unreadCountChanged" object:ctx userInfo:@{@"newCount": @(0)}];
}

- (void)newWindowWithDESContext:(id<DESChatContext>)aContext {
    NSMutableArray *cleanup = [[NSMutableArray alloc] initWithCapacity:_standaloneWindows.count];
    for (SCStandaloneWindowController *win in _standaloneWindows) {
        if (!win.window) {
            [cleanup addObject:win];
            continue;
        } else if (win.chatController.context == aContext) {
            [win.window makeKeyAndOrderFront:self];
            return;
        }
    }
    if ([cleanup count] != 0) {
        for (id obj in cleanup) {
            [(NSMutableArray*)_standaloneWindows removeObject:obj];
        }
    }
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(_mainWindow.window.frame.origin.x + 22, _mainWindow.window.frame.origin.y - 22, 400, 299) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
    window.delegate = self;
    window.releasedWhenClosed = YES;
    SCStandaloneWindowController *wctl = [[SCStandaloneWindowController alloc] initWithWindow:window];
    SCChatViewController *ctl = [[SCChatViewController alloc] initWithNibName:@"ChatView" bundle:[NSBundle mainBundle]];
    ctl.context = aContext;
    wctl.chatController = ctl;
    [(NSMutableArray*)_standaloneWindows addObject:wctl];
    [window setFrame:NSMakeRect(_mainWindow.window.frame.origin.x + 22, _mainWindow.window.frame.origin.y - 22, 400, 300) display:YES];
    [window makeKeyAndOrderFront:self];
}

- (void)closeWindowsContainingDESContext:(id<DESChatContext>)ctx {
    NSMutableArray *cleanup = [[NSMutableArray alloc] initWithCapacity:_standaloneWindows.count];
    for (SCStandaloneWindowController *win in _standaloneWindows) {
        if (win.chatController.context == ctx) {
            [cleanup addObject:win];
        }
    }
    if ([cleanup count] != 0) {
        for (SCStandaloneWindowController *obj in cleanup) {
            obj.chatController.context = nil;
            [(NSMutableArray*)_standaloneWindows removeObject:obj];
            [obj.window close];
        }
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    for (SCStandaloneWindowController *win in _standaloneWindows) {
        if (win.window == notification.object) {
            [self clearUnreadCountForChatContext:win.chatController.context];
            return;
        }
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    for (SCStandaloneWindowController *win in _standaloneWindows) {
        if (win.window == notification.object) {
            win.chatController.context = nil;
            return;
        }
    }
}

#pragma mark - User Notifications

- (void)postFriendRequestNotificationIfNeeded:(NSNotification *)notification {
    if (!OS_VERSION_IS_BETTER_THAN_LION)
        return;
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        NSUserNotification *unotification = [[NSUserNotification alloc] init];
        unotification.title = NSLocalizedString(@"New Friend Request", @"");
        unotification.subtitle = [NSString stringWithFormat:NSLocalizedString(@"From: %@", @""), ((DESFriend*)notification.userInfo[DESArrayObjectKey]).publicKey];
        unotification.informativeText = ((DESFriend*)notification.userInfo[DESArrayObjectKey]).requestInfo;
        [[SCNotificationManager sharedManager] postNotification:unotification ofType:SCEventTypeNewFriendRequest];
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}

- (void)chatContextHadMessagePosted:(NSNotification *)notification {
    DESMessage *msg = notification.userInfo[DESMessageKey];
    if ((msg.type != DESMessageTypeChat && msg.type != DESMessageTypeAction) || msg.sender == [DESSelf selfWithConnection:((id<DESChatContext>)notification.object).friendManager.connection]) {
        return;
    }
    if ([self currentChatContext] != notification.object && notification.object != _mainWindow.currentContext) {
        id a = objc_getAssociatedObject(notification.object, SCUnreadCountStoreKey);
        if (![a isKindOfClass:[NSNumber class]]) {
            objc_setAssociatedObject(notification.object, SCUnreadCountStoreKey, @(1), OBJC_ASSOCIATION_RETAIN);
        } else {
            objc_setAssociatedObject(notification.object, SCUnreadCountStoreKey, @([a integerValue] + 1), OBJC_ASSOCIATION_RETAIN);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"unreadCountChanged" object:notification.object userInfo:@{@"newCount": @([a integerValue] + 1)}];
    }
    NSUserNotification *nc = [[NSUserNotification alloc] init];
    nc.title = ((id<DESChatContext>)notification.object).name;
    if (msg.type == DESMessageTypeChat)
        nc.informativeText = msg.content;
    else
        nc.informativeText = [NSString stringWithFormat:@"\u2022 %@ %@", msg.sender.displayName, msg.content];
    nc.userInfo = @{@"chatContext": ((id<DESChatContext>)notification.object).uuid};
    nc.icon = [NSImage imageNamed:@"user-icon-default"];
    [[SCNotificationManager sharedManager] postNotification:nc ofType:SCEventTypeNewChatMessage];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        DESFriend *obj = (DESFriend*)object;
        NSUserNotification *nc = [[NSUserNotification alloc] init];
        nc.title = obj.displayName;
        nc.userInfo = @{@"chatContext": obj.chatContext.uuid};
        if ([change[NSKeyValueChangeNewKey] integerValue] == DESFriendStatusOnline) {
            nc.subtitle = NSLocalizedString(@"is now online.", @"");
            [[SCNotificationManager sharedManager] postNotification:nc ofType:SCEventTypeFriendConnected];
        } else {
            nc.subtitle = NSLocalizedString(@"is now offline.", @"");
            [[SCNotificationManager sharedManager] postNotification:nc ofType:SCEventTypeFriendDisconnected];
        }
    }
}

#pragma mark - Menus

- (IBAction)showAboutWindow:(id)sender {
    if (!self.aboutWindow)
        self.aboutWindow = [[SCAboutWindowController alloc] initWithWindowNibName:@"AboutWindow"];
    [self.aboutWindow showWindow:self];
}

- (IBAction)showPreferencesWindow:(id)sender {
    if (!self.preferencesWindow)
        self.preferencesWindow = [[SCPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
    [self.preferencesWindow showWindow:self];
}

- (IBAction)showNicknameSet:(id)sender {
    if (self.mainWindow) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow presentNickChangeSheet:self];
    }
}

- (IBAction)showStatusSet:(id)sender {
    if (self.mainWindow) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow presentCustomStatusSheet:self];
    }
}

- (IBAction)copyPublicKey:(id)sender {
    [[NSPasteboard generalPasteboard] clearContents];
    #ifdef SC_FUN_ALLOWED
    [[NSPasteboard generalPasteboard] writeObjects:@[[NSString stringWithFormat:NSLocalizedString(@"Tox me on Tox: %@", @""), [DESSelf self].friendAddress]]];
    #else
    [[NSPasteboard generalPasteboard] writeObjects:@[[DESSelf self].friendAddress]];
    #endif
}

- (IBAction)showAddFriend:(id)sender {
    if (self.mainWindow) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow presentAddFriendSheet:self];
    }
}

- (IBAction)showRequestsWindow:(id)sender {
    if (self.mainWindow) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow presentFriendRequestsSheet:self];
    }
}

- (IBAction)showBootstrapWindow:(id)sender {
    if (self.mainWindow) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow presentBootstrappingSheet:self];
    }
}

- (IBAction)showDHTInspector:(id)sender {
    if (self.mainWindow) {
        [self.mainWindow.window makeKeyAndOrderFront:self];
        [self.mainWindow presentInspectorSheet:self];
    }
}

- (IBAction)connectToxIRC:(id)sender {
    if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"ircs://chat.freenode.net:6697/tox"]]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://webchat.freenode.net/?channels=#tox"]];
    }
}

- (IBAction)connectDeveloperIRC:(id)sender {
    if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"ircs://chat.freenode.net:6697/tox"]]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://webchat.freenode.net/?channels=#tox"]];
    }
}

- (IBAction)openToxSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://tox.im/"]];
}

- (IBAction)openGitHubAgain:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/stal888/Poison"]];
}


@end
