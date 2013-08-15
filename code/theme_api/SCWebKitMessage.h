#import <Foundation/Foundation.h>
#import <DeepEnd/DeepEnd.h>
#import "SCWebKitFriend.h"
@interface SCWebKitMessage : NSObject

@property (strong) SCWebKitFriend *sender;
@property (readonly) NSInteger type;
@property (readonly) NSString *content;
@property (readonly) NSInteger statusType;
@property (readonly) NSInteger friendStatus;
@property (readonly) NSString *dateString;
@property (readonly) NSInteger messageID;
@property DESMessage *wrappedMessage;

- (instancetype)initWithMessage:(DESMessage *)message;

@end
