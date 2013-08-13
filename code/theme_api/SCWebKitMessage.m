#import "SCWebKitMessage.h"

@implementation SCWebKitMessage

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
    return NO;
}

- (instancetype)initWithMessage:(DESMessage *)message {
    self = [super init];
    if (self) {
        self.wrappedMessage = message;
        self.sender = [[SCWebKitFriend alloc] initWithWrappedFriend:message.sender];
    }
    return self;
}

- (NSInteger)type {
    return self.wrappedMessage.type;
}

- (NSString *)content {
    return self.wrappedMessage.content;
}

- (NSInteger)statusType {
    return self.wrappedMessage.statusType;
}

- (NSInteger)friendStatus {
    return self.wrappedMessage.friendStatus;
}

- (NSDate *)dateReceived {
    return self.wrappedMessage.dateReceived;
}

- (NSInteger)messageID {
    return self.wrappedMessage.messageID;
}

@end
