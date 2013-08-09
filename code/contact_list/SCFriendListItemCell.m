#import "SCFriendListItemCell.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCFriendListItemCell {
    DESFriend *referencedFriend;
    CGFloat originalOriginX;
}

- (void)awakeFromNib {
    self.userImage.layer.cornerRadius = 2.0;
    self.userImage.layer.masksToBounds = YES;
    originalOriginX = self.userStatus.frame.origin.x;
}

- (NSString *)defaultStringForStatusType:(DESStatusType)kind {
    switch (kind) {
        case DESStatusTypeOnline: return NSLocalizedString(@"Online", @"");
        case DESStatusTypeAway: return NSLocalizedString(@"Away", @"");
        case DESStatusTypeBusy: return NSLocalizedString(@"Busy", @"");
        default: return NSLocalizedString(@"Invalid", @"");
    }
}

- (void)bindToFriend:(DESFriend *)aFriend {
    referencedFriend = aFriend;
    [aFriend addObserver:self forKeyPath:@"userStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [aFriend addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    [aFriend addObserver:self forKeyPath:@"statusType" options:NSKeyValueObservingOptionNew context:NULL];
    [aFriend addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    if ([aFriend.displayName isEqualToString:@""]) {
        self.displayName.stringValue = referencedFriend.publicKey;
        self.displayName.textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
    } else {
        self.displayName.stringValue = aFriend.displayName;
        self.displayName.textColor = [NSColor whiteColor];
    }
    if ([aFriend.userStatus isEqualToString:@""]) {
        self.userStatus.stringValue = [self defaultStringForStatusType:aFriend.statusType];
    } else {
        self.userStatus.stringValue = aFriend.userStatus;
    }
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
    if (referencedFriend.status != DESFriendStatusOnline) {
        self.statusLight.hidden = YES;
        [self.userStatus setFrameOrigin:(NSPoint){self.statusLight.frame.origin.x, self.userStatus.frame.origin.y}];
        switch (referencedFriend.status) {
            case DESFriendStatusConfirmed: self.userStatus.stringValue = NSLocalizedString(@"Offline", @"");
            case DESFriendStatusRequestSent: self.userStatus.stringValue = NSLocalizedString(@"Request sent...", @"");
            case DESFriendStatusOffline: self.userStatus.stringValue = NSLocalizedString(@"Offline", @"");
            default: self.userStatus.stringValue = NSLocalizedString(@"Offline", @"");
        }
    } else {
        self.statusLight.hidden = NO;
        [self.userStatus setFrameOrigin:(NSPoint){originalOriginX, self.userStatus.frame.origin.y}];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == referencedFriend) {
        if ([keyPath isEqualToString:@"userStatus"]) {
            if ([change[NSKeyValueChangeNewKey] isEqualToString:@""]) {
                self.userStatus.stringValue = [self defaultStringForStatusType:referencedFriend.statusType];
            } else {
                self.userStatus.stringValue = change[NSKeyValueChangeNewKey];
            }
        } else if ([keyPath isEqualToString:@"displayName"]) {
            if ([change[NSKeyValueChangeNewKey] isEqualToString:@""]) {
                self.displayName.stringValue = referencedFriend.publicKey;
                self.displayName.textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
            } else {
                self.displayName.stringValue = change[NSKeyValueChangeNewKey];
                self.displayName.textColor = [NSColor whiteColor];
            }
        } else if ([keyPath isEqualToString:@"statusType"] || [keyPath isEqualToString:@"status"]) {
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
            if (referencedFriend.status != DESFriendStatusOnline) {
                self.statusLight.hidden = YES;
                [self.userStatus setFrameOrigin:(NSPoint){self.statusLight.frame.origin.x, self.userStatus.frame.origin.y}];
                switch (referencedFriend.status) {
                    case DESFriendStatusConfirmed: self.userStatus.stringValue = NSLocalizedString(@"Offline", @"");
                    case DESFriendStatusRequestSent: self.userStatus.stringValue = NSLocalizedString(@"Request sent...", @"");
                    case DESFriendStatusOffline: self.userStatus.stringValue = NSLocalizedString(@"Offline", @"");
                    default: self.userStatus.stringValue = NSLocalizedString(@"Offline", @"");
                }
            } else {
                self.statusLight.hidden = NO;
                [self.userStatus setFrameOrigin:(NSPoint){originalOriginX, self.userStatus.frame.origin.y}];
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
