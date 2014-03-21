#import "ObjectiveTox-Private.h"

static inline DESEventType _DESExtendedGroupChatChangeTypeToDESEventType(uint8_t changeType) {
    switch (changeType) {
        case TOX_CHAT_CHANGE_PEER_ADD:
            return DESEventTypeGroupUserJoined;
        case TOX_CHAT_CHANGE_PEER_DEL:
            return DESEventTypeGroupUserLeft;
        case TOX_CHAT_CHANGE_PEER_NAME:
            return DESEventTypeGroupUserNameChanged;
        default:
            return 0;
    }
}

void _DESCallbackFriendRequest(Tox *tox, uint8_t *from, uint8_t *payload, uint16_t payloadLength, void *dtcInstance) {
    DESToxConnection *connection = (__bridge DESToxConnection*)dtcInstance;
    DESFriendRequest *req = [[DESFriendRequest alloc] initWithSenderKey:from message:payload length:payloadLength connection:connection];
    DESInfo(@"Friend request. -->");
    DESInfo(@"%@", [req senderName]);
    DESInfo(@"%@", [req message]);
    DESInfo(@"<----------------->");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([connection.delegate respondsToSelector:@selector(didReceiveFriendRequest:onConnection:)]) {
            [connection.delegate didReceiveFriendRequest:req onConnection:connection];
        }
    });
}



void _DESCallbackFriendMessage(Tox *tox, uint32_t from, uint8_t *payload, uint16_t payloadLength, void *dtcInstance) {
    
}

void _DESCallbackExtendedGroupChatNameListDidChange(Tox *tox, int group, int peernum, uint8_t changeType, void *dtcInstance) {
    DESToxConnection *connection = (__bridge DESToxConnection*)dtcInstance;
    DESGroupChat *applyGC = (DESGroupChat *)[connection groupChatWithID:group];
}