#import <Cocoa/Cocoa.h>
#import <Kudryavka/Kudryavka.h>
#import <DeepEnd/DeepEnd.h>

@class SCLoginWindowController, SCMainWindowController,
       SCPreferencesWindowController, SCAboutWindowController,
       SCKudTestingWindowController;
@interface SCAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

/* Windows */
@property (strong) SCLoginWindowController *loginWindow;
@property (strong) SCMainWindowController *mainWindow;
@property (strong) SCPreferencesWindowController *preferencesWindow;
@property (strong) SCAboutWindowController *aboutWindow;
@property (strong) SCKudTestingWindowController *kTestingWindow;
@property (strong) NSArray *standaloneWindows;

@property (unsafe_unretained) IBOutlet NSMenuItem *kudoTestingMenuItem;
@property (strong) NSString *queuedPublicKey;
- (void)beginConnectionWithUsername:(NSString *)theUsername saveMethod:(NKSerializerType)method;
- (void)newWindowWithDESContext:(id<DESChatContext>)aContext;
- (void)closeWindowsContainingDESContext:(id<DESChatContext>)ctx;

@end
