#import <Foundation/Foundation.h>
#import <DeepEnd/DeepEnd.h>

@class DESFriend;
@interface SCWebKitFriend : NSObject

@property DESFriend *wrappedFriend;
@property (readonly) NSString *displayName;
@property (readonly) NSString *userStatus;
@property (readonly) DESStatusType statusType;
@property (readonly) NSString *publicKey;
@property (readonly) DESFriendStatus status;

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector;
+ (BOOL)isKeyExcludedFromWebScript:(const char *)name;
- (instancetype)initWithWrappedFriend:(DESFriend *)friend;
- (BOOL)isSelf;

@end
