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
@property (strong) NSString *queuedPublicKey;
@property (strong) NSString *encPassword;

- (void)beginConnectionWithUsername:(NSString *)theUsername;
- (void)connectNewAccountWithUsername:(NSString *)theUsername password:(NSString *)pass inKeychain:(BOOL)yeahnah;
- (void)newWindowWithDESContext:(id<DESChatContext>)aContext;
- (void)closeWindowsContainingDESContext:(id<DESChatContext>)ctx;

- (NSInteger)unreadCountForChatContext:(id<DESChatContext>)ctx;
- (void)clearUnreadCountForChatContext:(id<DESChatContext>)ctx;
- (id<DESChatContext>)currentChatContext;
- (void)giveFocusToChatContext:(id<DESChatContext>)ctx;

- (NSString *)findPasswordInKeychain:(NSString *)name;
- (void)clearPasswordFromKeychain:(NSString *)pass username:(NSString *)user;
- (void)dumpPasswordToKeychain:(NSString *)pass username:(NSString *)user;

@end
