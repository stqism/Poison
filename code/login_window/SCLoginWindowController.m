#import "SCGradientView.h"
#import "SCShadowedView.h"
#import "SCLoginWindowController.h"
#import "SCAppDelegate.h"
#import <Kudryavka/Kudryavka.h>

@implementation SCLoginWindowController {
    NKSerializerType saveMethod;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    saveMethod = -1;
    /* Configure the background */
    self.backgroundView.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.backgroundView.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.backgroundView.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.backgroundView.dragsWindow = YES;
    self.backgroundView.needsDisplay = YES;
    /* Configure the input panel */
    self.inputPanel.backgroundColor = [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
    self.inputPanel.shadowColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.inputPanel.needsDisplay = YES;
    self.pageTwoBackgroundView.backgroundColor = [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
    self.pageTwoBackgroundView.shadowColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.pageTwoBackgroundView.needsDisplay = YES;
    [self.window setFrame:(NSRect){{(self.window.screen.frame.size.width - (self.window.frame.size.width / 2.0)) / 2.0, self.window.frame.origin.y}, {self.window.frame.size.width / 2.0, self.window.frame.size.height}} display:YES];
    self.window.minSize = (NSSize){480, 264};
    self.window.maxSize = (NSSize){480, 264};
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"%@ %@", info[@"CFBundleName"], info[@"CFBundleShortVersionString"]];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]) {
        self.helperLabel.stringValue = NSLocalizedString(@"Welcome to Poison. Enter a nickname to get started.", @"");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
    } else {
        self.helperLabel.stringValue = NSLocalizedString(@"Welcome back. Please login with your nickname.", @"");
    }
}

- (void)transitionToPasswordPage {
    self.pageTwo.alphaValue = 0.1;
    self.pageTwo.frame = (NSRect){{170, self.pageTwo.frame.origin.y}, self.pageTwo.frame.size};
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD && 0) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.3;
            [self.pageTwo.animator setFrame:(NSRect){{0, self.pageTwo.frame.origin.y}, self.pageTwo.frame.size}];
            [self.pageTwo.animator setAlphaValue:1.0];
        } completionHandler:^{
            self.pageOne.hidden = YES;
        }];
    } else {
        [NSAnimationContext beginGrouping];
        [NSAnimationContext currentContext].duration = 0.3;
        [self.pageTwo.animator setFrame:(NSRect){{0, self.pageTwo.frame.origin.y}, self.pageTwo.frame.size}];
        [self.pageTwo.animator setAlphaValue:1.0];
        [NSAnimationContext endGrouping];
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.pageOne.hidden = YES;
        });
    }
    
}

- (void)deselectRadios {
    self.radioOptKeychain.state = NSOffState;
    self.radioOptCustomFile.state = NSOffState;
    self.radioOptNoSave.state = NSOffState;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
}

#pragma mark - Actions

- (IBAction)submitNickname:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] dictionaryForKey:@"nicknameSaveOptions"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:@"nicknameSaveOptions"];
    }
    if ([self.nicknameField.stringValue isEqualToString:@""]) {
        self.helperLabel.stringValue = NSLocalizedString(@"Your nickname cannot be blank.", @"");
        self.helperLabel.textColor = [NSColor colorWithCalibratedRed:0.8 green:0.3 blue:0.3 alpha:1.0];
    } else {
        NSDictionary *optDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"nicknameSaveOptions"];
        NSString *theUsername = [self.nicknameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (optDict[theUsername]) {
            SCAppDelegate *appDelegate = ((SCAppDelegate*)[NSApp delegate]);
            optDict = optDict[theUsername];
            [appDelegate beginConnectionWithUsername:theUsername saveMethod:[optDict[@"saveOption"] integerValue]];
            return;
        }
        [self transitionToPasswordPage];
    }
}

- (IBAction)returnPressed:(id)sender {
    [self submitNickname:sender];
}

- (IBAction)selectKeychain:(id)sender {
    [self deselectRadios];
    self.radioOptKeychain.state = NSOnState;
    saveMethod = NKSerializerKeychain;
}

- (IBAction)selectCustomFile:(id)sender {
    [self deselectRadios];
    self.radioOptCustomFile.state = NSOnState;
    saveMethod = NKSerializerCustomFile;
    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"(do not localize) Kudryavka doesn't support this yet. Your keys will be lost if you continue."];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)selectNoSave:(id)sender {
    [self deselectRadios];
    self.radioOptNoSave.state = NSOnState;
    saveMethod = NKSerializerNoop;
}

- (IBAction)continueWithKeySaveOption:(id)sender {
    if (saveMethod == -1) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Whoops!", @"") defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Please select one of the options before continuing.", @"")];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    } else {
        SCAppDelegate *appDelegate = ((SCAppDelegate*)[NSApp delegate]);
        NSString *theUsername = [self.nicknameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSMutableDictionary *optDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"nicknameSaveOptions"] mutableCopy];
        optDict[theUsername] = @{@"saveOption": @(saveMethod)};
        [[NSUserDefaults standardUserDefaults] setObject:optDict forKey:@"nicknameSaveOptions"];
        [appDelegate beginConnectionWithUsername:theUsername saveMethod:saveMethod];
    }
}

@end
