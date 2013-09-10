#import <Cocoa/Cocoa.h>

@interface SCGeneralPaneController : NSViewController

@property (strong) IBOutlet NSButton *radioButton200;
@property (strong) IBOutlet NSButton *radioButton100;
@property (strong) IBOutlet NSButton *radioButton20;
@property (strong) IBOutlet NSButton *radioButton10;
@property (strong) IBOutlet NSPopUpButton *popUp;
@property (strong) IBOutlet NSButton *sendsNotification;
@property (strong) IBOutlet NSButton *playsSound;

@end
