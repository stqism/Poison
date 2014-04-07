#include "Copyright.h"

#import <Foundation/Foundation.h>

@class DESToxConnection, DESConversation, SCBuddyListController;
@interface SCBuddyListManager : NSObject <NSTableViewDataSource>
@property (nonatomic, readonly) NSArray *orderingList;
@property (nonatomic, copy) NSString *filterString;
- (instancetype)initWithConnection:(DESToxConnection *)con;
- (DESConversation *)conversationAtRowIndex:(NSInteger)r;
@end
