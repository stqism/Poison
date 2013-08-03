#import <Cocoa/Cocoa.h>

@class SCLoginWindowController, SCMainWindowController,
       SCPreferencesWindowController, SCAboutWindowController;
@interface SCAppDelegate : NSObject <NSApplicationDelegate>

/* Windows */
@property (strong) SCLoginWindowController *loginWindow;
@property (strong) SCMainWindowController *mainWindow;
@property (strong) SCPreferencesWindowController *preferencesWindow;
@property (strong) SCAboutWindowController *aboutWindow;
@property (strong) NSArray *standaloneWindows;

@end
