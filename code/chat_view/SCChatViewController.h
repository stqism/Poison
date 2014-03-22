#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "SCNonGarbageSplitView.h"

@interface SCChatViewController : NSViewController <SCNonGarbageSplitViewDelegate, NSTextFieldDelegate>
@property (nonatomic) BOOL showsVideoPane;
@property (nonatomic) BOOL showsUserList;
@end
