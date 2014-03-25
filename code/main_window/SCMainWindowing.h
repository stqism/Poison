#include "Copyright.h"

#import <Foundation/Foundation.h>
#import "SCQRCodeSheetController.h"
#import "SCAddFriendSheetController.h"

@class DESToxConnection;
@protocol SCMainWindowing <NSObject>
- (instancetype)initWithDESConnection:(DESToxConnection *)tox;
- (void)displayQRCode;
- (void)displayAddFriend;
- (void)displayAddFriendWithToxSchemeURL:(NSURL *)url;
@end
