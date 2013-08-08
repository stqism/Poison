#import <Cocoa/Cocoa.h>
#import <Kudryavka/Kudryavka.h>

@class SCLoginWindowController, SCMainWindowController,
       SCPreferencesWindowController, SCAboutWindowController, SCKudTestingWindowController;
@interface SCAppDelegate : NSObject <NSApplicationDelegate>

/* Windows */
@property (strong) SCLoginWindowController *loginWindow;
@property (strong) SCMainWindowController *mainWindow;
@property (strong) SCPreferencesWindowController *preferencesWindow;
@property (strong) SCAboutWindowController *aboutWindow;
@property (strong) SCKudTestingWindowController *kTestingWindow;
@property (strong) NSArray *standaloneWindows;

- (void)beginConnectionWithUsername:(NSString *)theUsername saveMethod:(NKSerializerType)method;

@end
