//
//  SCMainWindowing.h
//  Poison
//
//  Created by stal on 2/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

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
