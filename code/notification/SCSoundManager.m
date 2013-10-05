#import "SCSoundManager.h"

static SCSoundManager *sharedInstance = nil;

@implementation SCSoundManager {
    NSMutableDictionary *themeDictionary;
    NSArray *searchPaths;
    NSCache *soundCache;
}

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[SCSoundManager alloc] init];
    }
}

+ (instancetype)sharedManager {
    return sharedInstance;
}

- (instancetype)init {
    self = [self initWithSearchPaths:@[
               [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"SoundSets"],
               [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"SoundSets"],
            ]];
    return self;
}

- (instancetype)initWithSearchPaths:(NSArray *)anArray {
    self = [super init];
    if (self) {
        searchPaths = anArray;
        for (NSString *searchPath in anArray) {
            [[NSFileManager defaultManager] createDirectoryAtPath:searchPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *savedThemePref = [[NSUserDefaults standardUserDefaults] stringForKey:@"hiSetDirectory"];
        BOOL themeIsWithinSearchPaths = NO;
        for (NSString *searchPath in anArray) {
            if ([[savedThemePref stringByDeletingLastPathComponent] isEqualToString:searchPath])
                themeIsWithinSearchPaths = YES;
        }
        if (!savedThemePref || ![SCSoundManager isValidSoundSetAtPath:savedThemePref] || !themeIsWithinSearchPaths) {
            savedThemePref = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"psnSounds" inDirectory:@"SoundSets"];
            [[NSUserDefaults standardUserDefaults] setObject:savedThemePref forKey:@"hiSetDirectory"];
        }
        if (![SCSoundManager isValidSoundSetAtPath:savedThemePref]) {
            [[NSException exceptionWithName:@"SCSoundSetLoadingFailed" reason:@"Not even the default theme is valid. WTF?!" userInfo:nil] raise];
            abort();
        }
        self.pathOfCurrentSoundSetDirectory = savedThemePref;
        themeDictionary = [[NSDictionary dictionaryWithContentsOfFile:[savedThemePref stringByAppendingPathComponent:@"soundset.plist"]] mutableCopy];
        if (!themeDictionary) {
            [[NSException exceptionWithName:@"SCSoundSetLoadingFailed" reason:@"Theme's still not valid. I'm outta here." userInfo:nil] raise];
            abort();
        }
        soundCache = [[NSCache alloc] init];
    }
    return self;
}

+ (BOOL)isValidSoundSetAtPath:(NSString *)path {
    NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"soundset.plist"]];
    if (!themeDict) {
        return NO;
    }
    if (![themeDict[@"hiSounds"] isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSArray *checkFiles = @[
        @"hiEventConnected",
        @"hiEventDisconnected",
        @"hiEventFriendConnected",
        @"hiEventFriendDisconnected",
        @"hiEventNewChatMessage",
        @"hiEventNewFriendRequest",
        @"hiEventError",
        @"hiEventNewGroupInvite"
    ];
    BOOL isDir = NO;
    for (NSString *eType in checkFiles) {
        NSString *spath = themeDict[@"hiSounds"][eType];
        if (spath && [spath isKindOfClass:[NSString class]]) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:spath] isDirectory:&isDir] || isDir) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)changeSoundSetPath:(NSString *)soundsPath {
    if ([SCSoundManager isValidSoundSetAtPath:soundsPath]) {
        self.pathOfCurrentSoundSetDirectory = soundsPath;
        themeDictionary = [[NSDictionary dictionaryWithContentsOfFile:[soundsPath stringByAppendingPathComponent:@"soundset.plist"]] mutableCopy];
        [soundCache removeAllObjects];
    } else {
        NSLog(@"WARNING: -[SCSoundManager changeSoundSetPath:] called with invalid path argument %@. The theme was not changed.", soundsPath);
    }
}

- (NSString *)keyForEventType:(SCEventType)type {
    switch (type) {
        case SCEventTypeConnected:
            return @"hiEventConnected";
        case SCEventTypeDisconnected:
            return @"hiEventDisconnected";
        case SCEventTypeFriendConnected:
            return @"hiEventFriendConnected";
        case SCEventTypeFriendDisconnected:
            return @"hiEventFriendDisconnected";
        case SCEventTypeNewChatMessage:
            return @"hiEventNewChatMessage";
        case SCEventTypeNewFriendRequest:
            return @"hiEventNewFriendRequest";
        case SCEventTypeError:
            return @"hiEventError";
        case SCEventTypeNewGroupInvite:
            return @"hiEventNewGroupInvite";
        default:
            return nil;
    }
}

- (NSSound *)soundForEventType:(SCEventType)type {
    NSString *k = [self keyForEventType:type];
    if (k) {
        NSSound *sound = nil;
        sound = [soundCache objectForKey:k];
        if (!sound) {
            sound = [[NSSound alloc] initWithContentsOfFile:[self.pathOfCurrentSoundSetDirectory stringByAppendingPathComponent:themeDictionary[@"hiSounds"][k]] byReference:YES];
            [soundCache setObject:sound forKey:k];
        }
        if (sound) {
            if (![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"alertVolume"]) {
                [[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"alertVolume"];
            }
            sound.volume = [[NSUserDefaults standardUserDefaults] floatForKey:@"alertVolume"];
            return sound;
        } else {
            NSLog(@"*** WARNING: SoundSet at %@ declares a sound %@, but it is not available at the declared path.", self.pathOfCurrentSoundSetDirectory, k);
        }
    }
    return nil;
}

- (NSArray *)availableSoundSets {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSMutableArray *discoveredThemes = [[NSMutableArray alloc] init];
    for (NSString *searchPath in searchPaths) {
        NSArray *a = [fm contentsOfDirectoryAtPath:searchPath error:&error];
        if (error) {
            NSLog(@"I fucked up: %@", error.userInfo);
            error = nil;
            continue;
        }
        for (NSString *themePath in a) {
            NSString *s = [searchPath stringByAppendingPathComponent:themePath];
            if ([SCSoundManager isValidSoundSetAtPath:s]) {
                [discoveredThemes addObject:s];
            }
        }
    }
    return (NSArray*)discoveredThemes;
}

- (BOOL)currentSoundSetIsSystemProvided {
    NSString *systemPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"SoundSets"];
    if ([[self.pathOfCurrentSoundSetDirectory stringByDeletingLastPathComponent] isEqualToString:systemPath]) {
        return YES;
    }
    return NO;
}


@end
