#import "SCWebKitMessage.h"

static NSDateFormatter *sharedFormatter = nil;

@implementation SCWebKitMessage

+ (void)initialize {
    sharedFormatter = [[NSDateFormatter alloc] init];
    sharedFormatter.timeStyle = NSDateFormatterLongStyle;
    sharedFormatter.dateStyle = NSDateFormatterNoStyle;
}

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

- (NSString *)dateString {
    return [sharedFormatter stringFromDate:self.wrappedMessage.dateReceived];
}

- (NSInteger)messageID {
    return self.wrappedMessage.messageID;
}

@end
