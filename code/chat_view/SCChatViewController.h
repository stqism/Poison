//
//  SCChatViewController.h
//  Poison
//
//  Created by stal on 2/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SCNonGarbageSplitView.h"

@interface SCChatViewController : NSViewController <SCNonGarbageSplitViewDelegate, NSTextFieldDelegate>
@property (nonatomic) BOOL showsVideoPane;
@property (nonatomic) BOOL showsUserList;
@end
