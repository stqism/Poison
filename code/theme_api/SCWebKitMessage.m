#import "SCSafeUnicode.h"
#import "SCWebKitMessage.h"

NSString *const killString = @" \u0337\u0334\u0310";

static NSDateFormatter *cachedFormatter = nil;

@implementation SCWebKitMessage

+ (void)initialize {
    cachedFormatter = [[NSDateFormatter alloc] init];
    cachedFormatter.timeStyle = NSDateFormatterMediumStyle;
    cachedFormatter.dateStyle = NSDateFormatterMediumStyle;
    cachedFormatter.doesRelativeDateFormatting = YES;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    if (aSelector == @selector(initWithMessage:)) {
        return YES;
    }
    return NO;
}

- (instancetype)initWithMessage:(DESMessage *)message {
    self = [super init];
    if (self) {
        _wrappedMessage = message;
        _sender = [[SCWebKitFriend alloc] initWithFriend:message.sender];
    }
    return self;
}

- (void)setWrappedMessage:(DESMessage *)wrappedMessage {
    _wrappedMessage = wrappedMessage;
    _sender.wrappedFriend = wrappedMessage.sender;
}

- (NSNumber *)type {
    return @(self.wrappedMessage.type);
}

- (id)newValue {
    if (self.wrappedMessage.type == DESMessageTypeStatusChange || self.wrappedMessage.type == DESMessageTypeStatusTypeChange) {
        return @(self.wrappedMessage.newValue);
    } else if (self.wrappedMessage.type == DESMessageTypeNicknameChange || self.wrappedMessage.type == DESMessageTypeUserStatusChange) {
        return SC_SANITIZED_STRING(self.wrappedMessage.newAttribute);
    }
    return nil;
}

- (id)oldValue {
    if (self.wrappedMessage.type == DESMessageTypeStatusChange || self.wrappedMessage.type == DESMessageTypeStatusTypeChange) {
        return @(self.wrappedMessage.oldValue);
    } else if (self.wrappedMessage.type == DESMessageTypeNicknameChange || self.wrappedMessage.type == DESMessageTypeUserStatusChange) {
        return SC_SANITIZED_STRING(self.wrappedMessage.oldAttribute);
    }
    return nil;
}

- (NSString *)body {
    return SC_SANITIZED_STRING(self.wrappedMessage.content);
}

- (NSString *)localizedTimestamp {
    return [cachedFormatter stringFromDate:self.wrappedMessage.dateReceived];
}

- (id)timestamp {
    return @([self.wrappedMessage.dateReceived timeIntervalSince1970]);
}

@end