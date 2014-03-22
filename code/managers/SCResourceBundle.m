#include "Copyright.h"

#import "SCResourceBundle.h"

NSString *const kaiHumanReadableName = @"aiHumanReadableName";
NSString *const kaiAuthor = @"aiAuthor";
NSString *const kaiShortVersionString = @"aiShortVersionString";
NSString *const kaiDescription = @"aiDescription";

NS_INLINE NSString *SCExtensionForResourceType(SCResource type) {
    switch (type) {
        case SCResourceTheme:
            return @"psnChatStyle";
        case SCResourceSoundSet:
            return @"psnSounds";
        default:
            return nil;
    }
}

@implementation SCResourceBundle {
    NSURL *_basePath;
    NSDictionary *_bundleValues;
}

- (instancetype)initWithBundleName:(NSString *)bundleName ofType:(SCResource)type {
    self = [super init];
    if (self) {

    }
    return self;
}

- (instancetype)initWithBundleName:(NSString *)bundleName
                            ofType:(SCResource)type
                       searchPaths:(NSArray *)paths {
    self = [super init];
    if (self) {
        NSURL *foundPath = nil;
        NSString *finding = [bundleName stringByAppendingPathExtension:SCExtensionForResourceType(type)];
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *path in [paths reverseObjectEnumerator]) {
            BOOL isDir = NO;
            NSString *full = [path stringByAppendingPathComponent:finding];
            if ([fm fileExistsAtPath:full isDirectory:&isDir] && isDir) {
                foundPath = [NSURL fileURLWithPath:full];
                break;
            }
        }
        if (!foundPath)
            return nil;
        _basePath = foundPath;
        _bundleValues = [NSDictionary dictionaryWithContentsOfURL:[foundPath URLByAppendingPathComponent:@"Info.plist"]];
        if (!_bundleValues)
            return nil;
    }
    return self;
}

- (NSDictionary *)infoDictionary {
    return _bundleValues;
}

- (NSString *)name {
    return _bundleValues[kaiHumanReadableName];
}

- (NSString *)author {
    return _bundleValues[kaiAuthor];
}

- (NSString *)versionString {
    return _bundleValues[kaiShortVersionString];
}

- (NSString *)bundleDescription {
    return _bundleValues[kaiDescription];
}

- (NSURL *)URLForResource:(NSString *)partial {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[_basePath path] stringByAppendingPathComponent:partial]])
        return [_basePath URLByAppendingPathComponent:partial];
    else
        return nil;
}

@end
