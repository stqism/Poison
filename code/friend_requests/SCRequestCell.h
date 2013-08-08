#import <Cocoa/Cocoa.h>
#import "PXListViewCell.h"

@interface SCRequestCell : PXListViewCell
@property (strong) IBOutlet NSTextField *keyLabel;
@property (strong) IBOutlet NSTextField *dateReceivedLabel;
@end
