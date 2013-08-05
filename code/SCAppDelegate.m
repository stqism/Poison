#import "SCAppDelegate.h"
#import "SCPreferencesWindowController.h"
#import "SCLoginWindowController.h"
#import "SCMainWindowController.h"

#import <DeepEnd/DeepEnd.h>

@implementation SCAppDelegate {
    NKSerializerType saveMode;
    NSString *currentNickname;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.loginWindow = [[SCLoginWindowController alloc] initWithWindowNibName:@"LoginWindow"];
    [self.loginWindow showWindow:self];
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
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    currentNickname = change[NSKeyValueChangeNewKey];
}

#pragma mark - Menus

- (IBAction)showPreferencesWindow:(id)sender {
    if (!self.preferencesWindow)
        self.preferencesWindow = [[SCPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
    [self.preferencesWindow showWindow:self];
}

@end
