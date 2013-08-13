#import <Cocoa/Cocoa.h>
#import <Kudryavka/Kudryavka.h>

@class SCLoginWindowController, SCMainWindowController,
       SCPreferencesWindowController, SCAboutWindowController, SCKudTestingWindowController, DESChatContext;
@interface SCAppDelegate : NSObject <NSApplicationDelegate>

/* Windows */
@property (strong) SCLoginWindowController *loginWindow;
@property (strong) SCMainWindowController *mainWindow;
@property (strong) SCPreferencesWindowController *preferencesWindow;
@property (strong) SCAboutWindowController *aboutWindow;
@property (strong) SCKudTestingWindowController *kTestingWindow;
@property (strong) NSArray *standaloneWindows;

@property (unsafe_unretained) IBOutlet NSMenuItem *kudoTestingMenuItem;
- (void)beginConnectionWithUsername:(NSString *)theUsername saveMethod:(NKSerializerType)method;
- (void)newWindowWithDESContext:(DESChatContext *)aContext;

@end
