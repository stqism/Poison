//
//  SCInformationalButton.m
//  Poison
//
//  Created by stal on 1/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import "SCInformationalButton.h"

@implementation SCInformationalButton

- (NSView *)hitTest:(NSPoint)aPoint {
    return self.superview;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [self.superview mouseDown:theEvent];
}

@end
