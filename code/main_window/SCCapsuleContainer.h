#import <Cocoa/Cocoa.h>

@interface SCCapsuleCell : NSSegmentedCell

@end

@interface SCCapsuleContainer : NSView

@property (strong) IBOutlet NSSegmentedControl *tabControl;

@end
