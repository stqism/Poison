#import <Cocoa/Cocoa.h>

@interface SCDHTStatusView : NSView

@property (nonatomic) NSInteger connectedNodes;
@property SEL action;
@property (strong) id target;

@end
