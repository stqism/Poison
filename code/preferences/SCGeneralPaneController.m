#import "SCGeneralPaneController.h"
#import "SCNotificationManager.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCGeneralPaneController

- (void)awakeFromNib {
    NSInteger speed = [[NSUserDefaults standardUserDefaults] integerForKey:@"DESRunLoopSpeed"];
    if (!speed) {
        speed = (NSInteger)(1 / DEFAULT_MESSENGER_TICK_RATE);
        [[NSUserDefaults standardUserDefaults] setInteger:speed forKey:@"DESRunLoopSpeed"];
    }
    switch (speed) {
        case 200:
            self.radioButton200.state = NSOnState;
            break;
        case 100:
            self.radioButton100.state = NSOnState;
            break;
        case 30:
            self.radioButton20.state = NSOnState;
            break;
        case 10:
            self.radioButton10.state = NSOnState;
            break;
        default:
            break;
    }
    [self popupOptionChanged:self.popUp];
}

- (IBAction)runLoopSpeedChanged:(NSButton *)sender {
    self.radioButton10.state = NSOffState;
    self.radioButton20.state = NSOffState;
    self.radioButton100.state = NSOffState;
    self.radioButton200.state = NSOffState;
    sender.state = NSOnState;
    [[NSUserDefaults standardUserDefaults] setInteger:sender.tag forKey:@"DESRunLoopSpeed"];
    [DESToxNetworkConnection sharedConnection].runLoopSpeed = (1.0 / (double)sender.tag);
}

- (IBAction)popupOptionChanged:(NSPopUpButton *)sender {
    NSString *optString = [NSString stringWithFormat:@"%lu", (long)sender.selectedTag];
    NSMutableDictionary *noteDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"notificationOptions"] mutableCopy];
    if (!noteDict) {
        [[NSUserDefaults standardUserDefaults] setObject:@{optString: [SCNotificationManager defaultOptionSetForEventType:sender.selectedTag]} forKey:@"notificationOptions"];
        self.playsSound.state = NSOnState;
        self.sendsNotification.state = NSOnState;
    } else {
        NSDictionary *opts = noteDict[optString];
        if (opts) {
            self.playsSound.state = ([opts[@"sound"] isKindOfClass:[NSNumber class]] && [opts[@"sound"] boolValue]) ? NSOnState : NSOffState;
            self.sendsNotification.state = ([opts[@"toast"] isKindOfClass:[NSNumber class]] && [opts[@"toast"] boolValue]) ? NSOnState : NSOffState;
        } else {
            noteDict[optString] = [SCNotificationManager defaultOptionSetForEventType:sender.selectedTag];
            [[NSUserDefaults standardUserDefaults] setObject:noteDict forKey:@"notificationOptions"];
        }
    }
}

- (IBAction)changeToastPreference:(id)sender {
    NSString *optString = [NSString stringWithFormat:@"%lu", (long)self.popUp.selectedTag];
    NSMutableDictionary *noteDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"notificationOptions"] mutableCopy];
    NSMutableDictionary *opts = [noteDict[optString] mutableCopy];
    if (opts) {
        opts[@"toast"] = @(self.sendsNotification.state == NSOnState ? YES : NO);
        noteDict[optString] = opts;
        [[NSUserDefaults standardUserDefaults] setObject:noteDict forKey:@"notificationOptions"];
    }
}

- (IBAction)changeSoundPreference:(id)sender {
    NSString *optString = [NSString stringWithFormat:@"%lu", (long)self.popUp.selectedTag];
    NSMutableDictionary *noteDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"notificationOptions"] mutableCopy];
    NSMutableDictionary *opts = [noteDict[optString] mutableCopy];
    if (opts) {
        opts[@"sound"] = @(self.playsSound.state == NSOnState ? YES : NO);
        noteDict[optString] = opts;
        [[NSUserDefaults standardUserDefaults] setObject:noteDict forKey:@"notificationOptions"];
    }
}
@end
