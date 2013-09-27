#import "PXListViewCell.h"

@class DESGroupChat;
@interface SCGroupRequestCell : PXListViewCell
@property (strong) IBOutlet NSTextField *displayName;
@property (strong) IBOutlet NSTextField *userStatus;

- (void)bindToGroupChat:(DESGroupChat *)grp;

@end
