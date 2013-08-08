#import <Cocoa/Cocoa.h>
#import "PXListViewCell.h"

@interface SCFriendListHeaderCell : PXListViewCell

@property (strong, nonatomic) NSColor *backgroundColor;
@property (strong, nonatomic) NSColor *shadowColor;
@property (strong, nonatomic) NSColor *textColor;
@property (strong, nonatomic) NSString *stringValue;

@end
