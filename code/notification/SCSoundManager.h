#import <Foundation/Foundation.h>
#import "SCNotificationManager.h"

@interface SCSoundManager : NSObject

@property (strong) NSString *pathOfCurrentSoundSetDirectory;

+ (instancetype)sharedManager;
+ (BOOL)isValidSoundSetAtPath:(NSString *)path;
- (NSArray *)availableSoundSets;
- (void)changeSoundSetPath:(NSString *)soundsPath;
- (NSSound *)soundForEventType:(SCEventType)type;
- (BOOL)currentSoundSetIsSystemProvided;

@end
