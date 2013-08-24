#import "SCWebKitContext.h"

@implementation SCWebKitContext

- (instancetype)initWithContext:(id<DESChatContext>)context {
    self = [super init];
    if (self) {
        self.wrappedContext = context;
    }
    return self;
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector {
    return [NSStringFromSelector(aSelector) stringByReplacingOccurrencesOfString:@"_" withString:@""];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    if (aSelector == @selector(initWithContext:)) {
        return YES;
    }
    return NO;
}

- (NSString *)URLToUserProfileImage:(NSString *)clientID {
    return nil;
}

- (NSArray *)participants {
    return [self.wrappedContext.participants allObjects];
}

- (NSString *)nameForPublicKey:(NSString *)clientID {
    return [((DESFriend*)[self.wrappedContext.participants anyObject]).owner friendWithPublicKey:clientID].publicKey;
}

- (NSArray *)chatHistory {
    return self.wrappedContext.backlog;
}

- (NSNumber *)systemControlColor {
    switch ([NSColor currentControlTint]) {
        case NSBlueControlTint:
            return @(1);
        case NSGraphiteControlTint:
            return @(2);
        default:
            return @(0);
    }
}

@end
