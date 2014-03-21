#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const kaiHumanReadableName;
FOUNDATION_EXPORT NSString *const kaiAuthor;
FOUNDATION_EXPORT NSString *const kaiShortVersionString;
FOUNDATION_EXPORT NSString *const kaiDescription;

typedef NS_ENUM(NSInteger, SCResource) {
    SCResourceTheme,
    SCResourceSoundSet
};

@interface SCResourceBundle : NSObject

- (instancetype)initWithBundleName:(NSString *)bundleName ofType:(SCResource)type;

- (NSString *)name;
- (NSString *)author;
- (NSString *)versionString;
- (NSString *)bundleDescription;

- (NSDictionary *)infoDictionary;
- (NSURL *)URLForResource:(NSString *)partial;

@end
