#import "SCIdentityManager.h"

static SCIdentityManager *sharedInstance = nil;

@implementation SCIdentityManager {
    NSDictionary *userMap;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reloadUsers];
    }
    return self;
}

+ (SCIdentityManager *)sharedManager {
    if (!sharedInstance) {
        sharedInstance = [[SCIdentityManager alloc] init];
    }
    return sharedInstance;
}

- (NSString *)UUIDOfUser:(NSString *)userName {
    return userMap[userName];
}

- (NSString *)profilePathOfUser:(NSString *)userName {
    NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"];
    NSString *path = [libraryPath stringByAppendingPathComponent:userMap[userName]];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

- (void)createUser:(NSString *)userName {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *str = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"];
    BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:[libraryPath stringByAppendingPathComponent:str] withIntermediateDirectories:YES attributes:nil error:nil];
    if (ok) {
        NSMutableDictionary *mf = [userMap mutableCopy];
        mf[userName] = str;
        [mf writeToFile:[libraryPath stringByAppendingPathComponent:@"manifest.plist"] atomically:YES];
        userMap = (NSDictionary*)mf;
    }
}

- (NSArray *)knownUsers {
    return [userMap allKeys];
}

- (void)reloadUsers {
    NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"];
    NSDictionary *manifest = [NSDictionary dictionaryWithContentsOfFile:[libraryPath stringByAppendingPathComponent:@"manifest.plist"]];
    if (!manifest) {
        manifest = @{};
    }
    userMap = manifest;
}

- (void)setName:(NSString *)name forUser:(NSString *)user {
    if (!userMap[user])
        return;
    NSString *d = userMap[user];
    NSMutableDictionary *md = [userMap mutableCopy];
    [md removeObjectForKey:user];
    md[name] = d;
    NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Profiles"];
    [md writeToFile:[libraryPath stringByAppendingPathComponent:@"manifest.plist"] atomically:YES];
    userMap = md;
}

@end
