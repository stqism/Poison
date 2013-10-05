#import <Foundation/Foundation.h>

@interface SCIdentityManager : NSObject

+ (SCIdentityManager *)sharedManager;
- (NSString *)UUIDOfUser:(NSString *)userName;
- (NSString *)profilePathOfUser:(NSString *)userName;
- (void)createUser:(NSString *)userName;
- (NSArray *)knownUsers;
- (void)reloadUsers;
- (void)setName:(NSString *)name forUser:(NSString *)user;

@end
