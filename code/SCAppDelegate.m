#import "SCAppDelegate.h"
#import "SCAboutWindowController.h"
#import "SCPreferencesWindowController.h"
#import "SCLoginWindowController.h"
#import "SCMainWindowController.h"
#import "SCKudTestingWindowController.h"
#import "SCChatViewController.h"
#import "SCThemeManager.h"
#import "SCStandaloneWindowController.h"

#import <DeepEnd/DeepEnd.h>
#import <Kudryavka/Kudryavka.h>

@interface SCAppDelegate ()

@property (strong) IBOutlet NSMenuItem *networkMenu;

@end

@implementation SCAppDelegate {
    NKSerializerType saveMode;
    NSString *currentNickname;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if (![NKDataSerializer isDebugBuild])
        [self.kudoTestingMenuItem.menu removeItem:self.kudoTestingMenuItem]; /* Remove the Kudryavka testing option if it was not compiled for debugging. */
    NSLog(@"%@", [[SCThemeManager sharedManager] availableThemes]);
    _standaloneWindows = [[NSMutableArray alloc] initWithCapacity:5];
    self.loginWindow = [[SCLoginWindowController alloc] initWithWindowNibName:@"LoginWindow"];
    [self.loginWindow showWindow:self];
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
    currentNickname = theUsername;
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionInitialized:) name:DESConnectionDidInitNotification object:connection];
    [connection connect];
    [connection.me addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    connection.me.displayName = theUsername;
    connection.me.userStatus = @"Online";
}

- (void)saveKeys {
    NKDataSerializer *kud = [NKDataSerializer serializerUsingMethod:saveMode];
    NSError *error = nil;
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    NSDictionary *options = @{@"username": currentNickname, @"overwrite": @YES};
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

#pragma mark - Notifications

- (void)connectionInitialized:(NSNotification *)notification {
    [self saveKeys];
    if (self.loginWindow)
        [self.loginWindow.window close];
    [self showMainWindow];
    self.networkMenu.enabled = YES;
    for (NSMenuItem *item in self.networkMenu.submenu.itemArray) {
        item.enabled = YES;
    }
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
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(_mainWindow.window.frame.origin.x + 22, _mainWindow.window.frame.origin.y - 22, 400, 300) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = YES;
    SCStandaloneWindowController *wctl = [[SCStandaloneWindowController alloc] initWithWindow:window];
    SCChatViewController *ctl = [[SCChatViewController alloc] initWithNibName:@"ChatView" bundle:[NSBundle mainBundle]];
    ctl.context = aContext;
    wctl.chatController = ctl;
    [(NSMutableArray*)_standaloneWindows addObject:wctl];
    [window makeKeyAndOrderFront:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    currentNickname = change[NSKeyValueChangeNewKey];
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

- (IBAction)showKudoTests:(id)sender {
    if (!self.kTestingWindow)
        self.kTestingWindow = [[SCKudTestingWindowController alloc] initWithWindowNibName:@"KudoTesting"];
    [self.kTestingWindow showWindow:self];
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

@end
