#import "SCSoundManager.h"
#import "SCNotificationManager.h"
#import "SCAppDelegate.h"

@interface NSUserNotification (Private)
/* Mavericks 13A524d.
 * I hope this doesn't break anything. */
- (void)set_identityImage:(id)arg1;
- (void)set_identityImageHasBorder:(BOOL)arg1;
@end

@implementation NSUserNotification (SetIcon)

- (void)setIcon:(NSImage *)icon {
    if ([self respondsToSelector:@selector(set_identityImage:)]) {
        [self set_identityImage:icon];
    }
}

- (void)setIconHasBorder:(BOOL)iconHasBorder {
    if ([self respondsToSelector:@selector(set_identityImageHasBorder:)]) {
        [self set_identityImageHasBorder:iconHasBorder];
    }
}

@end

static SCNotificationManager *sharedInstance = nil;

@implementation SCNotificationManager

+ (SCNotificationManager *)sharedManager {
    if (!sharedInstance) {
        sharedInstance = [[SCNotificationManager alloc] init];
    }
    return sharedInstance;
}

+ (NSDictionary *)defaultOptionSetForEventType:(SCEventType)type {
    switch (type) {
        case SCEventTypeConnected:
            return @{@"sound": @(YES), @"toast": @(NO)};
        case SCEventTypeDisconnected:
            return @{@"sound": @(NO), @"toast": @(NO)};
        case SCEventTypeError:
            return @{@"sound": @(YES), @"toast": @(NO)};
        default:
            return @{@"sound": @(YES), @"toast": @(YES)};
    }
}

- (void)postNotification:(NSUserNotification *)notification ofType:(SCEventType)type {
    if (notification.userInfo[@"chatContext"]) {
        id<DESChatContext> ctx = [[DESToxNetworkConnection sharedConnection].friendManager chatContextWithUUID:notification.userInfo[@"chatContext"]];
        if (ctx && [(SCAppDelegate*)[NSApp delegate] currentChatContext] == ctx)
            return; /* Do not post if the chat context is in focus. */
    }
    notification.deliveryDate = [NSDate date];
    NSMutableDictionary *d = [notification.userInfo mutableCopy];
    if (!d)
        d = [NSMutableDictionary dictionary];
    d[@"eventType"] = @((long)type); /* Tag with event type. */
    notification.userInfo = d;
    NSString *optString = [NSString stringWithFormat:@"%lu", (long)type];
    NSDictionary *notifyOptionDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"notificationOptions"];
    BOOL shouldToast = YES;
    BOOL shouldPlaySound = YES;
    NSDictionary *eventSettings = nil;
    if (!notifyOptionDict[optString]) {
        eventSettings = [SCNotificationManager defaultOptionSetForEventType:type];
    } else {
        eventSettings = notifyOptionDict[optString];
    }
    if (eventSettings[@"toast"]) {
        shouldToast = [eventSettings[@"toast"] boolValue];
    }
    if (eventSettings[@"sound"]) {
        shouldPlaySound = [eventSettings[@"sound"] boolValue];
    }
    if (shouldToast) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    } else if (shouldPlaySound) {
        /* If notifications are disabled but sounds aren't, play the 
         * sound here because - [userNotificationCenter:didDeliverNotification:]
         * will never get reached. */
        NSSound *toPlay = [[SCSoundManager sharedManager] soundForEventType:type];
        if (toPlay) {
            [toPlay play];
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    if (notification.userInfo[@"chatContext"]) {
        id<DESChatContext> ctx = [[DESToxNetworkConnection sharedConnection].friendManager chatContextWithUUID:notification.userInfo[@"chatContext"]];
        if (ctx) {
            [(SCAppDelegate*)[NSApp delegate] giveFocusToChatContext:ctx];
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
    NSString *optString = [NSString stringWithFormat:@"%lu", [notification.userInfo[@"eventType"] longValue]];
    NSDictionary *notifyOptionDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"notificationOptions"];
    BOOL shouldPlaySound = YES;
    NSDictionary *eventSettings = nil;
    if (!notifyOptionDict[optString]) {
        eventSettings = [SCNotificationManager defaultOptionSetForEventType:[notification.userInfo[@"eventType"] longValue]];
    } else {
        eventSettings = notifyOptionDict[optString];
    }
    if (eventSettings[@"sound"]) {
        shouldPlaySound = [eventSettings[@"sound"] boolValue];
    }
    if (shouldPlaySound) {
        NSSound *toPlay = [[SCSoundManager sharedManager] soundForEventType:[notification.userInfo[@"eventType"] integerValue]];
        if (toPlay) {
            [toPlay play];
        }
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES; /* always */
}

@end
