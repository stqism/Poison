#import "SCThemeManager.h"

static SCThemeManager *sharedInstance = nil;
NSString *const SCTranscriptThemeDidChangeNotification = @"SCTranscriptThemeDidChangeNotification";

@implementation SCThemeManager {
    NSMutableDictionary *themeDictionary;
    NSString *themeBasePath;
    NSArray *searchPaths;
}

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[SCThemeManager alloc] init];
    }
}

+ (instancetype)sharedManager {
    return sharedInstance;
}

- (instancetype)init {
    self = [self initWithSearchPaths:@[
            [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Themes"],
            [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Poison"] stringByAppendingPathComponent:@"Themes"],
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
        NSString *savedThemePref = [[NSUserDefaults standardUserDefaults] stringForKey:@"aiThemeDirectory"];
        if (!savedThemePref || ![SCThemeManager isValidThemeAtPath:savedThemePref]) {
            savedThemePref = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"psnChatStyle" inDirectory:@"Themes"];
            [[NSUserDefaults standardUserDefaults] setObject:savedThemePref forKey:@"aiThemeDirectory"];
        }
        if (![SCThemeManager isValidThemeAtPath:savedThemePref]) {
            [NSException exceptionWithName:@"SCThemeLoadingFailed" reason:@"Not even the default theme is valid. WTF?!" userInfo:nil];
            abort();
        }
        themeBasePath = savedThemePref;
        themeDictionary = [[NSDictionary dictionaryWithContentsOfFile:[savedThemePref stringByAppendingPathComponent:@"theme.plist"]] mutableCopy];
        if (!themeDictionary) {
            [NSException exceptionWithName:@"SCThemeLoadingFailed" reason:@"Theme's still not valid. I'm outta here." userInfo:nil];
            abort();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SCTranscriptThemeDidChangeNotification object:self userInfo:nil];
    }
    return self;
}

+ (BOOL)isValidThemeAtPath:(NSString *)path {
    NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"theme.plist"]];
    if (!themeDict) {
        return NO;
    }
    NSString *baseTemplate = [path stringByAppendingPathComponent:themeDict[@"aiThemeBaseTemplateName"]];
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:baseTemplate isDirectory:&isDir] || isDir) {
        return NO;
    }
    if (!themeDict[@"aiThemeHumanReadableName"]) {
        return NO;
    }
    return YES;
}

- (NSColor *)parseHTMLColor:(NSString *)hex {
    if ([hex length] != 6) {
        return nil;
    }
    NSCharacterSet *valid = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFabcdef0123456789"];
    for (int l = 0; l < [hex length]; l++) {
        if ([valid characterIsMember:[hex characterAtIndex:l]]) {
            continue;
        } else {
            return nil;
        }
    }
    const char *chars = [hex UTF8String];
    uint8_t output[3];
    int i = 0, j = 0;
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte = 0;
    while (i < 6) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        output[j++] = wholeByte;
    }
    return [NSColor colorWithCalibratedRed:((CGFloat)output[0]) / 255.0 green:((CGFloat)output[1]) / 255.0 blue:((CGFloat)output[2]) / 255.0 alpha:1.0];
}

- (NSColor *)backgroundColorOfCurrentTheme {
    id dictValue = themeDictionary[@"aiThemeBackgroundColor"];
    if ([dictValue isKindOfClass:[NSColor class]]) {
        return (NSColor*)dictValue;
    } else if (!dictValue) {
        themeDictionary[@"aiThemeBackgroundColor"] = [NSColor whiteColor];
        return [NSColor whiteColor];
    } else if ([dictValue isKindOfClass:[NSString class]]) {
        NSColor *bgc = [self parseHTMLColor:dictValue];
        if (!bgc) {
            themeDictionary[@"aiThemeBackgroundColor"] = [NSColor whiteColor];
            return [NSColor whiteColor];
        } else {
            themeDictionary[@"aiThemeBackgroundColor"] = bgc;
            return bgc;
        }
    }
    return [NSColor whiteColor];
}

- (NSURL *)baseTemplateURLOfCurrentTheme {
    return [NSURL fileURLWithPath:[themeBasePath stringByAppendingPathComponent:themeDictionary[@"aiThemeBaseTemplateName"]]];
}

- (NSURL *)baseDirectoryURLOfCurrentTheme {
    return [NSURL fileURLWithPath:themeBasePath];
}

- (NSDictionary *)themeDictionary {
    return (NSDictionary*)themeDictionary;
}

- (void)changeThemePath:(NSString *)themePath {
    if ([SCThemeManager isValidThemeAtPath:themePath]) {
        themeBasePath = themePath;
        themeDictionary = [[NSDictionary dictionaryWithContentsOfFile:[themePath stringByAppendingPathComponent:@"theme.plist"]] mutableCopy];
        [[NSNotificationCenter defaultCenter] postNotificationName:SCTranscriptThemeDidChangeNotification object:self userInfo:nil];
    } else {
        NSLog(@"WARNING: -[SCThemeManager changeThemePath:] called with invalid path argument %@. The theme was not changed.", themePath);
    }
}

- (NSArray *)availableThemes {
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
            if ([SCThemeManager isValidThemeAtPath:s]) {
                [discoveredThemes addObject:s];
            }
        }
    }
    return (NSArray*)discoveredThemes;
}

@end
