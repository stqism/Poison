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
        NSAlert *warning = [NSAlert alertWithMessageText:NSLocalizedString(@"Code Signature Invalid", nil)
                                           defaultButton:NSLocalizedString(@"Quit", nil)
                                         alternateButton:SCLocalizedFormatString(@"Download %@", nil, SCApplicationInfoDictKey(@"CFBundleName"))
                                             otherButton:NSLocalizedString(@"Ignore", nil)
                               informativeTextWithFormat:@""];
        warning.informativeText = SCLocalizedFormatString(@"This copy of %1$@ DID NOT pass code signature verification!\n"
                                                          @"It probably has a botnet in it. Please download %1$@ again from %2$@.", @"",
                                                          SCApplicationInfoDictKey(@"CFBundleName"),
                                                          SCApplicationDownloadPage);
        warning.alertStyle = NSCriticalAlertStyle;
        NSInteger ret = [warning runModal];
        if (ret == NSAlertDefaultReturn) {
            [NSApp terminate:self];
        } else if (ret == NSAlertAlternateReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SCApplicationDownloadPage]];
            [NSApp terminate:self];
        }
    }

    NSString *autologinUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"autologinUsername"];
    SCNewUserWindowController *login = [[SCNewUserWindowController alloc] initWithWindowNibName:@"NewUser"];
    self.mainWindowController = login;
    if ([SCProfileManager profileNameExists:autologinUsername]) {
        [login tryAutomaticLogin:autologinUsername];
    } else {
        [login showWindow:self];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([self.mainWindowController conformsToProtocol:@protocol(SCMainWindowing)]) {
        return YES;
    } else {
        return NO;
    }
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
    [self.toxConnection addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [self.toxConnection addObserver:self forKeyPath:@"statusMessage" options:NSKeyValueObservingOptionNew context:NULL];
    if (userProfile) {
        [self.toxConnection restoreDataFromTXDIntermediate:userProfile];
    } else {
        self.toxConnection.name = profileName;
        self.toxConnection.statusMessage = SCLocalizedFormatString(@"Toxing on %@ %@", @"default status message",
                                                                   SCApplicationInfoDictKey(@"CFDevelopmentName"),
                                                                   SCApplicationInfoDictKey(@"CFBundleShortVersionString"));
        [self saveProfile];
    }
    [self.toxConnection start];
    if ([self.mainWindowController isKindOfClass:[SCNewUserWindowController class]])
        [self.mainWindowController close];
    Class preferredWindowClass = SCBoolPreference(@"forcedMultiWindowUI")?
        [SCBuddyListWindowController class] : [SCUnifiedWindowController class];
    self.mainWindowController = [[preferredWindowClass alloc] initWithDESConnection:self.toxConnection];
    [self.mainWindowController showWindow:self];
    if (self.waitingToxURL && [self.mainWindowController conformsToProtocol:@protocol(SCMainWindowing)])
        [(id<SCMainWindowing>)self.mainWindowController displayAddFriendWithToxSchemeURL:self.waitingToxURL];
}

#pragma mark - Opening stuff

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    BOOL isDir = NO, exists = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir];
    if (!exists || !isDir)
        return NO;
    NSString *objectType = NSLocalizedString(@"Theme", nil);
    SCResourceBundle *object = [[SCResourceBundle alloc] initWithBundleName:[filename substringToIndex:[filename length] - [[filename pathExtension] length]] ofType:SCResourceTheme];
    NSAlert *alert = [NSAlert alertWithMessageText:SCLocalizedFormatString(@"%@ installed", @"%@: object type, theme or sound set", objectType)
                                     defaultButton:@"Delete"
                                   alternateButton:@"Keep"
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"%@ has been installed. Do you want to delete the original file?", nil), object.name];
    [alert runModal];
    return YES;
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
    } else {
        self.userInfoMenuItem.statusMessage = change[NSKeyValueChangeNewKey];
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
    self.akiUserInfoMenuItemPlaceholder.view = nil;
    [connection removeObserver:self forKeyPath:@"name"];
    [connection removeObserver:self forKeyPath:@"statusMessage"];
    self.toxConnection = nil;
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
    self.aboutWindowApplicationNameLabel.stringValue = SCApplicationInfoDictKey(@"CFDevelopmentName");
    self.aboutWindowVersionLabel.stringValue = SCApplicationInfoDictKey(@"CFBundleShortVersionString");
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
