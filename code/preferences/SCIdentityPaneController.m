#import "SCIdentityPaneController.h"
#import "SCIdentityManager.h"
#import <Kudryavka/Kudryavka.h>

@implementation SCIdentityPaneController {
    NSArray *availableIdentities;
}

- (void)awakeFromNib {
    availableIdentities = [[SCIdentityManager sharedManager] knownUsers];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.nameEditField.delegate = self;
    if ([availableIdentities count] != 0) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }
    [self buildMenu];
}

- (void)buildMenu {
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:NSLocalizedString(@"Nobody", @"") action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    for (NSString *i in availableIdentities) {
        [menu addItemWithTitle:i action:nil keyEquivalent:@""];
    }
    self.identityPopup.menu = menu;
    NSString *n = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberedName"];
    NSInteger idx = [availableIdentities indexOfObject:n];
    if (idx != NSNotFound) {
        [self.identityPopup selectItemAtIndex:idx + 2];
    } else {
        [self.identityPopup selectItemAtIndex:0];
    }
}

- (IBAction)changeAutoLoginIdentity:(id)sender {
    if (self.identityPopup.indexOfSelectedItem == 0) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"rememberedName"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"rememberUserName"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:availableIdentities[self.identityPopup.indexOfSelectedItem - 2] forKey:@"rememberedName"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"rememberUserName"];
    }
}

- (IBAction)importCoreDataFile:(id)sender {
}

- (IBAction)importNewStyleDataFile:(id)sender {
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [availableIdentities count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableColumn == self.imageColumn) {
        return [NSImage imageNamed:@"user-icon-default"];
    } else {
        return availableIdentities[row];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.nameEditField.stringValue = availableIdentities[self.tableView.selectedRow];
    NSString *pp = [[SCIdentityManager sharedManager] profilePathOfUser:availableIdentities[self.tableView.selectedRow]];
    NSData *blob = [NSData dataWithContentsOfFile:[pp stringByAppendingPathComponent:@"data.txd"]];
    if (!blob) {
        self.dataComment.string = NSLocalizedString(@"<blob missing>", @"");
        return;
    }
    NKDataSerializer *kud = [[NKDataSerializer alloc] init];
    NSString *comment = [kud fileCommentFromBlob:blob];
    if (!comment) {
        comment = NSLocalizedString(@"<data corrupt>", @"");
    }
    self.dataComment.string = comment;
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:self.tableView.selectedRow] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
    [[SCIdentityManager sharedManager] setName:self.nameEditField.stringValue forUser:availableIdentities[self.tableView.selectedRow]];
    availableIdentities = [[SCIdentityManager sharedManager] knownUsers];
}

- (IBAction)revealProfileDirectory:(id)sender {
    SCIdentityManager *m = [SCIdentityManager sharedManager];
    NSString *pp = [m profilePathOfUser:availableIdentities[self.tableView.selectedRow]];
    [[NSWorkspace sharedWorkspace] selectFile:[pp stringByAppendingPathComponent:@"data.txd"] inFileViewerRootedAtPath:pp];
}

@end
