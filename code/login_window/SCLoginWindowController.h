#import <Cocoa/Cocoa.h>

@class SCGradientView, SCShadowedView, SCBigGreenButton;
@interface SCLoginWindowController : NSWindowController <NSTextFieldDelegate>

@property (strong) IBOutlet SCGradientView *backgroundView;
@property (strong) IBOutlet SCShadowedView *inputPanel;
@property (strong) IBOutlet NSTextField *helperLabel;
@property (strong) IBOutlet NSTextField *nicknameField;
@property (strong) IBOutlet NSButton *rememberCheck;
@property (strong) IBOutlet SCBigGreenButton *submitButton;
@property (strong) IBOutlet NSTextField *versionLabel;
@property (strong) IBOutlet SCShadowedView *pageTwoBackgroundView;

@property (strong) IBOutlet NSView *pageOne;
@property (strong) IBOutlet NSView *pageTwo;

@property (strong) IBOutlet NSButton *passwordSaveKeychainCheck;
@property (strong) IBOutlet NSSecureTextField *passwordFieldOne;
@property (strong) IBOutlet NSSecureTextField *passwordFieldTwo;

@end
