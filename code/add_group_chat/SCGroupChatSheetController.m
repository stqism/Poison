#import "SCGroupChatSheetController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCGroupChatSheetController {
    NSMutableArray *friends;
}

- (void)awakeFromNib {
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFriendsList:) name:DESFriendArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
    self.friendsList.dataSource = self;
    [self refreshFriendsList:nil];
}

- (IBAction)cancelSheet:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)createGroupChat:(id)sender {
    [[DESToxNetworkConnection sharedConnection].friendManager createGroupChatWithName:self.nameField.stringValue];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
