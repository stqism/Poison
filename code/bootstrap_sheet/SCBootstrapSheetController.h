#import <Cocoa/Cocoa.h>

@interface SCBootstrapSheetController : NSWindowController
@property (strong) IBOutlet NSView *easyView;
@property (strong) IBOutlet NSView *advancedView;
@property (strong) IBOutlet NSTextField *autostrapStatusLabel;
@property (strong) IBOutlet NSProgressIndicator *autostrapProgress;
@property (strong) IBOutlet NSButton *suppressionCheckEasy;
@property (strong) IBOutlet NSButton *suppressionCheckAdvanced;

@property (strong) IBOutlet NSButton *autostrapButton;
@property (strong) IBOutlet NSButton *modeSwitchButton;
@property (strong) IBOutlet NSButton *cancelButton;

@property (strong) IBOutlet NSTextField *hostField;
@property (strong) IBOutlet NSTextField *portField;
@property (strong) IBOutlet NSTextField *publicKeyField;
@property (strong) IBOutlet NSButton *advContinueButton;
@property (strong) IBOutlet NSButton *advBackButton;
@end
