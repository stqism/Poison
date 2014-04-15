#import <Cocoa/Cocoa.h>

@interface SCTextField : NSTextField

- (void)clearSelection;
- (void)saveSelection;
- (void)restoreSelection;

@end
