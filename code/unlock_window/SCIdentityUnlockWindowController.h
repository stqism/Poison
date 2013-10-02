#import <Cocoa/Cocoa.h>

@interface SCIdentityUnlockWindowController : NSWindowController <NSTextFieldDelegate>

@property (strong) IBOutlet NSSecureTextField *passwordField;
@property (strong) IBOutlet NSButton *unlockButton;
@property (strong, nonatomic) NSString *unlockingIdentity;
@property (strong) IBOutlet NSTextField *userName;

- (void)beginModalSession;

@end
