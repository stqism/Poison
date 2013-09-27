#import "SCFriendListItemCell.h"
#import <DeepEnd/DeepEnd.h>

@interface SCFriendListGroupCell : SCFriendListItemCell

- (void)bindToChatContext:(id<DESChatContext>)ctx;

@end
