#import "SCStandaloneWindowController.h"
#import "SCChatViewController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCStandaloneWindowController

- (void)setChatController:(SCChatViewController *)chatController {
    for (DESFriend *i in _chatController.context.participants) {
        [i removeObserver:self forKeyPath:@"displayName"];
    }
    _chatController = chatController;
    self.window.contentView = _chatController.view;
    [self setTitleUsingContext:_chatController.context];
}

- (void)setTitleUsingContext:(id<DESChatContext>)context {
    NSMutableArray *names = [[NSMutableArray alloc] initWithCapacity:[context.participants count]];
    for (DESFriend *i in [context.participants sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]]) {
        [names addObject:i.displayName];
        [i addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    }
    self.window.title = [names componentsJoinedByString:@", "];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"displayName"]) {
        [self setTitleUsingContext:_chatController.context];
    }
}

- (void)dealloc {
    for (DESFriend *i in _chatController.context.participants) {
        [i removeObserver:self forKeyPath:@"displayName"];
    }
}

@end
