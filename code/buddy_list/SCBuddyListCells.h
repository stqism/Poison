#include "Copyright.h"

@class SCBuddyListController;

@interface SCFriendRowView : NSTableRowView

@end

@interface SCFriendCellView : NSTableCellView
@property (strong) IBOutlet NSTextField *mainLabel;
@property (strong) IBOutlet NSTextField *auxLabel;
@property (strong) IBOutlet NSImageView *light;
@property (strong) IBOutlet NSImageView *avatarView;

@property (weak) SCBuddyListController *manager;
- (void)applyMaskIfRequired;
@end