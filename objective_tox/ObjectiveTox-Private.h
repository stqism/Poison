#import "ObjectiveTox.h"
#import "DESMacros.h"

#pragma mark - DESToxConnection internal API

@interface DESToxConnection ()
- (Tox *)_core;
- (dispatch_queue_t)_messengerQueue;
- (void)addGroup:(id<DESConversation>)conversation;
@end

#pragma mark - Callbacks

void _DESCallbackFriendRequest(Tox *tox, uint8_t *from, uint8_t *payload, uint16_t payloadLength, void *dtcInstance);

#pragma mark - DESRequest concrete subclasses

@interface DESFriendRequest : DESRequest
@property uint8_t *senderPublicKey;

- (instancetype)initWithSenderKey:(const uint8_t *)sender
                          message:(const uint8_t *)message
                           length:(uint32_t)length
                       connection:(DESToxConnection *)connection;

@end

@interface DESGroupRequest : DESRequest
@property int32_t senderNo;
@property uint8_t *groupKey;

- (instancetype)initWithSenderNo:(int32_t)sender
                            name:(NSString *)name
                        groupKey:(const uint8_t *)key
                      connection:(DESToxConnection *)connection;

@end

#pragma mark - DESFriend concrete subclasses

@interface DESConcreteFriend : DESFriend

- (instancetype)initWithNumber:(int32_t)friendNum
                  onConnection:(DESToxConnection *)connection;

@end

@interface DESGroupChat : DESConversation

- (instancetype)initWithNumber:(int32_t)groupNum
                  onConnection:(DESToxConnection *)connection;

@end

@interface DESSelf : DESFriend

- (instancetype)initWithConnection:(DESToxConnection *)connection;

@end

#pragma mark - Extensions to Core

int DESCountCloseNodes(Tox *tox);