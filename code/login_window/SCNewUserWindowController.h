//
//  SCNewUserWindowController.h
//  Poison
//
//  Created by stal on 1/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SCGradientView.h"
#import "SCShadowedView.h"

@interface SCNewUserWindowController : NSWindowController <NSWindowDelegate, NSTextFieldDelegate>
@property (strong) IBOutlet SCGradientView *header;
@property (strong) IBOutlet SCShadowedView *footer;

- (void)tryAutomaticLogin:(NSString *)name;
@end
