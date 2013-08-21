#import "SCWebKitFriend.h"

@implementation SCWebKitFriend

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    if (aSelector == @selector(initWithFriend:)) {
        return YES;
    }
    return NO;
}

- (instancetype)initWithFriend:(DESFriend *)friend {
    self = [super init];
    if (self) {
        _wrappedFriend = friend;
    }
    return self;
}

- (void)setWrappedFriend:(DESFriend *)wrappedFriend {
    _wrappedFriend = wrappedFriend;
}

- (int)friendNumber {
    return self.wrappedFriend.friendNumber;
}

- (NSString *)displayName {
    return self.wrappedFriend.displayName;
}

- (NSString *)userStatus {
    return self.wrappedFriend.userStatus;
}

- (NSNumber *)statusType {
    return @(self.wrappedFriend.statusType);
}

- (NSString *)publicKey {
    return self.wrappedFriend.publicKey;
}

@end