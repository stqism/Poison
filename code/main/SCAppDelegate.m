#include "Copyright.h"

#import "DESToxConnection.h"
#import "SCAppDelegate.h"
#import "SCBuddyListWindowController.h"
#import "SCUnifiedWindowController.h"
#import "SCNewUserWindowController.h"
#import "SCGradientView.h"
#import "SCShadowedView.h"
#import "SCProfileManager.h"
#import "SCWidgetedWindow.h"
#import "SCResourceBundle.h"
#import "SCMenuStatusView.h"

/* note: this is hard-coded to make tampering harder. */
#define SCApplicationDownloadPage (@"http://download.tox.im/")

@interface SCAppDelegate ()
@property (strong) DESToxConnection *toxConnection;
@property (strong) NSString *profileName;
@property (strong) NSString *profilePass;
@property (weak) IBOutlet NSMenuItem *akiUserInfoMenuItemPlaceholder;
@property (weak) IBOutlet SCMenuStatusView *userInfoMenuItem;
#pragma mark - Tox menu
@property (weak) IBOutlet NSMenuItem *changeNameMenuItem;
@property (weak) IBOutlet NSMenuItem *changeStatusMenuItem;
@property (weak) IBOutlet NSMenuItem *savePublicAddressMenuItem;
@property (weak) IBOutlet NSMenuItem *genQRCodeMenuItem;
@property (weak) IBOutlet NSMenuItem *addFriendMenuItem;
@property (weak) IBOutlet NSMenuItem *logOutMenuItem;
#pragma mark - Dock menu
@property (weak) IBOutlet NSMenu *dockMenu;
@property (strong) NSMenuItem *dockNameMenuItem;
@property (strong) NSMenuItem *dockStatusMenuItem;
#pragma mark - AboutWindow
@property (weak) IBOutlet SCGradientView *aboutHeader;
@property (weak) IBOutlet SCShadowedView *aboutFooter;
@property (unsafe_unretained) IBOutlet NSWindow *aboutWindow;
@property (weak) IBOutlet NSTextField *aboutWindowApplicationNameLabel;
@property (weak) IBOutlet NSTextField *aboutWindowVersionLabel;
@property (unsafe_unretained) IBOutlet NSWindow *ackWindow;
@property (unsafe_unretained) IBOutlet NSTextView *ackTextView;
#pragma mark - Misc. state
@property BOOL userIsWaitingOnApplicationExit;
@property (strong) NSURL *waitingToxURL;
@end

@implementation SCAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSAppleEventManager *ae = [NSAppleEventManager sharedAppleEventManager];
    [ae setEventHandler:self
            andSelector:@selector(handleURLEvent:withReplyEvent:)
          forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"DefaultDefaults" withExtension:@"plist"]];
    NSLog(@"Default settings loaded: %@", defaults);
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    if (SCCodeSigningStatus == SCCodeSigningStatusInvalid) {
        NSAlert *warning = [[NSAlert alloc] init];
        warning.messageText = NSLocalizedString(@"Code Signature Invalid", nil);
        [warning addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
        NSString *downloadText = [NSString stringWithFormat:NSLocalizedString(@"Download %@", nil),
                                  SCApplicationInfoDictKey(@"CFBundleName")];
        [warning addButtonWithTitle:NSLocalizedString(@"Ignore", nil)];
        [warning addButtonWithTitle:downloadText];
        NSString *infoText = NSLocalizedString(@"This copy of %1$@ DID NOT pass code signature verification!\n"
                                               @"It probably has a botnet in it. Please download %1$@ again from %2$@.", nil);
        warning.informativeText = [NSString stringWithFormat:infoText,
                                   SCApplicationInfoDictKey(@"CFBundleName"), SCApplicationDownloadPage];
        warning.alertStyle = NSCriticalAlertStyle;
        NSInteger ret = [warning runModal];
        if (ret == NSAlertFirstButtonReturn) {
            [NSApp terminate:self];
        } else if (ret == NSAlertThirdButtonReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SCApplicationDownloadPage]];
            [NSApp terminate:self];
        }
    }

    NSString *autologinUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"autologinUsername"];
    SCNewUserWindowController *login = [[SCNewUserWindowController alloc] initWithWindowNibName:@"NewUser"];
    [login loadWindow];
    self.mainWindowController = login;
    if ([SCProfileManager profileNameExists:autologinUsername]) {
        [login tryAutomaticLogin:autologinUsername];
    } else {
        [login showWindow:self];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (![self.mainWindowController conformsToProtocol:@protocol(SCMainWindowing)]) {
        if (menuItem.action == @selector(copyPublicID:)
            || menuItem.action == @selector(showQRCode:)
            || menuItem.action == @selector(logOutFromUI:))
            return NO;
    }
    return YES;
}

- (void)setMainWindowController:(NSWindowController *)mainWindowController {
    _mainWindowController = mainWindowController;
}

- (void)makeApplicationReadyForToxing:(txd_intermediate_t)userProfile name:(NSString *)profileName password:(NSString *)pass {
    self.profileName = profileName;
    self.profilePass = pass;
    self.toxConnection = [[DESToxConnection alloc] init];
    self.toxConnection.delegate = self;
    self.akiUserInfoMenuItemPlaceholder.view = self.userInfoMenuItem;

    [self.dockMenu removeItemAtIndex:0];
    if (!self.dockStatusMenuItem)
        self.dockStatusMenuItem = [[NSMenuItem alloc] init];
    [self.dockMenu insertItem:self.dockStatusMenuItem atIndex:0];
    if (!self.dockNameMenuItem)
        self.dockNameMenuItem = [[NSMenuItem alloc] init];
    [self.dockMenu insertItem:self.dockNameMenuItem atIndex:0];

    [self.toxConnection addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [self.toxConnection addObserver:self forKeyPath:@"statusMessage" options:NSKeyValueObservingOptionNew context:NULL];
    if (userProfile) {
        [self.toxConnection restoreDataFromTXDIntermediate:userProfile];
    } else {
        self.toxConnection.name = profileName;
        NSString *defaultStatus = [NSString stringWithFormat:NSLocalizedString(@"Toxing on %@ %@", @"default status message"),
                                   SCApplicationInfoDictKey(@"SCDevelopmentName"),
                                   SCApplicationInfoDictKey(@"CFBundleShortVersionString")];
        self.toxConnection.statusMessage = defaultStatus;
        [self saveProfile];
    }
    [self.toxConnection start];
    if ([self.mainWindowController isKindOfClass:[SCNewUserWindowController class]])
        [self.mainWindowController close];
    Class preferredWindowClass = SCBoolPreference(@"forcedMultiWindowUI")?
        [SCBuddyListWindowController class] : [SCUnifiedWindowController class];
    self.mainWindowController = [[preferredWindowClass alloc] initWithDESConnection:self.toxConnection];
    [self.mainWindowController showWindow:self];
    if (self.waitingToxURL && [self.mainWindowController conformsToProtocol:@protocol(SCMainWindowing)]) {
        [(id<SCMainWindowing>)self.mainWindowController displayAddFriendWithToxSchemeURL:self.waitingToxURL];
        self.waitingToxURL = nil;
    }
}

#pragma mark - Opening stuff

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSLog(@"whoops, not implemented");
    return NO;
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
    NSURL *url = [NSURL URLWithString:urlString relativeToURL:[NSURL URLWithString:@"tox:///"]];
    NSLog(@"%@ %@ %@", [url host] ?: [url path], [url scheme], [url query]);
    if ([self.mainWindowController conformsToProtocol:@protocol(SCMainWindowing)])
        [(id<SCMainWindowing>)self.mainWindowController displayAddFriendWithToxSchemeURL:url];
    else
        self.waitingToxURL = url; /* We'll look at this later. */
}

#pragma mark - other appdelegate stuff

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    if ([self.mainWindowController conformsToProtocol:@protocol(SCMainWindowing)])
        return NO;
    else
        return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [self.mainWindowController.window performClose:self];
    if (self.mainWindowController.window.isVisible)
        return NSTerminateCancel; /* if the main window won't close then we shouldn't pretend we can quit either */
    /* todo: close aux. windows */
    if (self.toxConnection) {
        self.userIsWaitingOnApplicationExit = YES;
        [self logOut];
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self.mainWindowController.window makeKeyAndOrderFront:self];
    return YES;
}

#pragma mark - des delegate

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"name"]) {
        self.userInfoMenuItem.name = change[NSKeyValueChangeNewKey];
        self.dockNameMenuItem.title = change[NSKeyValueChangeNewKey];
    } else {
        self.userInfoMenuItem.statusMessage = change[NSKeyValueChangeNewKey];
        self.dockStatusMenuItem.title = change[NSKeyValueChangeNewKey];
    }
}

- (void)saveProfile {
    if (!self.toxConnection)
        return;
    txd_intermediate_t data = [self.toxConnection createTXDIntermediate];
    [SCProfileManager saveProfile:data name:self.profileName password:self.profilePass];
    txd_intermediate_free(data);
}

- (void)connectionDidBecomeInactive:(DESToxConnection *)connection {
    [self saveProfile];
    [connection removeObserver:self forKeyPath:@"name"];
    [connection removeObserver:self forKeyPath:@"statusMessage"];
    
    self.akiUserInfoMenuItemPlaceholder.view = nil;

    [self.dockMenu removeItem:self.dockNameMenuItem];
    [self.dockMenu removeItem:self.dockStatusMenuItem];
    self.dockNameMenuItem = nil;
    self.dockStatusMenuItem = nil;
    NSMenuItem *placeholder = [[NSMenuItem alloc] init];
    placeholder.title = self.akiUserInfoMenuItemPlaceholder.title;
    [self.dockMenu insertItem:placeholder atIndex:0];

    self.toxConnection = nil;
    self.profileName = nil;
    self.profilePass = nil;
    if (self.userIsWaitingOnApplicationExit) {
        [NSApp replyToApplicationShouldTerminate:YES];
    } else {
        SCNewUserWindowController *login = [[SCNewUserWindowController alloc] initWithWindowNibName:@"NewUser"];
        self.mainWindowController = login;
        [login showWindow:self];
    }
}

- (void)logOut {
    [self.toxConnection stop];
}

- (IBAction)logOutFromUI:(id)sender {
    [self.mainWindowController.window performClose:self];
    self.userIsWaitingOnApplicationExit = NO;
    if (!self.mainWindowController.window.isVisible)
        [self logOut];
}

#pragma mark - Auxiliary Windows

- (IBAction)showAboutWindow:(id)sender {
    self.aboutHeader.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.aboutHeader.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.aboutHeader.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.aboutHeader.dragsWindow = YES;
    self.aboutFooter.backgroundColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.aboutFooter.shadowColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
    self.aboutWindowApplicationNameLabel.stringValue = SCApplicationInfoDictKey(@"SCDevelopmentName");
    self.aboutWindowVersionLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@", nil),
                                                SCApplicationInfoDictKey(@"CFBundleShortVersionString")];
    [self.aboutWindow makeKeyAndOrderFront:self];
}

- (IBAction)showPreferencesWindow:(id)sender {
    
}

#pragma mark - AboutWindow click-throughs

- (IBAction)aboutWindowDidOpenGitHubURL:(id)sender {
    NSURL *github = [NSURL URLWithString:[NSBundle mainBundle].infoDictionary[@"ProjectHomepage"]];
    [[NSWorkspace sharedWorkspace] openURL:github];
}

- (IBAction)aboutWindowDidOpenToxURL:(id)sender {
    NSURL *tox_im = [NSURL URLWithString:[NSBundle mainBundle].infoDictionary[@"ToxHomepage"]];
    [[NSWorkspace sharedWorkspace] openURL:tox_im];
}

- (IBAction)aboutWindowDidOpenAcknowledgements:(id)sender {
    [self.ackTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"friends" ofType:@"rtf"]];
    [self.ackWindow makeKeyAndOrderFront:self];
}

#pragma mark - Tox menu

- (IBAction)copyPublicID:(id)sender {
    if (!self.toxConnection) {
        NSBeep();
    } else {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard clearContents];
        [pboard writeObjects:@[self.toxConnection.friendAddress]];
    }
}

- (IBAction)showQRCode:(id)sender {
    if ([self.mainWindowController respondsToSelector:@selector(displayQRCode)]) {
        [(id<SCMainWindowing>)self.mainWindowController displayQRCode];
    } else {
        NSBeep();
    }
}

@end
