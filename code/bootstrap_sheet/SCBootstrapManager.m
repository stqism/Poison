#import "SCBootstrapManager.h"
#import <DeepEnd/DeepEnd.h>
#import <arpa/inet.h>

@implementation SCBootstrapManager

- (NSString *)loadNodesFromURL:(NSURL *)aUrl {
    NSURLRequest *req = [NSURLRequest requestWithURL:aUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    NSHTTPURLResponse *resp = nil;
    NSError *err = nil;
    NSData *nodedata = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    if (err) {
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
        [self updateStatusOnMainThread:[NSString stringWithFormat:NSLocalizedString(@"Looking at server %i/%i", @""), (long)idx, c.count]];
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

- (void)updateStatusOnMainThread:(NSString *)theStatus {
    NSNotification *n = [NSNotification notificationWithName:@"AutostrapStatusUpdate" object:self userInfo:@{@"string": theStatus}];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:YES];
}

- (void)performAutomaticBootstrapWithSuccessCallback:(void (^)(void))successBlock failureBlock:(void (^)(void))failBlock {
    NSString *content = [self nodesFromDisk];
    if (!content) {
        content = [self loadNodesFromURL:[NSURL URLWithString:@"https://kirara.ca/poison/Nodefile"]];
    }
    if (!content) {
        failBlock();
        return;
    }
    NSMutableArray *usableNodes = [[self parseNodes:content] mutableCopy];
    NSUInteger cnt = [usableNodes count];
    for (NSUInteger i = 0; i < cnt; ++i) {
        uint32_t nElements = (uint32_t)(cnt - i);
        uint32_t n = (arc4random() % nElements) + (uint32_t)i;
        [usableNodes exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    DESToxNetworkConnection *connection = [DESToxNetworkConnection sharedConnection];
    for (NSDictionary *node in usableNodes) {
        NSLog(@"Hit server %@ %hu %@", node[@"host"], [node[@"port"] unsignedShortValue], node[@"comment"]);
        [self updateStatusOnMainThread:[NSString stringWithFormat:NSLocalizedString(@"Server: %@:%hu [%@]", @""), node[@"host"], [node[@"port"] unsignedShortValue], node[@"comment"]]];
        [connection bootstrapWithAddress:node[@"host"] port:[node[@"port"] unsignedShortValue] publicKey:node[@"key"]];
        sleep(2);
        if ([connection.connectedNodeCount integerValue] >= GOOD_CONNECTION_THRESHOLD) {
            break;
        }
    }
    if ([connection.connectedNodeCount integerValue] < 4) {
        failBlock();
    } else {
        successBlock();
    }
}

@end
