#import <Cocoa/Cocoa.h>

@interface SCAlertsPaneController : NSViewController

@property (strong) IBOutlet NSPopUpButton *soundSelection;
@property (strong) IBOutlet NSTextField *soundSetName;
@property (strong) IBOutlet NSTextField *soundSetAuthor;
@property (strong) IBOutlet NSTextField *soundSetDescription;
@property (strong) IBOutlet NSSlider *alertVolume;
@property (strong) IBOutlet NSPopUpButton *eventTypePicker;
@property (strong) IBOutlet NSTextField *builtInInfoLabel;
@property (strong) IBOutlet NSButton *uninstallButton;
@property (strong) IBOutlet NSButton *revealButton;

@end
