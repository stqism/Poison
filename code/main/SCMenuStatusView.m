#include "Copyright.h"

#import "SCMenuStatusView.h"

@interface SCMenuStatusView ()
@property (strong) IBOutlet NSTextField *nameDisplay;
@property (strong) IBOutlet NSTextField *statusDisplay;
@end

@implementation SCMenuStatusView {
    NSDictionary *_nameAttrs;
    NSDictionary *_smsgAttrs;
}

- (void)awakeFromNib {
    _nameAttrs = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:14]};
    _smsgAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:14]};
}

- (void)setName:(NSString *)name {
    self.nameDisplay.stringValue = name;
    [self adjustSize];
}

- (void)setStatusMessage:(NSString *)statusMessage {
    self.statusDisplay.stringValue = statusMessage;
    [self adjustSize];
}

- (void)adjustSize {
    NSSize nsize = [self.nameDisplay.stringValue sizeWithAttributes:_nameAttrs];
    NSSize ssize = [self.statusDisplay.stringValue sizeWithAttributes:_smsgAttrs];
    CGFloat requiredWidth = MAX(nsize.width, ssize.width);
    self.nameDisplay.frameSize = (NSSize){requiredWidth, self.nameDisplay.frame.size.height};
    self.statusDisplay.frameSize = (NSSize){requiredWidth, self.statusDisplay.frame.size.height};
    self.frameSize = (CGSize){requiredWidth + (self.nameDisplay.frame.origin.x * 2), self.frame.size.height};
}

@end
