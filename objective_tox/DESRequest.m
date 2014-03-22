#import "ObjectiveTox-Private.h"

@implementation DESRequest
- (void)accept { DESAbstractWarning; }
- (void)decline { DESAbstractWarning; }
@end

@implementation DESFriendRequest {
    NSString *_senderName;
    NSString *_message;
    DESToxConnection *__weak _connection;
}

- (instancetype)initWithSenderKey:(const uint8_t *)sender
                          message:(const uint8_t *)message
                           length:(uint32_t)length
                       connection:(DESToxConnection *)connection {
    self = [super init];
    if (self) {
        _senderName = DESConvertPublicKeyToString(sender);
        self.senderPublicKey = malloc(TOX_CLIENT_ID_SIZE);
        memcpy(self.senderPublicKey, sender, TOX_CLIENT_ID_SIZE);
        _message = [[NSString alloc] initWithBytes:message length:length encoding:NSUTF8StringEncoding];
        _connection = connection;
    }
    return self;
}

- (NSString *)senderName {
    return _senderName;
}

- (NSString *)message {
    return _message;
}

- (DESToxConnection *)connection {
    return _connection;
}

- (void)accept {
    tox_add_friend_norequest(_connection._core, self.senderPublicKey);
}

- (void)decline {
    return;
}

- (void)dealloc {
    free(self.senderPublicKey);
}

@end

@implementation DESGroupRequest {
    NSString *_senderName;
    NSString *_message;
    DESToxConnection *__weak _connection;
}

- (instancetype)initWithSenderNo:(int32_t)sender
                            name:(NSString *)name
                        groupKey:(const uint8_t *)key
                      connection:(DESToxConnection *)connection {
    self = [super init];
    if (self) {
        _senderName = name;
        self.groupKey = malloc(TOX_CLIENT_ID_SIZE);
        memcpy(self.groupKey, key, TOX_CLIENT_ID_SIZE);
        _message = nil;
        _connection = connection;
    }
    return self;
}

- (NSString *)senderName {
    return _senderName;
}

- (NSString *)message {
    return _message;
}

- (DESToxConnection *)connection {
    return _connection;
}

- (void)accept {
    int32_t groupnum = tox_join_groupchat(_connection._core,
                                          self.senderNo, self.groupKey);
    DESConversation *gc = [[DESGroupChat alloc] initWithNumber:groupnum onConnection:_connection];
    [_connection addGroup:gc];
}

- (void)decline {
    return;
}

@end

