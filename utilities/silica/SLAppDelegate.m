#import "SLAppDelegate.h"
#import "SCThemeManager.h"
#import "SCWebKitFriend.h"
#import "SCWebKitMessage.h"
#import "SCWebKitContext.h"
#import "SLBackingView.h"
#import <DeepEnd/DeepEnd.h>
#import <WebKit/WebKit.h>

@interface SLMockContext : NSObject <DESChatContext>

@end

@implementation SLMockContext
@synthesize backlog;
@synthesize participants;
@synthesize maximumBacklogSize;

- (instancetype)init {
    return self;
}

- (instancetype)initWithPartner:(DESFriend *)aFriend {
    return self;
}

- (instancetype)initWithParticipants:(NSArray *)participants {
    return self;
}

- (DESFriendManager *)friendManager {
    return nil;
}

- (void)setFriendManager:(DESFriendManager *)manager {
    return;
}

- (void)addParticipant:(DESFriend *)theFriend {}
- (void)removeParticipant:(DESFriend *)theFriend {}

- (void)sendMessage:(NSString *)message {}
- (void)pushMessage:(DESMessage *)aMessage {}

@end

@interface SLMockFriend : DESFriend

- (instancetype)initAsMock;
- (void)setNumber:(NSInteger)num;

@end

@implementation SLMockFriend

- (instancetype)initAsMock {
    self = [super init];
    _displayName = @"Hipster";
    _userStatus = @"Online";
    uint8_t *data = malloc(DESPublicKeySize);
    _publicKey = DESConvertPublicKeyToString(data);
    free(data);
    _friendNumber = 0;
    _status = DESFriendStatusOnline;
    _statusType = DESStatusTypeOnline;
    return self;
}

- (void)setNumber:(NSInteger)num {
    _friendNumber = (int)num;
}

@end

@interface SLAppDelegate ()

@property (unsafe_unretained) IBOutlet NSTextField *name;
@property (unsafe_unretained) IBOutlet NSTextField *template;
@property (unsafe_unretained) IBOutlet NSTextField *author;
@property (unsafe_unretained) IBOutlet NSTextField *descr;
@property (unsafe_unretained) IBOutlet NSTextField *version;
@property (unsafe_unretained) IBOutlet NSColorWell *color;
@property (strong) SLMockFriend *mockFriend;

@end

@interface SCThemeManager (expose)

- (NSColor *)parseHTMLColor:(NSString *)hex;

@end

@implementation SLAppDelegate {
    NSMutableDictionary *themeDictionary;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"Silica is a work in progress. Behaviour should reflect the same revision of Poison that Silica is compiled against.\n"
          @"If it doesn't, and you are running the latest git of Silica, please file an issue on GitHub, including \"Silica\" or \"ThemeUtility\" in your issue title.");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
    _mockFriend = [[SLMockFriend alloc] initAsMock];
    themeDictionary = [@{} mutableCopy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTheme:) name:SCTranscriptThemeDidChangeNotification object:[SCThemeManager sharedManager]];
    self.webView.drawsBackground = NO;
    self.webView.frameLoadDelegate = self;
    [self reloadTheme:nil];
}

- (IBAction)loadTheme:(id)sender {
    NSOpenPanel *open = [[NSOpenPanel alloc] init];
    open.prompt = @"Select a theme...";
    open.allowedFileTypes = @[@"psnChatStyle"];
    NSInteger success = [open runModal];
    if (success == NSOKButton) {
        [[SCThemeManager sharedManager] changeThemePath:[open.URL path]];
        NSLog(@"Loaded theme from directory: %@", open.URL.path);
        NSLog(@"%@", [[SCThemeManager sharedManager] themeDictionary]);
    }
}

- (IBAction)tfEdited:(NSTextField *)sender {
    themeDictionary[sender.identifier] = sender.stringValue;
}

- (IBAction)colorEdited:(id)sender {
    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    [self.color.color getRed:&red green:&green blue:&blue alpha:NULL];
    themeDictionary[@"aiThemeBackgroundColor"] = [NSString stringWithFormat:@"%02X%02X%02X", (int)(red * 255), (int)(green * 255), (int)(blue * 255)];
    self.backing.topLel = self.color.color;
    self.backing.needsDisplay = YES;
}

- (IBAction)selfCheckEdited:(NSButton *)sender {
    [_mockFriend setNumber:sender.state == NSOnState ? DESFriendSelf : 0];
}

- (void)reloadTheme:(NSNotification *)notification {
    themeDictionary = [[SCThemeManager sharedManager].themeDictionary mutableCopy];
    self.window.title = [NSString stringWithFormat:@"Silica: %@", [[SCThemeManager sharedManager].baseDirectoryURLOfCurrentTheme path]];
    NSLog(@"Theme loaded from %@: ", [SCThemeManager sharedManager].baseDirectoryURLOfCurrentTheme.path);
    self.name.stringValue = themeDictionary[@"aiThemeHumanReadableName"];
    self.template.stringValue = themeDictionary[@"aiThemeBaseTemplateName"];
    self.author.stringValue = themeDictionary[@"aiThemeAuthor"];
    self.descr.stringValue = themeDictionary[@"aiThemeDescription"];
    self.version.stringValue = themeDictionary[@"aiThemeShortVersionString"];
    self.color.color = [SCThemeManager sharedManager].backgroundColorOfCurrentTheme;
    self.backing.topLel = [SCThemeManager sharedManager].backgroundColorOfCurrentTheme;
    self.backing.needsDisplay = YES;
    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[SCThemeManager sharedManager].baseTemplateURLOfCurrentTheme cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10]];
    
}

- (IBAction)pushTextMessage:(id)sender {
    DESMessage *mockMessage;
    switch(((NSButton *)sender).tag) {
        case DESMessageTypeChat:
            mockMessage = [DESMessage messageFromSender:_mockFriend content:@"This is a Silica test message." messageID:12345];
            break;
        case DESMessageTypeAction:
            mockMessage = [DESMessage actionFromSender:_mockFriend content:@"performs a Silica test action."];
            break;
        case DESMessageTypeNicknameChange:
            mockMessage = [DESMessage nickChangeFromSender:_mockFriend newNick:@"Alice"];
            break;
        case DESMessageTypeUserStatusChange:
            mockMessage = [DESMessage userStatusChangeFromSender:_mockFriend newStatus:@"Testing changing their status message in Silica."];
            break;
    }
    [self.webView.mainFrame.windowObject callWebScriptMethod:@"pushMessage" withArguments:@[[[SCWebKitMessage alloc] initWithMessage:mockMessage]]];
}

- (IBAction)pushEnumeratedMessage:(id)sender {
    DESMessage *mockMessage;
    switch(((NSButton *)sender).tag) {
        case DESMessageTypeStatusTypeChange:
            mockMessage = [DESMessage userStatusTypeChangeFromSender:_mockFriend newStatusType:DESStatusTypeAway];
            break;
        case DESMessageTypeStatusChange:
            mockMessage = [DESMessage statusChangeFromSender:_mockFriend newStatus:DESFriendStatusOnline];
            break;
    }
    [self.webView.mainFrame.windowObject callWebScriptMethod:@"pushMessage" withArguments:@[[[SCWebKitMessage alloc] initWithMessage:mockMessage]]];
}

- (IBAction)reloadTemplate:(id)sender {
    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[SCThemeManager sharedManager].baseTemplateURLOfCurrentTheme cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10]];
}

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
    [self injectConstants];
}

- (void)injectConstants {
    /* This exports all DES constants to the webview. */
    WebScriptObject *w = self.webView.windowScriptObject;
    [w setValue:[NSNumber numberWithInteger:DESFriendSelf] forKey:@"DESFriendSelf"];
    [w setValue:[NSNumber numberWithInteger:DESFriendInvalid] forKey:@"DESFriendInvalid"];
    
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusOffline] forKey:@"DESFriendStatusOffline"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusOnline] forKey:@"DESFriendStatusOnline"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusRequestReceived] forKey:@"DESFriendStatusRequestReceived"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusRequestSent] forKey:@"DESFriendStatusRequestSent"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusConfirmed] forKey:@"DESFriendStatusConfirmed"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusSelf] forKey:@"DESFriendStatusSelf"];
    
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeOnline] forKey:@"DESStatusTypeOnline"];
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeAway] forKey:@"DESStatusTypeAway"];
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeBusy] forKey:@"DESStatusTypeBusy"];
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeInvalid] forKey:@"DESStatusTypeInvalid"];
    
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeChat] forKey:@"DESMessageTypeChat"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeAction] forKey:@"DESMessageTypeAction"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeNicknameChange] forKey:@"DESMessageTypeNicknameChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeStatusChange] forKey:@"DESMessageTypeStatusChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeUserStatusChange] forKey:@"DESMessageTypeUserStatusChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeStatusTypeChange] forKey:@"DESMessageTypeStatusTypeChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeSystem] forKey:@"DESMessageTypeSystem"];
    [w setValue:[[SCWebKitContext alloc] initWithContext:[[SLMockContext alloc] init]] forKey:@"Conversation"];
}

- (IBAction)save:(id)sender {
    [themeDictionary writeToFile:[NSString stringWithFormat:@"%@/theme.plist", [[SCThemeManager sharedManager].baseDirectoryURLOfCurrentTheme path]] atomically:YES];
    NSLog(@"Saved successfully.");
}
                                      
- (IBAction)saveAs:(id)sender {
    NSSavePanel *open = [[NSSavePanel alloc] init];
    open.prompt = @"Save here";
    open.allowedFileTypes = @[@"psnChatStyle"];
    NSInteger success = [open runModal];
    if (success == NSOKButton) {
        [[NSFileManager defaultManager] copyItemAtURL:[SCThemeManager sharedManager].baseDirectoryURLOfCurrentTheme toURL:open.URL error:nil];
        [[SCThemeManager sharedManager] changeThemePath:[open.URL path]];
        NSLog(@"Saved successfully to new directory: %@.", [open.URL path]);
    }
}

@end
