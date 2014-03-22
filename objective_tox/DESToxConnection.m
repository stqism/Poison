//
//  DESToxConnection.m
//  Poison
//
//  Created by stal on 22/2/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import "DESMacros.h"
#import "ObjectiveTox-Private.h"
#import "tox.h"
#import "Messenger.h"

NSString *const DESDefaultNickname = @"Toxicle";
NSString *const DESDefaultStatusMessage = @"Toxing on Tox";

@interface DESToxConnection ()
@property dispatch_queue_t messengerQueue;
@property BOOL isMessengerLoopStopping;

@property Tox *tox;
@property uint8_t *toxWaitData; /* The required data length of tox_wait. */
@property uint16_t toxWaitReqSize; /* These variables are saved so we don't realloc every loop iteration. */
@end

@implementation DESToxConnection {
    NSMutableDictionary *_groupMapping;
    NSMutableDictionary *_friendMapping;
}

- (instancetype)init {
    if (self = [super init]) {
        self.messengerQueue = dispatch_queue_create("ca.kirara.DES2RunLoop", DISPATCH_QUEUE_CONCURRENT);
        self.tox = tox_new(1);
        _friendMapping = [[NSMutableDictionary alloc] init];
        _groupMapping = [[NSMutableDictionary alloc] init];
        self.name = DESDefaultNickname;
        self.statusMessage = DESDefaultStatusMessage;
        tox_callback_friend_request(self.tox, _DESCallbackFriendRequest, (__bridge void*)self);
    }
    return self;
}

- (Tox *)_core {
    return self.tox;
}

- (dispatch_queue_t)_messengerQueue {
    return self.messengerQueue;
}

#pragma mark - Run loop

- (void)start {
    uint8_t *kek = malloc(TOX_FRIEND_ADDRESS_SIZE);
    tox_get_address(self.tox, kek);
    DESInfo(@"Our public key: %@", DESConvertPublicKeyToString(kek));
    free(kek);
    self.isMessengerLoopStopping = NO;
    dispatch_async(self.messengerQueue, ^{
        [self _desRunLoopRun];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(connectionDidInitialize:)])
                [self.delegate connectionDidInitialize:self];
        });
    });
}

- (void)_desRunLoopRun {
    if (!self.toxWaitData)
        self.toxWaitData = malloc(tox_wait_data_size());
    tox_wait_prepare(self.tox, self.toxWaitData);
    tox_wait_execute(self.toxWaitData, 1, 1);
    tox_wait_cleanup(self.tox, self.toxWaitData);
    tox_do(self.tox);
    BOOL willNotifyIfNodeCountChanges = (self.closeNodesCount == 0)? YES : NO;
    self.closeNodesCount = DESCountCloseNodes(self.tox);
    if (self.closeNodesCount > 0 && willNotifyIfNodeCountChanges
        && [self.delegate respondsToSelector:@selector(connectionDidBecomeEstablished:)])
        [self.delegate connectionDidBecomeEstablished:self];
    if (!self.isMessengerLoopStopping) {
        dispatch_async(self.messengerQueue, ^{
            [self _desRunLoopRun];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(connectionDidDisconnect:)])
                [self.delegate connectionDidDisconnect:self];
        });
    }
}

- (void)stop {
    self.isMessengerLoopStopping = YES;
    DESInfo(@"Stopping messenger loop.");
}

#pragma mark - Bootstrapping

- (void)setCloseNodesCount:(NSUInteger)closeNodesCount {
    if (_closeNodesCount == closeNodesCount)
        return;
    [self willChangeValueForKey:@"closeNodesCount"];
    _closeNodesCount = closeNodesCount;
    DESInfo(@"New node count: %lu", (unsigned long)_closeNodesCount);
    [self didChangeValueForKey:@"closeNodesCount"];
}

- (void)bootstrapWithServerAddress:(NSString *)addr
                              port:(uint16_t)port
                         publicKey:(NSString *)pubKey {
    dispatch_async(self.messengerQueue, ^{
        uint8_t *keyBytes = malloc(DESPublicKeySize);
        DESConvertPublicKeyToData(pubKey, keyBytes);
        tox_bootstrap_from_address(self.tox, [addr UTF8String], YES, port, keyBytes);
        free(keyBytes);
    });
}

#pragma mark - Self

- (DESFriend *)me {
    return (DESFriend*)self;
}

- (NSString *)name {
    uint32_t name_size = tox_get_self_name_size(self.tox);
    uint8_t *buf = malloc(name_size);
    tox_get_self_name(self.tox, buf);
    return [[NSString alloc] initWithBytesNoCopy:buf length:name_size encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

- (void)setName:(NSString *)name {
    [self willChangeValueForKey:@"name"];
    tox_set_name(self.tox, (uint8_t*)[name UTF8String],
                 (uint16_t)[name lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    [self didChangeValueForKey:@"name"];
}

- (NSString *)statusMessage {
    uint32_t smsg_size = tox_get_self_status_message_size(self.tox);
    uint8_t *buf = malloc(smsg_size);
    tox_get_self_status_message(self.tox, buf, smsg_size);
    return [[NSString alloc] initWithBytesNoCopy:buf length:smsg_size encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

- (void)setStatusMessage:(NSString *)statusMessage {
    [self willChangeValueForKey:@"statusMessage"];
    tox_set_status_message(self.tox, (uint8_t*)[statusMessage UTF8String],
                           (uint16_t)[statusMessage lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    [self didChangeValueForKey:@"statusMessage"];
}

- (NSString *)publicKey {
    // uint8_t *buf = malloc(DESPublicKeySize);
    /* TODO: Fix usage of private API */
    //tox_get_self_keys(self.tox, buf, NULL);
    Messenger *private = (Messenger*)self.tox;
    NSString *ret = DESConvertPublicKeyToString(private->net_crypto->self_public_key);
    //free(buf);
    return ret;
}

- (NSString *)privateKey {
    //uint8_t *buf = malloc(DESPrivateKeySize);
    /* TODO: Fix usage of private API */
    //tox_get_self_keys(self.tox, NULL, buf);
    Messenger *private = (Messenger*)self.tox;
    NSString *ret = DESConvertPublicKeyToString(private->net_crypto->self_secret_key);
    //NSString *ret = DESConvertPrivateKeyToString(buf);
    //free(buf);
    return ret;
}

- (NSString *)friendAddress {
    uint8_t *buf = malloc(DESFriendAddressSize);
    tox_get_address(self.tox, buf);
    NSString *ret = DESConvertFriendAddressToString(buf);
    free(buf);
    return ret;
}

- (void)setPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey {
    uint8_t *keys = malloc(DESPublicKeySize + DESPrivateKeySize);
    DESConvertPublicKeyToData(publicKey, keys);
    DESConvertPrivateKeyToData(privateKey, keys + DESPublicKeySize);
    if (DESKeyPairIsValid(keys, keys + DESPublicKeySize)) {
        [self willChangeValueForKey:@"publicKey"];
        [self willChangeValueForKey:@"privateKey"];
        [self willChangeValueForKey:@"friendAddress"];
        //tox_set_self_keys(self.tox, keys, keys + DESPublicKeySize);
        [self didChangeValueForKey:@"friendAddress"];
        [self didChangeValueForKey:@"privateKey"];
        [self didChangeValueForKey:@"publicKey"];
    } else {
        DESWarn(@"You tried to set keys that were not valid. Public: %@ Private %@", publicKey, privateKey);
    }
    free(keys);
}

- (DESConversation *)conversation {
    return nil;
}

- (DESToxConnection *)connection {
    return self;
}

- (int32_t)peerNumber {
    return -1;
}

- (BOOL)isTyping {
    return NO;
}

#pragma mark - Friends

- (void)addFriendPublicKey:(NSString *)key message:(NSString *)message {
    dispatch_async(self.messengerQueue, ^{
        uint8_t *keyBytes = malloc(DESPublicKeySize);
        DESConvertPublicKeyToData(key, keyBytes);
        int32_t friendnum = tox_add_friend(self.tox, keyBytes, (uint8_t*)[message UTF8String],
                       [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        free(keyBytes);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addFriendTriggeringKVO:friendnum];
        });
    });
}

- (void)addFriendPublicKeyWithoutRequest:(NSString *)key {
    dispatch_async(self.messengerQueue, ^{
        uint8_t *keyBytes = malloc(DESPublicKeySize);
        DESConvertPublicKeyToData(key, keyBytes);
        int32_t friendnum = tox_add_friend_norequest(self.tox, keyBytes);
        free(keyBytes);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addFriendTriggeringKVO:friendnum];
        });
    });
}

- (void)addGroup:(id<DESConversation>)conversation {
    NSSet *changeSet = [NSSet setWithObject:conversation];
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changeSet];
    _groupMapping[@(conversation.peerNumber)] = conversation;
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changeSet];
    if ([self.delegate respondsToSelector:@selector(didJoinGroupChat:onConnection:)])
        [self.delegate didJoinGroupChat:conversation onConnection:self];
}

- (void)addFriendTriggeringKVO:(int32_t)friendnum {
    DESFriend *friend = [[DESConcreteFriend alloc] initWithNumber:friendnum onConnection:self];
    NSSet *changeSet = [NSSet setWithObject:friend];
    [self willChangeValueForKey:@"friends" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changeSet];
    _friendMapping[@(friendnum)] = friend;
    [self didChangeValueForKey:@"friends" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changeSet];
    if ([self.delegate respondsToSelector:@selector(didAddFriend:onConnection:)])
        [self.delegate didAddFriend:friend onConnection:self];
}

- (id<DESConversation>)groupChatWithID:(int32_t)num {
    return _groupMapping[@(num)];
}

- (id<DESFriend>)friendWithID:(int32_t)num {
    return _friendMapping[@(num)];
}

- (void)leaveGroup:(id<DESConversation>)group {
    if (!tox_del_groupchat(self.tox, group.peerNumber)) {
        NSSet *changeSet = [NSSet setWithObject:group];
        [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changeSet];
        [_groupMapping removeObjectForKey:@(group.peerNumber)];
        [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changeSet];
    } else {
        DESWarn(@"group chat %d is not valid", group.peerNumber);
    }
}

- (void)deleteFriend:(id<DESFriend>)friend {
    if (!tox_del_friend(self.tox, friend.peerNumber)) {
        NSSet *changeSet = [NSSet setWithObject:friend];
        [self willChangeValueForKey:@"friends" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changeSet];
        [_friendMapping removeObjectForKey:@(friend.peerNumber)];
        [self didChangeValueForKey:@"friends" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changeSet];
    } else {
        DESWarn(@"friend %d is not valid", friend.peerNumber);
    }
}

- (NSSet *)friends {
    return [NSSet setWithArray:[_friendMapping allValues]];
}

- (NSSet *)groups {
    return [NSSet setWithArray:[_groupMapping allValues]];
}

#pragma mark - TXD

- (txd_intermediate_t)createTXDIntermediate {
    txd_intermediate_t txd = txd_intermediate_from_tox(self.tox);
    return txd;
}

- (void)restoreDataFromTXDIntermediate:(txd_intermediate_t)txd {
    if (txd)
        txd_restore_intermediate(txd, self.tox);
}

- (void)dealloc {
    if (self.tox)
        tox_kill(self.tox);
    if (self.toxWaitData)
        free(self.toxWaitData);
    dispatch_release(self.messengerQueue);
    DESInfo(@"deallocated!");
}

@end
