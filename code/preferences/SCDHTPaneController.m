#import "SCDHTPaneController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCDHTPaneController

- (void)awakeFromNib {
    BOOL isAutoconnectEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUseSavedBSSettings"];
    if (!isAutoconnectEnabled) {
        self.autoconnectCheck.state = NSOffState;
        [self.radioMatrix.cells enumerateObjectsUsingBlock:^(NSButtonCell *obj, NSUInteger idx, BOOL *stop) {
            obj.enabled = NO;
        }];
    } else {
        self.autoconnectCheck.state = NSOnState;
    }
    NSString *bootstrapType = [[NSUserDefaults standardUserDefaults] stringForKey:@"bootstrapType"];
    if ([bootstrapType isEqualToString:@"auto"]) {
        [self.radioMatrix selectCellWithTag:1];
    } else {
        [self.radioMatrix selectCellWithTag:0];
    }
    [self populateNodeInformationFromPreferences];
    [self bootstrapDetailsChanged:self];
}

- (BOOL)checkValuesInDictionary:(NSDictionary *)d {
    id theHost = d[@"host"];
    id thePort = d[@"port"];
    id theKey = d[@"publicKey"];
    return ([theHost isKindOfClass:[NSString class]] && [thePort isKindOfClass:[NSNumber class]] && [theKey isKindOfClass:[NSString class]]);
}

- (void)populateNodeInformationFromPreferences {
    NSDictionary *d = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"manualBSSavedServer"];
    if (![self checkValuesInDictionary:d]) {
        NSLog(@"WARNING: value types in manualBSSavedServer are incorrect. Could handle this more gracefully, but I'm just going to destroy it.");
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"manualBSSavedServer"];
    }
    NSLog(@"%@", d);
    NSString *theHost = d[@"host"];
    self.hostField.stringValue = theHost ? theHost : @"";
    NSNumber *thePort = d[@"port"];
    self.portField.stringValue = thePort ? [NSString stringWithFormat:@"%lu", [thePort unsignedLongValue]] : @"";
    NSString *theKey = d[@"publicKey"];
    self.publicKeyField.stringValue = theKey ? theKey : @"";
}

- (IBAction)checkBoxChanged:(NSButton *)sender {
    [self.radioMatrix.cells enumerateObjectsUsingBlock:^(NSButtonCell *obj, NSUInteger idx, BOOL *stop) {
        obj.enabled = (sender.state == NSOnState);
    }];
    [[NSUserDefaults standardUserDefaults] setBool:sender.state == NSOnState forKey:@"shouldUseSavedBSSettings"];
}

- (IBAction)radioButtonChanged:(NSMatrix *)sender {
    NSLog(@"%li", sender.selectedTag);
    switch (sender.selectedTag) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setObject:@"manual" forKey:@"bootstrapType"];
            break;
        case 1:
            [[NSUserDefaults standardUserDefaults] setObject:@"auto" forKey:@"bootstrapType"];
            break;
        default:
            break;
    }
}

- (IBAction)bootstrapDetailsChanged:(id)sender {
    BOOL portOK = NO;
    BOOL keyOK = NO;
    NSInteger port = self.portField.integerValue;
    if (port < 1 || port > 65535) {
        self.portField.textColor = [NSColor colorWithCalibratedRed:0.6 green:0 blue:0 alpha:1.0];
        portOK = NO;
    } else {
        self.portField.textColor = [NSColor blackColor];
        portOK = YES;
    }
    if (!DESPublicKeyIsValid(self.publicKeyField.stringValue)) {
        self.publicKeyField.textColor = [NSColor colorWithCalibratedRed:0.6 green:0 blue:0 alpha:1.0];
        keyOK = NO;
    } else {
        self.publicKeyField.textColor = [NSColor blackColor];
        keyOK = YES;
    }
    if (portOK && keyOK) {
        [[NSUserDefaults standardUserDefaults] setObject:@{
            @"host": self.hostField.stringValue,
            @"port": @([self.portField integerValue]),
            @"publicKey": self.publicKeyField.stringValue,
        } forKey:@"manualBSSavedServer"];
    }
}

@end
