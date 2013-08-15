#import "SCWebKitFriend.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCWebKitFriend

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
    return NO;
}

- (instancetype)initWithWrappedFriend:(DESFriend *)friend {
    self = [super init];
    if (self) {
        self.wrappedFriend = friend;
    }
    return self;
}

- (NSString *)displayName {
    return self.wrappedFriend.displayName;
}

- (NSString *)userStatus {
    return self.wrappedFriend.userStatus;
}

- (NSString *)publicKey {
    return self.wrappedFriend.publicKey;
}

- (BOOL)isSelf {
    return self.wrappedFriend.friendNumber == DESFriendSelf;
}

- (int)friendNumber {
    return self.wrappedFriend.friendNumber;
}

@end
