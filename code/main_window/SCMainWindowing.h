#include "Copyright.h"

#import <Foundation/Foundation.h>
#import "SCQRCodeSheetController.h"

@class DESToxConnection;
@protocol SCMainWindowing <NSObject, NSTableViewDelegate>
@property (strong) SCQRCodeSheetController *qrPanel;
- (instancetype)initWithDESConnection:(DESToxConnection *)tox;
- (void)displayQRCode;
- (void)displayAddFriend;
- (void)displayAddFriendWithToxSchemeURL:(NSURL *)url;
@end
