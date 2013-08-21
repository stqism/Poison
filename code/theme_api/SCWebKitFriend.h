#import <Foundation/Foundation.h>
#import <DeepEnd/DeepEnd.h>

@interface SCWebKitFriend : NSObject

@property (readonly) int friendNumber;
@property (strong, readonly) NSString *displayName;
@property (strong, readonly) NSString *userStatus;
@property (readonly) NSNumber *statusType;
@property (strong, readonly) NSString *publicKey;
@property (nonatomic) DESFriend *wrappedFriend;

- (instancetype)initWithFriend:(DESFriend *)friend;

@end