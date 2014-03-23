#ifndef DESConstants_h
#define DESConstants_h

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

FOUNDATION_EXPORT NSString *const DESDefaultNickname; /* Toxicle */
FOUNDATION_EXPORT NSString *const DESDefaultStatusMessage; /* Toxing on Tox */

extern const uint32_t DESPublicKeySize;
extern const uint32_t DESPrivateKeySize;
extern const uint32_t DESFriendAddressSize;

extern const uint32_t DESMaximumMessageLength;
extern const uint32_t DESMaximumNameLength;
extern const uint32_t DESMaximumStatusMessageLength;

typedef NS_ENUM(uint8_t, DESFriendStatus) {
    DESFriendStatusAvailable,
    DESFriendStatusAway,
    DESFriendStatusBusy,
    DESFriendStatusOffline,
};

typedef NS_ENUM(uint8_t, DESMessageType) {
    DESMessageTypeText,
    DESMessageTypeAction,
};

typedef NS_ENUM(uint8_t, DESEventType) {
    DESEventTypeGroupUserNameChanged,
    DESEventTypeGroupUserJoined,
    DESEventTypeGroupUserLeft,
    DESEventTypeFriendNameChanged,
    DESEventTypeFriendStatusMessageChanged,
    DESEventTypeFriendUserStatusChanged,
    DESEventTypeFriendConnectionStatusChanged,
    DESEventTypeFriendControlMessage
};

#endif
