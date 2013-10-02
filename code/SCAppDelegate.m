#import "SCAppDelegate.h"
#import "SCAboutWindowController.h"
#import "SCPreferencesWindowController.h"
#import "SCLoginWindowController.h"
#import "SCMainWindowController.h"
#import "SCChatViewController.h"
#import "SCThemeManager.h"
#import "SCStandaloneWindowController.h"
#import "SCNotificationManager.h"
#import "SCSoundManager.h"
#import "SCIdentityUnlockWindowController.h"
#import <objc/runtime.h>

#import <DeepEnd/DeepEnd.h>
#import <Kudryavka/Kudryavka.h>

char *const SCUnreadCountStoreKey = "";

@interface SCAppDelegate ()

@property (strong) IBOutlet NSMenuItem *networkMenu;

@end

@implementation SCAppDelegate {
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
        if (rememberedUsername && ![[rememberedUsername stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            [self beginConnectionWithUsername:rememberedUsername];
        } else {
            self.loginWindow = [[SCLoginWindowController alloc] initWithWindowNibName:@"LoginWindow"];
            [self.loginWindow showWindow:self];
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

- (void)saveData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *profilePath = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"] stringByAppendingPathComponent:originalUsername];
        if ([[NSFileManager defaultManager] createDirectoryAtPath:profilePath withIntermediateDirectories:YES attributes:nil error:nil]) {
            NKDataSerializer *kud = [[NKDataSerializer alloc] init];
            [[kud encryptedDataWithConnection:[DESToxNetworkConnection sharedConnection] password:self.encPassword] writeToFile:[profilePath stringByAppendingPathComponent:@"data.txd"] atomically:YES];
            NSLog(@"Data was saved.");
        } else {
            NSLog(@"Data couldn't be saved.");
        }
    });
}

- (NSString *)findPasswordInKeychain:(NSString *)name {
    UInt32 length = 0;
    uint8_t *buffer;
    NSString *theService = @"ca.kirara.Poison.passwordStore";
    OSStatus ret = SecKeychainFindGenericPassword(NULL, (UInt32)[theService lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [theService UTF8String], (UInt32)[name lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [name UTF8String], &length, (void**)&buffer, NULL);
    if (ret != errSecSuccess) {
        return nil;
    }
    NSString *pass = [[NSString alloc] initWithBytes:buffer length:length encoding:NSUTF8StringEncoding];
    SecKeychainItemFreeContent(NULL, buffer);
    return pass;
}

- (void)clearPasswordFromKeychain:(NSString *)pass username:(NSString *)user {
    NSString *theService = @"ca.kirara.Poison.passwordStore";
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
    item[(id)kSecClass] = (__bridge id)(kSecClassGenericPassword);
    item[(id)kSecAttrAccount] = user;
    item[(id)kSecAttrService] = theService;
    SecItemDelete((__bridge CFDictionaryRef)(item));
}

- (void)dumpPasswordToKeychain:(NSString *)pass username:(NSString *)user {
    NSString *theService = @"ca.kirara.Poison.passwordStore";
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
    item[(id)kSecClass] = (__bridge id)(kSecClassGenericPassword);
    item[(id)kSecAttrAccount] = user;
    item[(id)kSecAttrService] = theService;
    SecItemDelete((__bridge CFDictionaryRef)(item));
    SecKeychainAddGenericPassword(NULL, (UInt32)[theService lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [theService UTF8String], (UInt32)[user lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [user UTF8String], (UInt32)[pass lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [pass UTF8String], NULL);
}

- (void)beginConnectionWithUsername:(NSString *)theUsername {
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

- (void)connectNewAccountWithUsername:(NSString *)theUsername password:(NSString *)pass inKeychain:(BOOL)yeahnah {
    originalUsername = theUsername;
    self.encPassword = pass;
    if (yeahnah) {
        [self dumpPasswordToKeychain:pass username:theUsername];
    } else {
        [self clearPasswordFromKeychain:pass username:theUsername];
    }
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

#pragma mark - Notifications

- (void)connectionInitialized:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataFileUnlocked:) name:@"UnlockSuccessful" object:self];
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    connection.me.displayName = originalUsername;
    connection.me.userStatus = @"Online";
    NSString *profilePath = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"] stringByAppendingPathComponent:originalUsername];
    NSData *blob = [NSData dataWithContentsOfFile:[profilePath stringByAppendingPathComponent:@"data.txd"]];
    BOOL isDir = NO;
    if (!blob && [[NSFileManager defaultManager] fileExistsAtPath:profilePath isDirectory:&isDir] && isDir) {
        SCIdentityUnlockWindowController *unlocker = [[SCIdentityUnlockWindowController alloc] initWithWindowNibName:@"GetPassword"];
        unlocker.unlockingIdentity = originalUsername;
        [unlocker beginModalSession];
        [unlocker close];
        return;
    } else {
        NSString *dataPass = nil;
        dataPass = [self findPasswordInKeychain:originalUsername];
        if (!dataPass) {
            SCIdentityUnlockWindowController *unlocker = [[SCIdentityUnlockWindowController alloc] initWithWindowNibName:@"UnlockData"];
            unlocker.unlockingIdentity = originalUsername;
            [unlocker beginModalSession];
            [unlocker close];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NKDataSerializer *kud = [[NKDataSerializer alloc] init];
                NSDictionary *d = [kud decryptDataBlob:blob withPassword:dataPass];
                if (!d) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        SCIdentityUnlockWindowController *unlocker = [[SCIdentityUnlockWindowController alloc] initWithWindowNibName:@"UnlockData"];
                        unlocker.unlockingIdentity = originalUsername;
                        [unlocker beginModalSession];
                        [unlocker close];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.encPassword = dataPass;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"UnlockSuccessful" object:self userInfo:d];
                    });
                }
            });
        }
    }
}

- (void)dataFileUnlocked:(NSNotification *)notification {
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postFriendRequestNotificationIfNeeded:) name:DESFriendRequestArrayDidChangeNotification object:connection.friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeToFriend:) name:DESFriendArrayDidChangeNotification object:connection.friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeToContext:) name:DESChatContextArrayDidChangeNotification object:connection.friendManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyForGroupInvite:) name:DESGroupRequestArrayDidChangeNotification object:connection.friendManager];
    if (notification.userInfo) {
        connection.me.displayName = notification.userInfo[@"displayName"];
        connection.me.userStatus = notification.userInfo[@"userStatus"];
        connection.me.statusType = [notification.userInfo[@"statusType"] integerValue];
        [connection setPrivateKey:notification.userInfo[@"privateKey"] publicKey:notification.userInfo[@"publicKey"]];
        for (NSDictionary *i in notification.userInfo[@"friends"]) {
            [connection.friendManager addFriendWithoutRequest:i[@"publicKey"]];
        }
    } else {
        [self saveData];
    }
    [connection.me addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    [connection.me addObserver:self forKeyPath:@"userStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [connection.me addObserver:self forKeyPath:@"statusType" options:NSKeyValueObservingOptionNew context:NULL];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        [[NSProcessInfo processInfo] disableAutomaticTermination:@"The connection is connected."];
    if (self.loginWindow)
        [self.loginWindow.window close];
    [self showMainWindow];
    self.networkMenu.enabled = YES;
    for (NSMenuItem *item in self.networkMenu.submenu.itemArray) {
        item.enabled = YES;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UnlockSuccessful" object:self];
}

- (void)subscribeToFriend:(NSNotification *)notification {
    DESFriend *f = notification.userInfo[DESArrayObjectKey];
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        [f addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    } else {
        [f removeObserver:self forKeyPath:@"status"];
    }
    [self saveData];
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

- (NSInteger)unreadCountForChatContext:(id<DESChatContext>)ctx {
    id a = objc_getAssociatedObject(ctx, SCUnreadCountStoreKey);
    if (!a)
        return 0;
    else
        return [a integerValue];
}

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
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        if (!OS_VERSION_IS_BETTER_THAN_LION) {
            NSSound *eventSound = [[SCSoundManager sharedManager] soundForEventType:SCEventTypeNewFriendRequest];
            [eventSound play];
            [NSApp requestUserAttention:NSInformationalRequest];
        } else {
            NSUserNotification *unotification = [[NSUserNotification alloc] init];
            unotification.title = NSLocalizedString(@"New Friend Request", @"");
            unotification.subtitle = [NSString stringWithFormat:NSLocalizedString(@"From: %@", @""), ((DESFriend*)notification.userInfo[DESArrayObjectKey]).publicKey];
            unotification.informativeText = ((DESFriend*)notification.userInfo[DESArrayObjectKey]).requestInfo;
            [[SCNotificationManager sharedManager] postNotification:unotification ofType:SCEventTypeNewFriendRequest];
            [NSApp requestUserAttention:NSInformationalRequest];
        }
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
    if (OS_VERSION_IS_BETTER_THAN_LION) {
        NSUserNotification *nc = [[NSUserNotification alloc] init];
        nc.title = ((id<DESChatContext>)notification.object).name;
        nc.subtitle = (![((id<DESChatContext>)notification.object).name isEqualToString:msg.sender.displayName]) ? msg.sender.displayName : nil;
        /* Display the sender's name if it's not also the context's name.
         * This is true for group chats, etc. */
        if (msg.type == DESMessageTypeChat)
            nc.informativeText = msg.content;
        else
            nc.informativeText = [NSString stringWithFormat:@"\u2022 %@ %@", msg.sender.displayName, msg.content];
        nc.userInfo = @{@"chatContext": ((id<DESChatContext>)notification.object).uuid};
        nc.icon = [NSImage imageNamed:@"user-icon-default"];
        [[SCNotificationManager sharedManager] postNotification:nc ofType:SCEventTypeNewChatMessage];
    } else {
        NSSound *eventSound = [[SCSoundManager sharedManager] soundForEventType:SCEventTypeNewChatMessage];
        [eventSound play];
    }
}

- (void)notifyForGroupInvite:(NSNotification *)notification {
    if (notification.userInfo[DESArrayOperationKey] == DESArrayOperationTypeAdd) {
        DESGroupChat *o = notification.userInfo[DESArrayObjectKey];
        if (OS_VERSION_IS_BETTER_THAN_LION) {
            NSUserNotification *nc = [[NSUserNotification alloc] init];
            nc.title = NSLocalizedString(@"Invited to Group Chat", @"");
            nc.informativeText = [NSString stringWithFormat:NSLocalizedString(@"You were invited to a group chat by %@.", @""), o.inviter.displayName];
            [[SCNotificationManager sharedManager] postNotification:nc ofType:SCEventTypeNewGroupInvite];
        } else {
            NSSound *eventSound = [[SCSoundManager sharedManager] soundForEventType:SCEventTypeNewGroupInvite];
            [eventSound play];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [DESToxNetworkConnection sharedConnection].me) {
        [self saveData];
    } else {
        if ([keyPath isEqualToString:@"status"]) {
            if (!OS_VERSION_IS_BETTER_THAN_LION) {
                NSSound *eventSound;
                if ([change[NSKeyValueChangeNewKey] integerValue] == DESFriendStatusOnline)
                    eventSound = [[SCSoundManager sharedManager] soundForEventType:SCEventTypeFriendConnected];
                else
                    eventSound = [[SCSoundManager sharedManager] soundForEventType:SCEventTypeFriendDisconnected];
                [eventSound play];
            } else {
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
