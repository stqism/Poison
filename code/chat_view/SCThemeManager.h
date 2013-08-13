#import <Foundation/Foundation.h>

NSString *const SCTranscriptThemeDidChangeNotification;

@interface SCThemeManager : NSObject

@property (strong) NSString *pathOfCurrentThemeDirectory;

+ (instancetype)sharedManager;
+ (BOOL)isValidThemeAtPath:(NSString *)path;
- (NSColor *)backgroundColorOfCurrentTheme;
- (NSURL *)baseTemplateURLOfCurrentTheme;
- (NSURL *)baseDirectoryURLOfCurrentTheme;
- (NSArray *)availableThemes;

@end
