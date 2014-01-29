#import "SCAppDelegate.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCAppDelegate {
    NSTimer *aTimer;
    NSArray *closeNodes;
    BOOL updating;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidConnect:) name:DESConnectionDidInitNotification object:nil];
    self.myPub.stringValue = @"not connected";
    self.myPriv.stringValue = @"not connected";
    self.DEVersionLabel.stringValue = [NSString stringWithFormat:@"DE version: %@ (%@)", [NSBundle bundleForClass:[DESToxNetworkConnection class]].infoDictionary[@"DESGitRef"], [NSBundle bundleForClass:[DESToxNetworkConnection class]].infoDictionary[@"CFBundleShortVersionString"]];
    DESToxNetworkConnection *c = [DESToxNetworkConnection sharedConnection];
    [c connect];
    updating = YES;
    aTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0 target:self selector:@selector(runLoopRun) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:aTimer forMode:NSRunLoopCommonModes];
    self.tableView.dataSource = self;
}

- (void)connectionDidConnect:(NSNotification *)notification {
    self.myPub.stringValue = [NSString stringWithFormat:@"My public key:\n%@", [DESSelf self].publicKey];
    self.myPriv.stringValue = [NSString stringWithFormat:@"My private key:\n%@", [DESSelf self].privateKey];
}

- (IBAction)discardKeys:(id)sender {
    DESToxNetworkConnection *c = [DESToxNetworkConnection sharedConnection];
    [c disconnect];
    [c connect];
}

- (IBAction)clearFields:(id)sender {
    self.addressField.stringValue = @"";
    self.portField.stringValue = @"";
    self.keyField.stringValue = @"";
}

- (IBAction)connectBootstrap:(id)sender {
    DESToxNetworkConnection *c = [DESToxNetworkConnection sharedConnection];
    NSHost *aHost = [NSHost hostWithName:self.addressField.stringValue];
    if (![aHost address]) {
        aHost = [NSHost hostWithAddress:self.addressField.stringValue];
    }
    if (![aHost address]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Address could not be resolved." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"I was unable to resolve the name %@.", self.addressField.stringValue];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        return;
    }
    [c bootstrapWithAddress:[aHost address] port:self.portField.integerValue publicKey:self.keyField.stringValue];
}

- (void)runLoopRun {
    if (!updating)
        return;
    DESToxNetworkConnection *c = [DESToxNetworkConnection sharedConnection];
    closeNodes = [c closeNodes];
    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [closeNodes count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableColumn == self.addressColumn) {
        return [NSString stringWithFormat:@"%@:%@", closeNodes[row][DESDHTNodeIPAddressKey], closeNodes[row][DESDHTNodePortKey]];
    } else if (tableColumn == self.idColumn) {
        return closeNodes[row][DESDHTNodePublicKey];
    } else {
        return @(time(NULL) - [closeNodes[row][DESDHTNodeTimestampKey] longValue]);
    }
}

- (void)exportDataToRealFile:(NSURL *)url {
    NSLog(@"hello %@", url);
    NSOutputStream *f = [[NSOutputStream alloc] initToFileAtPath:[url path] append:NO];
    NSString *header = [NSString stringWithFormat:@"Inspectox Log // DE version: %@ (%@)\nThis log was produced %@.\n\nClose Nodes (%lu):\n", [NSBundle bundleForClass:[DESToxNetworkConnection class]].infoDictionary[@"DESGitRef"], [NSBundle bundleForClass:[DESToxNetworkConnection class]].infoDictionary[@"CFBundleShortVersionString"], [NSDate date], (unsigned long)[closeNodes count]];
    [f open];
    [f write:(const uint8_t*)[header UTF8String] maxLength:[header length]];
    for (NSDictionary *i in closeNodes) {
        NSString *node = [NSString stringWithFormat:@"%@:%hu\t%@\n", i[DESDHTNodeIPAddressKey], [i[DESDHTNodePortKey] shortValue], i[DESDHTNodePublicKey]];
        [f write:(const uint8_t*)[node UTF8String] maxLength:[node length]];
    }
    [f close];
}

- (IBAction)exportResults:(id)sender {
    updating = NO;
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.message = @"Where should I save your results?";
    panel.title = @"Export";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self exportDataToRealFile:panel.URL];
        }
        updating = YES;
    }];
}

@end
