//
//  SCAppDelegate.h
//  Atroquinine
//
//  Created by stal on 20/2/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ObjectiveTox.h"
#import "SCMainWindowing.h"
#include "tox.h"

@interface SCAppDelegate : NSObject <NSApplicationDelegate, DESToxConnectionDelegate>
@property (strong, nonatomic) NSWindowController *mainWindowController;
- (void)makeApplicationReadyForToxing:(txd_intermediate_t)userProfile name:(NSString *)profileName;
@end
