#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "ObjectiveTox.h"

@interface SCBuddyListController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
- (void)attachKVOHandlersToConnection:(DESToxConnection *)tox;
@end
