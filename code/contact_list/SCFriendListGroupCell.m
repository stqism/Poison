#import "SCFriendListGroupCell.h"
#import "SCAppDelegate.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCFriendListGroupCell {
    id<DESChatContext> chatContext;
}

- (void)bindToChatContext:(NSObject<DESChatContext> *)ctx {
    [ctx addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnread:) name:@"unreadCountChanged" object:ctx];
    chatContext = ctx;
    self.displayName.stringValue = ctx.name;
    self.userStatus.stringValue = @"--";
}

- (void)changeUnreadIndicatorState:(BOOL)hidden {
    if (hidden) {
        self.unreadIndicator.hidden = YES;
    } else {
        self.unreadIndicator.hidden = NO;
    }
    [self.displayName setFrameSize:(NSSize){self.frame.size.width - 8 - (self.unreadIndicator.isHidden ? 0 : 16), self.displayName.frame.size.height}];
    [self.userStatus setFrameSize:(NSSize){self.frame.size.width - 8 - (self.unreadIndicator.isHidden ? 0 : 16), self.userStatus.frame.size.height}];
}

- (IBAction)forkNewWindow:(id)sender {
    [(SCAppDelegate*)[NSApp delegate] newWindowWithDESContext:chatContext];
}

- (IBAction)deleteFriend:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"leaveGroupChat" object:nil userInfo:@{@"chat": chatContext}];
}

- (void)prepareForReuse {
    [(NSObject*)chatContext removeObserver:self forKeyPath:@"name"];
    chatContext = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"unreadCountChanged" object:chatContext];
}

@end
