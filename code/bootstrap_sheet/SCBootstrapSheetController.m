#import "SCBootstrapSheetController.h"
#import "SCBootstrapManager.h"
#import <DeepEnd/DeepEnd.h>
#import <arpa/inet.h>

/* TODO: Improve this code. It was very quickly written and could use some refining (in style). */

@implementation SCBootstrapSheetController {
    NSView *blankView;
}

- (void)windowDidLoad {
    [self.window setFrame:(NSRect){{0, 0}, self.easyView.frame.size} display:NO];
    self.window.contentView = self.easyView;
    blankView = [[NSView alloc] initWithFrame:CGRectZero];
    self.autostrapStatusLabel.hidden = YES;
    self.autostrapProgress.hidden = YES;
}

- (IBAction)toggleSetupMode:(id)sender {
    if (self.window.contentView == self.easyView) {
        self.window.contentView = blankView;
        [self.window setFrame:(NSRect){self.window.frame.origin, self.advancedView.frame.size} display:YES animate:YES];
        self.window.contentView = self.advancedView;
        [self fillFields];
        self.easyView.hidden = NO;
    } else {
        self.window.contentView = blankView;
        [self.window setFrame:(NSRect){self.window.frame.origin, self.easyView.frame.size} display:YES animate:YES];
        self.window.contentView = self.easyView;
        self.advancedView.hidden = NO;
    }
}

- (IBAction)suppressionStateDidChange:(NSButton *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state == NSOnState forKey:@"shouldUseSavedBSSettings"];
    self.suppressionCheckAdvanced.state = sender.state;
    self.suppressionCheckEasy.state = sender.state;
}

- (IBAction)endSheet:(id)sender {
    [NSApp endSheet:self.window];
}

#pragma mark - Manual bootstrap

- (void)fillFields {
    self.hostField.stringValue = @"";
    self.portField.stringValue = @"";
    self.publicKeyField.stringValue = @"";
    NSArray *objects = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class]] options:nil];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    for (NSString *rawStr in objects) {
        NSString *theStr = [rawStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![theStr isKindOfClass:[NSString class]])
            continue;
        NSArray *components = [[theStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];
        if ([components count] != 3) {
            continue;
        }
        long long port = [[formatter numberFromString:components[1]] longLongValue];
        if (port > 65535 || port < 1) {
            continue;
        }
        if (!DESPublicKeyIsValid(components[2])) {
            continue;
        }
        self.hostField.stringValue = components[0];
        self.portField.stringValue = components[1];
        self.publicKeyField.stringValue = components[2];
        break;
    }
}

- (IBAction)beginManualBootstrap:(id)sender {
    self.advBackButton.enabled = NO;
    self.advContinueButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSHost *host = [NSHost hostWithName:self.hostField.stringValue];
        NSString *addr = [host address];
        if (!addr) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to bootstrap", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The DNS name '%@' could not be resolved.", @""), self.hostField.stringValue];
                [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performAdvActionOnErrorEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)(self.hostField)];
            });
        }
        NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
        NSNumber *port_obj = [fmt numberFromString:self.portField.stringValue];
        if (!port_obj || [port_obj longLongValue] > 65535 || [port_obj longLongValue] < 1) {
            NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to bootstrap", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"A port must be a number between 1 and 65535.", @"")];
            [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performAdvActionOnErrorEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)(self.portField)];
        }
        [[DESToxNetworkConnection sharedConnection] bootstrapWithAddress:addr port:[port_obj integerValue] publicKey:self.publicKeyField.stringValue];
        sleep(4);
        if ([[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue] > GOOD_CONNECTION_THRESHOLD) {
            [self endSheet:self];
        } else {
            NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to bootstrap", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"There were not enough peers to have a healthy connection.", @"")];
            [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performAdvActionOnErrorEnd:returnCode:contextInfo:) contextInfo:nil];
        }
    });
}

- (void)performAdvActionOnErrorEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.advBackButton.enabled = YES;
    self.advContinueButton.enabled = YES;
    [(__bridge id)contextInfo becomeFirstResponder];
    [(__bridge id)contextInfo selectAll:self];
}

#pragma mark - Auto bootstrap

- (IBAction)bootstrapAutomatically:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"auto" forKey:@"bootstrapType"];
    self.autostrapProgress.hidden = NO;
    self.autostrapStatusLabel.hidden = NO;
    self.autostrapButton.enabled = NO;
    self.modeSwitchButton.enabled = NO;
    self.cancelButton.enabled = NO;
    self.autostrapStatusLabel.stringValue = NSLocalizedString(@"Fetching server list...", @"");
    self.autostrapProgress.usesThreadedAnimation = YES;
    [self.autostrapProgress startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        SCBootstrapManager *m = [[SCBootstrapManager alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusInfoChanged:) name:@"AutostrapStatusUpdate" object:m];
        [m performAutomaticBootstrapWithSuccessCallback:^{
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AutostrapStatusUpdate" object:m];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.autostrapProgress stopAnimation:self];
                self.autostrapProgress.hidden = YES;
                self.autostrapStatusLabel.hidden = YES;
                self.autostrapButton.enabled = YES;
                self.modeSwitchButton.enabled = YES;
                self.cancelButton.enabled = YES;
                [self endSheet:self];
            });
        } failureBlock:^{
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AutostrapStatusUpdate" object:m];
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.cancelButton.enabled = YES;
                self.modeSwitchButton.enabled = YES;
                self.autostrapButton.enabled = YES;
                [self.autostrapProgress stopAnimation:self];
                self.autostrapProgress.hidden = YES;
                self.autostrapStatusLabel.hidden = YES;
                NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to automatically bootstrap", @"") defaultButton:NSLocalizedString(@"Try again", @"") alternateButton:NSLocalizedString(@"Advanced", @"") otherButton:NSLocalizedString(@"Cancel", @"") informativeTextWithFormat:NSLocalizedString(@"Poison has run out of usable servers to connect to. If you know a server, click \"Advanced\" to connect manually. Sorry about that.", @"")];
                [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performActionOnErrorEnd:returnCode:contextInfo:) contextInfo:nil];
            });
        }];
    });
}

- (void)statusInfoChanged:(NSNotification *)notification {
    self.autostrapStatusLabel.stringValue = notification.userInfo[@"string"];
}

- (void)performActionOnErrorEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    switch (returnCode) {
        case -1: {
            double delayInSeconds = 0.4;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self endSheet:self];
            });
            return;
        } /* cancel */
        case 0: {
            if (self.window.contentView != self.advancedView)
                [self toggleSetupMode:self];
            return;
        }
        case 1: {
            return;
        }
    }
}

@end
