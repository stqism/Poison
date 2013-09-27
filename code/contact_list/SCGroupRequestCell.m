#import "SCGroupRequestCell.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCGroupRequestCell {
    DESGroupChat *groupInv;
}

- (void)bindToGroupChat:(DESGroupChat *)grp {
    groupInv = grp;
    self.displayName.stringValue = grp.publicKey;
    self.userStatus.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Invited by %@", @""), grp.inviter.displayName];
}

- (void)prepareForReuse {
    groupInv = nil;
}

- (IBAction)acceptGroupInvitation:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"joinGroup" object:nil userInfo:@{@"invite": groupInv}];
}

- (IBAction)dismissGroupInvitation:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rejectGroup" object:nil userInfo:@{@"invite": groupInv}];
}

@end
