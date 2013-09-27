#import "SCStandaloneWindowController.h"
#import "SCChatViewController.h"
#import <DeepEnd/DeepEnd.h>

@interface SCChatViewController ()

- (void)setTitleUsingContext:(id<DESChatContext>)context;

@end

@implementation SCStandaloneWindowController

- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        window.minSize = (NSSize){400, 300};
    }
    return self;
}

- (void)setChatController:(SCChatViewController *)chatController {
    _chatController = chatController;
    self.window.contentView = _chatController.view;
    [_chatController setTitleUsingContext:_chatController.context];
}

@end
