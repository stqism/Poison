#import <Foundation/Foundation.h>
#import <DeepEnd/DeepEnd.h>

@interface SCWebKitContext : NSObject

@property (nonatomic) id<DESChatContext> wrappedContext;
- (instancetype)initWithContext:(id<DESChatContext>)context;
- (NSString *)URLToUserProfileImage:(NSString *)clientID;
- (NSArray *)participants;
- (NSString *)nameForPublicKey:(NSString *)clientID;
- (NSArray *)chatHistory;
- (NSNumber *)systemControlColor;

@end
