#import <Cocoa/Cocoa.h>
#import <DeepEnd/DeepEnd.h>

typedef NS_ENUM(NSInteger, SCEventType) {
    SCEventTypeConnected,
    SCEventTypeDisconnected,
    SCEventTypeFriendConnected,
    SCEventTypeFriendDisconnected,
    SCEventTypeNewChatMessage,
    SCEventTypeNewFriendRequest,
    SCEventTypeError,
};

@interface NSUserNotification (SetIcon)
- (void)setIcon:(NSImage *)icon;
- (void)setIconHasBorder:(BOOL)iconHasBorder;
@end

@interface SCNotificationManager : NSObject <NSUserNotificationCenterDelegate>

+ (SCNotificationManager *)sharedManager;
+ (NSDictionary *)defaultOptionSetForEventType:(SCEventType)type;
- (void)postNotification:(NSUserNotification *)notification ofType:(SCEventType)type;

@end
