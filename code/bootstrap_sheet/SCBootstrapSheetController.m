#import "SCBootstrapSheetController.h"
#import <DeepEnd/DeepEnd.h>
#import <arpa/inet.h>

/* TODO: Improve this code. It was very quickly written and could use some refining (in style). */

@implementation SCBootstrapSheetController {
    NSView *blankView;
}

- (void)windowDidLoad {
    [self.window setFrame:(NSRect){{0, 0}, self.easyView.frame.size} display:NO];
    self.window.contentView = self.easyView;
    blankView = [[NSView alloc] initWithFrame:CGRectZero];
    self.autostrapStatusLabel.hidden = YES;
    self.autostrapProgress.hidden = YES;
}

- (IBAction)toggleSetupMode:(id)sender {
    if (self.window.contentView == self.easyView) {
        self.window.contentView = blankView;
        [self.window setFrame:(NSRect){self.window.frame.origin, self.advancedView.frame.size} display:YES animate:YES];
        self.window.contentView = self.advancedView;
        [self fillFields];
        self.easyView.hidden = NO;
    } else {
        self.window.contentView = blankView;
        [self.window setFrame:(NSRect){self.window.frame.origin, self.easyView.frame.size} display:YES animate:YES];
        self.window.contentView = self.easyView;
        self.advancedView.hidden = NO;
    }
}

- (IBAction)suppressionStateDidChange:(NSButton *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state == NSOnState forKey:@"bootstrapAutomatically"];
    self.suppressionCheckAdvanced.state = sender.state;
    self.suppressionCheckEasy.state = sender.state;
}

- (IBAction)endSheet:(id)sender {
    [NSApp endSheet:self.window];
}

#pragma mark - Manual bootstrap

- (void)fillFields {
    self.hostField.stringValue = @"";
    self.portField.stringValue = @"";
    self.publicKeyField.stringValue = @"";
    NSArray *objects = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class]] options:nil];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    for (NSString *rawStr in objects) {
        NSString *theStr = [rawStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![theStr isKindOfClass:[NSString class]])
            continue;
        NSArray *components = [[theStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];
        if ([components count] != 3) {
            continue;
        }
        long long port = [[formatter numberFromString:components[1]] longLongValue];
        if (port > 65535 || port < 1) {
            continue;
        }
        if (!DESPublicKeyIsValid(components[2])) {
            continue;
        }
        self.hostField.stringValue = components[0];
        self.portField.stringValue = components[1];
        self.publicKeyField.stringValue = components[2];
        break;
    }
}

- (IBAction)beginManualBootstrap:(id)sender {
    self.advBackButton.enabled = NO;
    self.advContinueButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSHost *host = [NSHost hostWithName:self.hostField.stringValue];
        NSString *addr = [host address];
        if (!addr) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to bootstrap", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The DNS name '%@' could not be resolved.", @""), self.hostField.stringValue];
                [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performAdvActionOnErrorEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)(self.hostField)];
            });
        }
        NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
        NSNumber *port_obj = [fmt numberFromString:self.portField.stringValue];
        if (!port_obj || [port_obj longLongValue] > 65535 || [port_obj longLongValue] < 1) {
            NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to bootstrap", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"A port must be a number between 1 and 65535.", @"")];
            [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performAdvActionOnErrorEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)(self.portField)];
        }
        [[DESToxNetworkConnection sharedConnection] bootstrapWithAddress:addr port:[port_obj integerValue] publicKey:self.publicKeyField.stringValue];
        sleep(4);
        if ([[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue] > GOOD_CONNECTION_THRESHOLD) {
            [self endSheet:self];
        } else {
            NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to bootstrap", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"There were not enough peers to have a healthy connection.", @"")];
            [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performAdvActionOnErrorEnd:returnCode:contextInfo:) contextInfo:nil];
        }
    });
}

- (void)performAdvActionOnErrorEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.advBackButton.enabled = YES;
    self.advContinueButton.enabled = YES;
    [(__bridge id)contextInfo becomeFirstResponder];
    [(__bridge id)contextInfo selectAll:self];
}

#pragma mark - Auto bootstrap

- (void)autostrapError {
    self.cancelButton.enabled = YES;
    self.modeSwitchButton.enabled = YES;
    self.autostrapButton.enabled = YES;
    [self.autostrapProgress stopAnimation:self];
    self.autostrapProgress.hidden = YES;
    self.autostrapStatusLabel.hidden = YES;
    NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to automatically bootstrap", @"") defaultButton:NSLocalizedString(@"Try again", @"") alternateButton:NSLocalizedString(@"Advanced", @"") otherButton:NSLocalizedString(@"Cancel", @"") informativeTextWithFormat:NSLocalizedString(@"Poison has run out of usable servers to connect to. If you know a server, click \"Advanced\" to connect manually. Sorry about that.", @"")];
    [errorAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(performActionOnErrorEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (NSString *)loadNodesFromURL:(NSURL *)aUrl {
    NSURLRequest *req = [NSURLRequest requestWithURL:aUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    NSHTTPURLResponse *resp = nil;
    NSError *err = nil;
    NSData *nodedata = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    if (err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self autostrapError];
        });
        return nil;
    }
    [self writeNodesToFile:nodedata];
    return [[NSString alloc] initWithData:nodedata encoding:NSUTF8StringEncoding];
}

- (void)writeNodesToFile:(NSData *)data {
    NSString *basedir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    basedir = [basedir stringByAppendingPathComponent:@"Poison"];
    NSString *nodefilename = [basedir stringByAppendingPathComponent:@"Nodefile"];
    NSFileManager *fileman = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileman createDirectoryAtPath:basedir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate distantPast] forKey:@"getNodesTime"];
        return;
    }
    [data writeToFile:nodefilename atomically:YES];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"getNodesTime"];
}

- (NSString *)nodesFromDisk {
    NSDate *refreshTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"getNodesTime"];
    if (!refreshTime || ![refreshTime isKindOfClass:[NSDate class]] || [refreshTime timeIntervalSinceNow] < -172800) {
        return nil;
    }
    NSString *basedir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    basedir = [basedir stringByAppendingPathComponent:@"Poison"];
    NSString *nodefilename = [basedir stringByAppendingPathComponent:@"Nodefile"];
    NSFileManager *fileman = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileman createDirectoryAtPath:basedir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
    }
    if (![fileman fileExistsAtPath:nodefilename]) {
        return nil;
    } else {
        error = nil;
        NSString *nodes = [NSString stringWithContentsOfFile:nodefilename encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%@", [error description]);
            return nil;
        }
        return nodes;
    }
}

- (NSArray *)parseNodes:(NSString *)content {
    NSArray *c = [content componentsSeparatedByString:@"\n"];
    NSMutableArray *compiled = [[NSMutableArray alloc] initWithCapacity:[c count]];
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [c enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.autostrapStatusLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Looking at server %i/%i", @""), (long)idx, c.count];
        });
        NSArray *components = [obj componentsSeparatedByString:@" "];
        if ([components count] < 4) {
            NSLog(@"Malformed object '%@', skipping.", obj);
            return;
        }
        NSHost *ip = nil;
        if (inet_addr([components[0] UTF8String]) == -1) {
            ip = [NSHost hostWithName:components[0]];
        } else {
            ip = [NSHost hostWithAddress:components[0]];
        }
        NSString *resolved = [ip address];
        if (!resolved) {
            NSLog(@"Un-resolvable object '%@', skipping.", obj);
            return;
        }
        long long port = [[nf numberFromString:components[1]] longLongValue];
        if (port > 65535 || port < 1) {
            NSLog(@"Invalid port for object '%@', skipping.", obj);
            return;
        }
        if (!DESPublicKeyIsValid(components[2])) {
            NSLog(@"Invalid key for object '%@', skipping.", obj);
            return;
        }
        NSString *comment = [[components subarrayWithRange:NSMakeRange(3, [components count] - 3)] componentsJoinedByString:@" "];
        [compiled addObject:@{@"host": resolved, @"port": [nf numberFromString:components[1]], @"key": [components[2] uppercaseString], @"comment": comment}];
    }];
    return (NSArray*)compiled;
}

- (IBAction)bootstrapAutomatically:(id)sender {
    self.autostrapProgress.hidden = NO;
    self.autostrapStatusLabel.hidden = NO;
    self.autostrapButton.enabled = NO;
    self.modeSwitchButton.enabled = NO;
    self.cancelButton.enabled = NO;
    self.autostrapStatusLabel.stringValue = NSLocalizedString(@"Fetching server list...", @"");
    self.autostrapProgress.usesThreadedAnimation = YES;
    [self.autostrapProgress startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *content = [self nodesFromDisk];
        if (!content) {
            content = [self loadNodesFromURL:[NSURL URLWithString:@"https://kirara.ca/poison/Nodefile"]];
        }
        if (!content) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self autostrapError];
            });
            return;
        }
        NSLog(@"%@", content);
        NSMutableArray *usableNodes = [[self parseNodes:content] mutableCopy];
        NSUInteger cnt = [usableNodes count];
        for (NSUInteger i = 0; i < cnt; ++i) {
            uint32_t nElements = (uint32_t)(cnt - i);
            uint32_t n = (arc4random() % nElements) + (uint32_t)i;
            [usableNodes exchangeObjectAtIndex:i withObjectAtIndex:n];
        }
        DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
        for (NSDictionary *node in usableNodes) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.autostrapStatusLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Server: %@:%hu [%@]", @""), node[@"host"], [node[@"port"] unsignedShortValue], node[@"comment"]];
            });
            [connection bootstrapWithAddress:node[@"host"] port:[node[@"port"] unsignedShortValue] publicKey:node[@"key"]];
            sleep(2);
            if ([connection.connectedNodeCount integerValue] > GOOD_CONNECTION_THRESHOLD) {
                break;
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.autostrapProgress stopAnimation:self];
            self.autostrapProgress.hidden = YES;
            self.autostrapStatusLabel.hidden = YES;
            self.autostrapButton.enabled = YES;
            self.modeSwitchButton.enabled = YES;
            self.cancelButton.enabled = YES;
        });
        if ([connection.connectedNodeCount integerValue] < 4) {
            [self autostrapError];
        } else {
            [self endSheet:self];
        }
    });
}

- (void)performActionOnErrorEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    switch (returnCode) {
        case -1: {
            double delayInSeconds = 0.4;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self endSheet:self];
            });
            return;
        } /* cancel */
        case 0: {
            if (self.window.contentView != self.advancedView)
                [self toggleSetupMode:self];
            return;
        }
        case 1: {
            return;
        }
    }
}

@end
