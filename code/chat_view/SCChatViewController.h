#import <Cocoa/Cocoa.h>
#import "PXListViewDelegate.h"

@class WebView, DESChatContext, SCBorderedGradientView;
@interface SCChatViewController : NSViewController <NSTextFieldDelegate>

@property (strong) IBOutlet SCBorderedGradientView *headerView;
@property (strong) IBOutlet WebView *transcriptView;
@property (strong) IBOutlet NSButton *sendButton;
@property (strong) IBOutlet NSTextField *messageInput;
@property (strong) IBOutlet NSImageView *statusLight;
@property (strong, nonatomic) DESChatContext *context;
@property (strong) IBOutlet NSTextField *partnerName;

@end
