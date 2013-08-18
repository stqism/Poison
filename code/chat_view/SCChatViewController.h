#import <Cocoa/Cocoa.h>
#import <DeepEnd/DeepEnd.h>
#import "PXListViewDelegate.h"

@class WebView, SCBorderedGradientView;
@interface SCChatViewController : NSViewController <NSTextFieldDelegate>

@property (strong) IBOutlet SCBorderedGradientView *headerView;
@property (strong) IBOutlet WebView *transcriptView;
@property (strong) IBOutlet NSButton *sendButton;
@property (strong) IBOutlet NSTextField *messageInput;
@property (strong) IBOutlet NSImageView *statusLight;
@property (strong, nonatomic) id<DESChatContext> context;
@property (strong) IBOutlet NSTextField *partnerName;

@end
