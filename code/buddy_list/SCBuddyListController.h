#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import "ObjectiveTox.h"

@interface SCBuddyListController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
- (void)attachKVOHandlersToConnection:(DESToxConnection *)tox;
- (IBAction)changeName:(id)sender;
- (IBAction)changeStatus:(id)sender;

- (NSString *)formatDate:(NSDate *)date;
- (NSString *)lookupCustomNameForID:(NSString *)id_;
@end
