#include "Copyright.h"

#import "ObjectiveTox.h"
#import "SCAddFriendSheetController.h"
#define SCFailedTextColour ([NSColor colorWithCalibratedRed:0.6 green:0.0 blue:0.0 alpha:1.0])

NS_INLINE int SCQuickValidateString(NSString *string) {
    const char *check = string.UTF8String;
    int i = 0;
    char a = 0;
    /* clear bit 3 - same thing as the XOR 32 trick to make
     * lowercase -> uppercase */
    for (a = *check & (~(1 << 5)); a != 0; a = check[++i] & (~(1 << 5))) {
        if ((a <= 70 && a >= 65) || (a <= 25 && a >= 16)) {
            continue; /* A-F, 0-9 */
        } else {
            // NSLog(@"fail: %d %c (%d -> %d) not valid tox char", i, check[i], check[i], a);
            return 0;
        }
    }
    return 1;
}

@interface SCAddFriendSheetController ()
@property (strong) IBOutlet NSTextField *idField;
@property (strong) IBOutlet NSTextField *messageField;
@property (strong) IBOutlet NSTextField *idValidationStatusField;
@property (strong) IBOutlet NSButton *continueButton;
@end

@implementation SCAddFriendSheetController
- (void)awakeFromNib {
    self.idField.delegate = self;
    self.idField.font = [NSFont fontWithName:@"Menlo-Regular" size:12];
    [self resetFields];
}

- (NSString *)toxID {
    return self.idField.stringValue;
}

- (void)setToxID:(NSString *)theID {
    self.idField.stringValue = [theID uppercaseString];
    [self validateFields];
}

- (NSString *)message {
    return self.messageField.stringValue;
}

- (void)setMessage:(NSString *)theMessage {
    self.messageField.stringValue = theMessage;
    [self validateFields];
}

- (void)resetFields {
    self.idField.stringValue = @"";
    self.messageField.stringValue = NSLocalizedString(@"Please Tox me on Tox.", nil);
}

- (void)validateFields {
    if (self.messageField.stringValue.length > UINT16_MAX) {
        self.messageField.textColor = SCFailedTextColour;
        [self failedValidation:NSLocalizedString(@"The message was too long.", nil)];
        return;
    }
    [self validateFieldsLite];
}

- (void)validateFieldsLite {
    if (self.idField.stringValue.length != DESFriendAddressSize * 2
        || !SCQuickValidateString(self.idField.stringValue)) {
        self.idField.textColor = SCFailedTextColour;
        [self failedValidation:NSLocalizedString(@"That doesn't look like a valid Tox ID.", nil)];
        return;
    }
    self.idField.textColor = [NSColor controlTextColor];
    self.messageField.textColor = [NSColor controlTextColor];
    [self passedValidation];
}

- (void)failedValidation:(NSString *)message {
    self.idValidationStatusField.stringValue = message;
    self.continueButton.enabled = NO;
}

- (void)passedValidation {
    self.idValidationStatusField.stringValue = NSLocalizedString(@"Looks good.", nil);
    self.continueButton.enabled = YES;
}

- (void)controlTextDidChange:(NSNotification *)obj {
    [self validateFieldsLite];
}

- (IBAction)exitSheet:(id)sender {
    [NSApp endSheet:self.window];
}
@end
