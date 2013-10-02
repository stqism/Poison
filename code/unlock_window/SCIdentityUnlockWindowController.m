#import "SCIdentityUnlockWindowController.h"
#import "SCAppDelegate.h"
#import "NSWindow+Shake.h"
#import <QuartzCore/QuartzCore.h>

@implementation SCIdentityUnlockWindowController

- (void)awakeFromNib {
    [super windowDidLoad];
    self.unlockButton.enabled = NO;
    self.passwordField.delegate = self;
}

- (void)beginModalSession {
    [self loadWindow];
    [NSApp runModalForWindow:self.window];
}

- (void)setUnlockingIdentity:(NSString *)unlockingIdentity {
    _unlockingIdentity = unlockingIdentity;
    [self loadWindow];
    self.userName.stringValue = unlockingIdentity;
}

- (IBAction)cancelUnlockAndExit:(id)sender {
    [NSApp stopModal];
    [NSApp terminate:self];
}

- (IBAction)performUnlock:(id)sender {
    self.unlockButton.enabled = NO;
    NSString *profilePath = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"] stringByAppendingPathComponent:self.unlockingIdentity];
    NSData *blob = [NSData dataWithContentsOfFile:[profilePath stringByAppendingPathComponent:@"data.txd"]];
    if (!blob) {
        ((SCAppDelegate*)[NSApp delegate]).encPassword = self.passwordField.stringValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UnlockSuccessful" object:[NSApp delegate]];
        [NSApp stopModal];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NKDataSerializer *kud = [[NKDataSerializer alloc] init];
            NSDictionary *d = [kud decryptDataBlob:blob withPassword:self.passwordField.stringValue];
            if (!d) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.unlockButton.enabled = YES;
                    [self.window shakeWindow:^{
                        [self.passwordField selectText:self];
                    }];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSApp stopModal];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UnlockSuccessful" object:[NSApp delegate] userInfo:d];
                });
            }
        });
    }
}

- (void)controlTextDidChange:(NSNotification *)obj {
    if ([self.passwordField.stringValue isEqualToString:@""]) {
        self.unlockButton.enabled = NO;
    } else {
        self.unlockButton.enabled = YES;
    }
}

@end
