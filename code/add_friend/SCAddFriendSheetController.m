#import "SCAddFriendSheetController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCAddFriendSheetController

- (void)fillFields {
    self.keyField.stringValue = @"";
    self.sendButton.enabled = NO;
    /* If there is a key on the pasteboard, put it into
     * the key field automatically. */
    NSArray *objects = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class]] options:nil];
    for (NSString *rawStr in objects) {
        NSString *theStr = [rawStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![theStr isKindOfClass:[NSString class]])
            continue;
        if ([theStr isEqualToString:[DESToxNetworkConnection sharedConnection].me.friendAddress])
            continue;
        if (DESFriendAddressIsValid(theStr)) {
            self.keyField.stringValue = theStr;
            self.sendButton.enabled = YES;
            break;
        }
    }
    self.messageField.stringValue = @"";
    [self controlTextDidChange:nil];
}

- (IBAction)messageStateDidChange:(NSButton *)sender {
    self.messageField.enabled = (sender.state == NSOnState) ? YES : NO;
}

- (IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)submitAction:(id)sender {
    if (!DESFriendAddressIsValid(self.keyField.stringValue))
        return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[DESToxNetworkConnection sharedConnection].friendManager addFriendWithAddress:self.keyField.stringValue message:self.sendsMessageCheck.state == NSOnState ? self.messageField.stringValue : @""];
        [NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:self.window waitUntilDone:NO];
    });
}

- (void)controlTextDidChange:(NSNotification *)notification {
    if (DESFriendAddressIsValid(self.keyField.stringValue)) {
        self.sendButton.enabled = YES;
        self.keyField.textColor = [NSColor blackColor];
    } else {
        self.sendButton.enabled = NO;
        self.keyField.textColor = [NSColor colorWithCalibratedRed:0.6 green:0 blue:0 alpha:1.0];
    }
}

@end
