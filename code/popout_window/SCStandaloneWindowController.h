#import <Cocoa/Cocoa.h>

@class SCChatViewController;
@interface SCStandaloneWindowController : NSWindowController

@property (strong, nonatomic) SCChatViewController *chatController;

@end
