#import <Cocoa/Cocoa.h>
#import "PXListViewCell.h"

@class DESFriend;
@interface SCFriendListItemCell : PXListViewCell
@property (strong) IBOutlet NSImageView *userImage;
@property (strong) IBOutlet NSTextField *displayName;
@property (strong) IBOutlet NSTextField *userStatus;
@property (strong) IBOutlet NSImageView *statusLight;

- (void)bindToFriend:(DESFriend *)aFriend;

@end
