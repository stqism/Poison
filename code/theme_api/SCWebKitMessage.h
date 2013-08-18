#import <Foundation/Foundation.h>
#import <DeepEnd/DeepEnd.h>
#import "SCWebKitFriend.h"

@interface SCWebKitMessage : NSObject

@property (nonatomic) DESMessage *wrappedMessage;
@property (nonatomic) SCWebKitFriend *sender;

- (instancetype)initWithMessage:(DESMessage *)message;
- (NSNumber *)type;
- (id)newValue;
- (id)oldValue;
- (NSString *)body;
- (SCWebKitFriend *)sender;
- (NSString *)localizedTimestamp;
- (id)timestamp;

@end