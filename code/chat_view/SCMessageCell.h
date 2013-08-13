#import <Cocoa/Cocoa.h>
#import "PXListViewCell.h"

@interface SCMessageCell : PXListViewCell
@property (strong) IBOutlet NSTextField *senderTitle;
@property (strong) IBOutlet NSTextField *dateReceived;
@property (strong) IBOutlet NSTextField *textView;
@end
