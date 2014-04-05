#ifndef Poison2x_SCBuddyListShared_h
#define Poison2x_SCBuddyListShared_h

#include "Copyright.h"

NS_INLINE NSImage *SCImageForFriendStatus(DESFriendStatus s) {
    switch (s) {
        case DESFriendStatusAvailable:
            return [NSImage imageNamed:@"status-light-online"];
        case DESFriendStatusAway:
            return [NSImage imageNamed:@"status-light-away"];
        case DESFriendStatusBusy:
            return [NSImage imageNamed:@"status-light-offline"];
        default:
            return [NSImage imageNamed:@"status-light-missing"];
    }
}

NS_INLINE NSString *SCStringForFriendStatus(DESFriendStatus sb) {
    switch (sb) {
        case DESFriendStatusAvailable:
            return NSLocalizedString(@"Available", nil);
        case DESFriendStatusAway:
            return NSLocalizedString(@"Away", nil);
        case DESFriendStatusBusy:
            return NSLocalizedString(@"Busy", nil);
        default:
            return NSLocalizedString(@"Offline", nil);
    }
}

@interface SCGroupMarker : NSObject
@property (strong) NSString *name;
@property (strong) NSString *other;
@end

#endif
