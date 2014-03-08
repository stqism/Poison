#import <Cocoa/Cocoa.h>

@interface SCAddFriendSheetController : NSWindowController <NSTextFieldDelegate>

@property (strong) IBOutlet NSTextField *keyField;
@property (strong) IBOutlet NSTextField *messageField;
@property (strong) IBOutlet NSButton *sendsMessageCheck;
@property (strong) IBOutlet NSButton *sendButton;
@property (strong) IBOutlet NSButton *cancelButton;

- (void)fillFields;
- (void)revalidate;

@end
