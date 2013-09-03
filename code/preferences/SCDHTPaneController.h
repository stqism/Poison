#import <Cocoa/Cocoa.h>

@interface SCDHTPaneController : NSViewController

@property (strong) IBOutlet NSButton *autoconnectCheck;
@property (strong) IBOutlet NSMatrix *radioMatrix;
@property (strong) IBOutlet NSTextField *hostField;
@property (strong) IBOutlet NSTextField *portField;
@property (strong) IBOutlet NSTextField *publicKeyField;

@end
