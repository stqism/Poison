#import "SCConnectionInspectorSheetController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCConnectionInspectorSheetController {
    dispatch_source_t updateTimer;
    BOOL timerIsRunning;
    NSArray *DHTNodes;
    NSArray *knownClients;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.tableView.dataSource = self;
    self.otherTableView.dataSource = self;
    timerIsRunning = NO;
}

- (IBAction)toggleRefresh:(NSButton *)sender {
    if (sender.state == NSOnState) {
        [self startTimer];
    } else {
        [self stopTimer];
    }
}

- (void)startTimer {
    if (timerIsRunning)
        return;
    updateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [DESToxNetworkConnection sharedConnection].messengerQueue);
    dispatch_source_set_timer(updateTimer, dispatch_walltime(NULL, 0), 2 * NSEC_PER_SEC, 5 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(updateTimer, ^{
        DHTNodes = [DESToxNetworkConnection sharedConnection].closeNodes;
        knownClients = [DESToxNetworkConnection sharedConnection].knownClients;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.DHTCounter.stringValue = [NSString stringWithFormat:@"%lu", [DHTNodes count]];
            self.runLoopSpeed.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%.0f times/sec.", @""), 1.0 / [DESToxNetworkConnection sharedConnection].runLoopSpeed];
            self.publicKey.stringValue = [NSString stringWithFormat:@"P:%@", [DESSelf self].publicKey];
            self.privateKey.stringValue = [NSString stringWithFormat:@"S:%@", [DESSelf self].privateKey];
            [self.tableView reloadData];
            [self.otherTableView reloadData];
        });
    });
    dispatch_resume(updateTimer);
}

- (void)stopTimer {
    if (!updateTimer)
        return;
    dispatch_source_cancel(updateTimer);
    dispatch_release(updateTimer);
    updateTimer = nil;
}

- (IBAction)endSheet:(id)sender {
    [self stopTimer];
    DHTNodes = nil;
    knownClients = nil;
    [NSApp endSheet:self.window];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.tableView)
        return [DHTNodes count];
    else
        return [knownClients count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.tableView) {
        return [self closeTableObjectValueForTableColumn:tableColumn row:row];
    } else {
        return [self knownClientTableObjectValueForTableColumn:tableColumn row:row];
    }
}

- (id)closeTableObjectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *d = DHTNodes[row];
    if (tableColumn == self.nodeNumberColumn) {
        return @(row + 1);
    } else if (tableColumn == self.nodeAddressColumn) {
        NSString *plain = [NSString stringWithFormat:@"%@:%@", d[DESDHTNodeIPAddressKey], d[DESDHTNodePortKey]];
        NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:plain attributes:nil];
        NSUInteger start = [plain rangeOfString:@":"].location;
        [s setAttributes:@{NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.4 alpha:1.0]} range:NSMakeRange(start, [s length] - start)];
        NSMutableParagraphStyle *pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        [s addAttributes:@{NSParagraphStyleAttributeName: pStyle} range:NSMakeRange(0, [plain length])];
        return s;
    } else if (tableColumn == self.nodeKeyColumn) {
        return d[DESDHTNodePublicKey];
    } else if (tableColumn == self.nodeRemarksColumn) {
        return [d[DESDHTNodeTimestampKey] stringValue];
    } else {
        return @"";
    }
}

- (id)knownClientTableObjectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *d = knownClients[row];
    /* TODO: Coalesce the two methods into one. */
    if (tableColumn == self.knownSourceColumn) {
        return [d[DESDHTNodeSourceKey] stringValue];
    } else if (tableColumn == self.knownAddress) {
        NSString *plain = [NSString stringWithFormat:@"%@:%@", d[DESDHTNodeIPAddressKey], d[DESDHTNodePortKey]];
        NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:plain attributes:nil];
        NSUInteger start = [plain rangeOfString:@":"].location;
        [s setAttributes:@{NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.4 alpha:1.0]} range:NSMakeRange(start, [s length] - start)];
        NSMutableParagraphStyle *pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        [s addAttributes:@{NSParagraphStyleAttributeName: pStyle} range:NSMakeRange(0, [plain length])];
        return s;
    } else if (tableColumn == self.knownPublicKey) {
        return d[DESDHTNodePublicKey];
    } else if (tableColumn == self.knownTimestamp) {
        return [d[DESDHTNodeTimestampKey] stringValue];
    } else {
        return @"";
    }
}

- (void)dealloc {
    [self stopTimer];
}

@end
