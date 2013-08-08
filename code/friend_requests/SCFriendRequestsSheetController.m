#import "SCFriendRequestsSheetController.h"
#import "SCGradientView.h"
#import "SCRequestCell.h"
#import "PXListView.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCFriendRequestsSheetController {
    NSDateFormatter *formatter;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.headerView.topColor = [NSColor whiteColor];
    self.headerView.bottomColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
    self.headerView.needsDisplay = YES;
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    formatter.doesRelativeDateFormatting = YES;
    self.listView.delegate = self;
    [self.listView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newFriendRequest:) name:DESFriendRequestArrayDidChangeNotification object:[DESToxNetworkConnection sharedConnection].friendManager];
}

- (IBAction)finishedSheet:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)acceptCurrentRequest:(id)sender {
    if (self.listView.selectedRow == -1)
        return;
    DESFriend *theRequest = [DESToxNetworkConnection sharedConnection].friendManager.requests[self.listView.selectedRow];
    [[DESToxNetworkConnection sharedConnection].friendManager acceptRequestFromFriend:theRequest];
}

- (IBAction)rejectCurrentRequest:(id)sender {
    if (self.listView.selectedRow == -1)
        return;
    DESFriend *theRequest = [DESToxNetworkConnection sharedConnection].friendManager.requests[self.listView.selectedRow];
    [[DESToxNetworkConnection sharedConnection].friendManager rejectRequestFromFriend:theRequest];
}

- (void)newFriendRequest:(NSNotification *)notification {
    NSUInteger row = self.listView.selectedRow;
    [self.listView reloadData];
    self.listView.selectedRow = row;
}

#pragma mark - PXListView delegate

- (NSUInteger)numberOfRowsInListView:(PXListView *)aListView {
    return [DESToxNetworkConnection sharedConnection].friendManager.requests.count;
}

- (CGFloat)listView:(PXListView *)aListView heightOfRow:(NSUInteger)row {
    return 80;
}

- (void)listViewSelectionDidChange:(NSNotification *)aNotification {
    if (self.listView.selectedRow == -1) {
        self.acceptButton.enabled = NO;
        self.rejectButton.enabled = NO;
        self.dateField.stringValue = @"--";
        self.keyField.stringValue = @"";
        self.dataField.string = @"";
    } else {
        DESFriend *theRequest = nil;
        if (self.listView.selectedRow < [DESToxNetworkConnection sharedConnection].friendManager.requests.count)
            theRequest = [DESToxNetworkConnection sharedConnection].friendManager.requests[self.listView.selectedRow];
        else
            return;
        self.acceptButton.enabled = YES;
        self.rejectButton.enabled = YES;
        self.dateField.stringValue = [formatter stringFromDate:theRequest.dateReceived];
        self.keyField.stringValue = theRequest.publicKey;
        self.dataField.string = theRequest.userStatus;
    }
    self.dataField.font = [NSFont systemFontOfSize:13];
    [self.listView cellForRowAtIndex:self.listView.selectedRow].needsDisplay = YES;
}

- (PXListViewCell *)listView:(PXListView *)aListView cellForRow:(NSUInteger)row {
    DESFriend *theRequest = [DESToxNetworkConnection sharedConnection].friendManager.requests[row];
    SCRequestCell *cell = nil;
    if (!(cell = (SCRequestCell*)[aListView dequeueCellWithReusableIdentifier:@"RequestCell"])) {
        cell = [SCRequestCell cellLoadedFromNibNamed:@"RequestsCell" bundle:[NSBundle mainBundle] reusableIdentifier:@"RequestCell"];
    }
    if (theRequest.dateReceived) {
        cell.dateReceivedLabel.stringValue = [formatter stringFromDate:theRequest.dateReceived];
    } else {
        cell.dateReceivedLabel.stringValue = @"--";
    }
    cell.keyLabel.stringValue = theRequest.publicKey;
    return cell;
}

@end
