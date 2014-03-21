//
//  SCAddFriendSheetController.h
//  Poison
//
//  Created by stal on 15/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SCAddFriendSheetController : NSWindowController
- (void)setToxID:(NSString *)theID;
- (void)setMessage:(NSString *)theMessage;
@end
