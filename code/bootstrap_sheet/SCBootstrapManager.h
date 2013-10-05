#import <Foundation/Foundation.h>

@interface SCBootstrapManager : NSObject

- (void)performAutomaticBootstrapWithSuccessCallback:(void (^)(void))successBlock failureBlock:(void (^)(void))failBlock stop:(BOOL *)stop;

@end
