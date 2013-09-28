#import "SCGroupChatSheetController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCGroupChatSheetController {
    NSMutableArray *friends;
}

- (void)awakeFromNib {
    [super windowDidLoad];
    self.friendsList.dataSource = self;
    [self refreshFriendsList:nil];
}

- (IBAction)cancelSheet:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)createGroupChat:(id)sender {
    id<DESChatContext> ctx = [[DESToxNetworkConnection sharedConnection].friendManager createGroupChatWithName:self.nameField.stringValue];
    [self.friendsList.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [ctx addParticipant:friends[idx]];
    }];
    self.friendsList.dataSource = nil;
    [self cancelSheet:self];
}

- (void)refreshFriendsList:(NSNotification *)notification {
    friends = [[NSMutableArray alloc] init];
    [[DESToxNetworkConnection sharedConnection].friendManager.friends enumerateObjectsUsingBlock:^(DESFriend *obj, NSUInteger idx, BOOL *stop) {
        if (!obj.isOnline)
            return;
        [friends addObject:obj];
    }];
    [self.friendsList reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [friends count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return ((DESFriend*)friends[row]).displayName;
}

@end
