#import "SCGradientView.h"
#import "SCShadowedView.h"
#import "SCLoginWindowController.h"
#import "SCAppDelegate.h"
#import "NSWindow+Shake.h"
#import "SCBigGreenButton.h"
#import <Kudryavka/Kudryavka.h>

@implementation SCLoginWindowController {
    NSArray *names;
}

- (void)windowDidLoad {
    [super windowDidLoad];
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
    self.nicknameField.delegate = self;
    NSAttributedString *s = [[NSAttributedString alloc] initWithString:self.passwordSaveKeychainCheck.title attributes:@{NSForegroundColorAttributeName: [NSColor whiteColor], NSFontAttributeName:[NSFont systemFontOfSize:13]}];
    self.passwordSaveKeychainCheck.attributedTitle = s;
    [self.window setFrame:(NSRect){{(self.window.screen.frame.size.width - (self.window.frame.size.width / 2.0)) / 2.0, self.window.frame.origin.y}, {self.window.frame.size.width / 2.0, self.window.frame.size.height}} display:YES];
    self.window.minSize = (NSSize){480, 264};
    self.window.maxSize = (NSSize){480, 264};
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"%@ %@", info[@"CFBundleName"], info[@"CFBundleShortVersionString"]];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *profilePath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"];
    [fm createDirectoryAtPath:profilePath withIntermediateDirectories:YES attributes:nil error:nil];
    names = [[fm contentsOfDirectoryAtPath:profilePath error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        BOOL dir = NO;
        [fm fileExistsAtPath:evaluatedObject isDirectory:&dir];
        return dir == NO;
    }]];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]) {
        self.helperLabel.stringValue = NSLocalizedString(@"Welcome to Poison. Enter a nickname to get started.", @"");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
    } else {
        self.helperLabel.stringValue = NSLocalizedString(@"Welcome back. Please login with your nickname.", @"");
    }
}

- (void)controlTextDidChange:(NSNotification *)obj {
    if (obj.object == self.nicknameField) {
        if ([names indexOfObject:self.nicknameField.stringValue] != NSNotFound) {
            self.submitButton.title = NSLocalizedString(@"Log in", @"");
        } else {
            self.submitButton.title = NSLocalizedString(@"Start", @"");
        }
    }
}

- (void)transitionToPasswordPage {
    self.pageTwo.hidden = NO;
    self.pageTwo.alphaValue = 0.1;
    self.pageTwo.frame = (NSRect){{170, self.pageTwo.frame.origin.y}, self.pageTwo.frame.size};
    self.passwordFieldOne.stringValue = @"";
    self.passwordFieldTwo.stringValue = @"";
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
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

#pragma mark - Actions: Page One

- (IBAction)submitNickname:(id)sender {
    if ([self.nicknameField.stringValue isEqualToString:@""]) {
        self.helperLabel.stringValue = NSLocalizedString(@"Your nickname cannot be blank.", @"");
        self.helperLabel.textColor = [NSColor colorWithCalibratedRed:0.8 green:0.3 blue:0.3 alpha:1.0];
        [self.window shakeWindow:nil];
    } else {
        NSString *theUsername = [self.nicknameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (self.rememberCheck.state == NSOnState)
            [[NSUserDefaults standardUserDefaults] setObject:theUsername forKey:@"rememberedName"];
        else
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"rememberedName"];
        if ([names indexOfObject:theUsername] != NSNotFound)
            [(SCAppDelegate*)[NSApp delegate] beginConnectionWithUsername:theUsername];
        else
            [self transitionToPasswordPage];
    }
}

- (IBAction)returnPressed:(id)sender {
    [self submitNickname:sender];
}

- (IBAction)toggleRememberance:(NSButton *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state == NSOnState forKey:@"rememberUserName"];
}

- (IBAction)continueLogin:(id)sender {
    SCAppDelegate *appDelegate = ((SCAppDelegate*)[NSApp delegate]);
    NSString *theUsername = [self.nicknameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![theUsername isEqualToString:@""])
        [appDelegate connectNewAccountWithUsername:theUsername password:self.passwordFieldOne.stringValue inKeychain:self.passwordSaveKeychainCheck.state == NSOnState];
}

#pragma mark - Actions: Page Two

- (IBAction)backButtonPressed:(id)sender {
    self.pageOne.hidden = NO;
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.3;
            [self.pageTwo.animator setFrame:(NSRect){{170, self.pageTwo.frame.origin.y}, self.pageTwo.frame.size}];
            [self.pageTwo.animator setAlphaValue:0];
        } completionHandler:^{
            self.pageTwo.hidden = YES;
        }];
    } else {
        [NSAnimationContext beginGrouping];
        [NSAnimationContext currentContext].duration = 0.3;
        [self.pageTwo.animator setFrame:(NSRect){{170, self.pageTwo.frame.origin.y}, self.pageTwo.frame.size}];
        [self.pageTwo.animator setAlphaValue:0];
        [NSAnimationContext endGrouping];
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.pageTwo.hidden = YES;
        });
    }
}

- (IBAction)shouldContinueWithPassword:(id)sender {
    if ([self.passwordFieldOne.stringValue isEqualToString:@""]) {
        [self.window shakeWindow:^{
            [self.passwordFieldOne selectText:self];
        }];
    } else if (![self.passwordFieldOne.stringValue isEqualToString:self.passwordFieldTwo.stringValue]) {
        [self.window shakeWindow:^{
            [self.passwordFieldTwo selectText:self];
        }];
    } else {
        [self continueLogin:self];
    }
}

@end
