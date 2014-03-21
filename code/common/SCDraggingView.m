//
//  SCDraggingView.m
//  Poison
//
//  Created by stal on 3/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import "SCDraggingView.h"

@implementation SCDraggingView {
    CGPoint initialLocation;
    BOOL willDrag;
}

#pragma mark - Dragging

- (void)mouseEntered:(NSEvent *)theEvent {
    willDrag = NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    initialLocation = [theEvent locationInWindow];
    willDrag = YES;
}

- (void)mouseUp:(NSEvent *)theEvent {
    initialLocation = CGPointZero;
    willDrag = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (!self.dragsWindow || !willDrag) {
        return;
    } else {
        NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
        NSRect windowFrame = [self.window frame];
        NSPoint newOrigin = windowFrame.origin;
        NSPoint currentLocation = [theEvent locationInWindow];
        newOrigin.x += (currentLocation.x - initialLocation.x);
        newOrigin.y += (currentLocation.y - initialLocation.y);
        if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
            newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
        }
        [self.window setFrameOrigin:newOrigin];
    }
}

@end
