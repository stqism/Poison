#import "SCFriendListItemCell.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCFriendListItemCell {
    DESFriend *referencedFriend;
}

- (void)awakeFromNib {
    self.userImage.layer.cornerRadius = 2.0;
    self.userImage.layer.masksToBounds = YES;
}

- (void)bindToFriend:(DESFriend *)aFriend {
    referencedFriend = aFriend;
    [aFriend addObserver:self forKeyPath:@"userStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [aFriend addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    [aFriend addObserver:self forKeyPath:@"statusType" options:NSKeyValueObservingOptionNew context:NULL];
    [aFriend addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    self.displayName.stringValue = aFriend.displayName;
    self.userStatus.stringValue = aFriend.userStatus;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == referencedFriend) {
        if ([keyPath isEqualToString:@"userStatus"]) {
            self.userStatus.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"displayName"]) {
            self.displayName.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"statusType"]) {
            switch (referencedFriend.statusType) {
                case DESStatusTypeAway:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-away"];
                    break;
                case DESStatusTypeBusy:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-offline"];
                    break;
                default:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-online"];
                    break;
            }
        } else if ([keyPath isEqualToString:@"status"]) {
            if (referencedFriend.status != DESFriendStatusOnline) {
                self.statusLight.hidden = YES;
            } else {
                self.statusLight.hidden = NO;
            }
        }
    }
}

- (void)prepareForReuse {
    [referencedFriend removeObserver:self forKeyPath:@"userStatus"];
    [referencedFriend removeObserver:self forKeyPath:@"displayName"];
    [referencedFriend removeObserver:self forKeyPath:@"statusType"];
    [referencedFriend removeObserver:self forKeyPath:@"status"];
    referencedFriend = nil;
}

- (void)dealloc {
    [self prepareForReuse];
}

#ifndef POISON_USES_ALTERNATE_FRIENDCELL_DRAW_STYLE

- (void)drawRect:(NSRect)dirtyRect {
    if (self.isSelected) {
        NSGradient *shadowGrad = [[NSGradient alloc] initWithStartingColor:[NSColor clearColor] endingColor:[NSColor colorWithCalibratedWhite:0.071 alpha:0.3]];
        [[NSColor colorWithCalibratedWhite:0.118 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect:self.bounds] fill];
        [shadowGrad drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, -4, self.bounds.size.width, 8)] angle:-90.0];
        [shadowGrad drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, self.bounds.size.height - 4, self.bounds.size.width, 8)] angle:90.0];
    }
}

#else

/* Based on a mockup posted on /g/. Define the macro 
 * POISON_USES_ALTERNATE_FRIENDCELL_DRAW_STYLE to use it. */

- (void)drawRect:(NSRect)dirtyRect {
    if (self.isSelected) {
        [[NSColor colorWithCalibratedWhite:0.04 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(-2, 0, self.bounds.size.width + 2, self.bounds.size.height)] stroke];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.35] set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(0, self.bounds.size.height - 2, self.bounds.size.width, 1)] fill];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.20] set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 1, self.bounds.size.width, 1)] fill];
        NSGradient *bodyGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.10] endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.20]];
        [bodyGrad drawInBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(-2, 2, self.bounds.size.width + 2, self.bounds.size.height - 4)] angle:90.0];
    }
}

#endif

@end
