#import "SCAddFriendSheetController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCAddFriendSheetController

- (void)fillFields {
    self.keyField.stringValue = @"";
    /* If there is a key on the pasteboard, put it into
     * the key field automatically. */
    NSArray *objects = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class]] options:nil];
    for (NSString *rawStr in objects) {
        NSString *theStr = [rawStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![theStr isKindOfClass:[NSString class]])
            continue;
        if ([theStr isEqualToString:[DESToxNetworkConnection sharedConnection].me.publicKey] || [theStr isEqualToString:[DESToxNetworkConnection sharedConnection].me.privateKey])
            continue;
        if (DESPublicKeyIsValid(theStr)) {
            self.keyField.stringValue = theStr;
            break;
        }
    }
    self.messageField.stringValue = @"";
}

- (IBAction)messageStateDidChange:(NSButton *)sender {
    self.messageField.enabled = (sender.state == NSOnState) ? YES : NO;
}

- (IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)submitAction:(id)sender {
    [[DESToxNetworkConnection sharedConnection].friendManager addFriendWithPublicKey:self.keyField.stringValue message:self.sendsMessageCheck.state == NSOnState ? self.messageField.stringValue : @""];
    [NSApp endSheet:self.window];
}

- (void)controlTextDidChange:(NSNotification *)notification{
    if (DESPublicKeyIsValid(self.keyField.stringValue)) {
        self.sendButton.enabled = YES;
        self.keyField.textColor = [NSColor blackColor];
    } else {
        self.sendButton.enabled = NO;
        self.keyField.textColor = [NSColor colorWithCalibratedRed:0.6 green:0 blue:0 alpha:1.0];
    }
}

@end
