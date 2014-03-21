//
//  SCUnifiedWindowController.h
//  Poison
//
//  Created by stal on 2/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SCMainWindowing.h"
#import "SCNonGarbageSplitView.h"

@interface SCUnifiedWindowController : NSWindowController <SCMainWindowing, SCNonGarbageSplitViewDelegate, NSWindowDelegate>

@end
