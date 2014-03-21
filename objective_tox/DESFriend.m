//
//  DESConcreteFriend.m
//  ObjectiveTox
//
//  Created by stal on 4/3/2014.
//  Copyright (c) 2014 Tox. All rights reserved.
//

#import "ObjectiveTox-Private.h"

const uint32_t DESMaximumMessageLength = 1024;

@implementation DESFriend
- (NSString *)name { DESAbstractWarning; return nil; }
- (NSString *)statusMessage { DESAbstractWarning; return nil; }
- (NSString *)publicKey { DESAbstractWarning; return nil; }
- (DESConversation *)conversation { DESAbstractWarning; return nil; }
- (DESToxConnection *)connection { DESAbstractWarning; return nil; }
- (int32_t)peerNumber { DESAbstractWarning; return -1; }
- (BOOL)isTyping { DESAbstractWarning; return -1; }

- (NSString *)presentableTitle { DESAbstractWarning; return nil; }
- (NSString *)presentableSubtitle { DESAbstractWarning; return nil; }
- (NSSet *)participants { DESAbstractWarning; return nil; }
- (id<DESConversationDelegate>)delegate { DESAbstractWarning; return nil; }
- (void)setDelegate:(id<DESConversationDelegate>)delegate { DESAbstractWarning; }

- (uint32_t)sendAction:(NSString *)action { DESAbstractWarning; return 0; }
- (uint32_t)sendMessage:(NSString *)message { DESAbstractWarning; return 0; }
@end

@implementation DESConcreteFriend {
    uint32_t _cMessageID;
}
@synthesize connection = _connection;
@synthesize peerNumber = _peerNumber;

- (instancetype)initWithNumber:(int32_t)friendNum
                  onConnection:(DESToxConnection *)connection {
    self = [super init];
    if (self) {
        _connection = connection;
        _peerNumber = friendNum;
        _cMessageID = 1;
    }
    return self;
}

- (NSString *)name {
    /* uint16_t sz = tox_get_name_size(_connection._core, _peerNumber); */
    uint16_t sz = TOX_MAX_NAME_LENGTH;
    uint8_t *buf = calloc(sz, 1);
    tox_get_name(_connection._core, _peerNumber, buf);
    return [[NSString alloc] initWithBytesNoCopy:buf length:strlen((char*)buf) encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

- (NSString *)statusMessage {
    uint16_t sz = tox_get_status_message_size(_connection._core, _peerNumber);
    uint8_t *buf = malloc(sz);
    tox_get_status_message(_connection._core, _peerNumber, buf, sz);
    return [[NSString alloc] initWithBytesNoCopy:buf length:sz encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

- (NSString *)publicKey {
    uint8_t *buf = malloc(DESPublicKeySize);
    tox_get_client_id(_connection._core, _peerNumber, buf);
    return DESConvertPublicKeyToString(buf);
}

- (DESConversation *)conversation {
    return (DESConversation*)self;
}

- (BOOL)isTyping {
    return tox_get_is_typing(_connection._core, _peerNumber)? YES : NO;
}

#pragma mark - DESConversation

- (NSString *)presentableTitle {
    return self.name;
}

- (NSString *)presentableSubtitle {
    return self.statusMessage;
}

- (NSSet *)participants {
    return [[NSSet alloc] initWithObjects:self, nil];
}

- (uint32_t)sendMessage:(NSString *)message {
    uint32_t mid = ++_cMessageID;
    dispatch_async(_connection._messengerQueue, ^{
        NSUInteger mlen = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        uint32_t ret = 0;
        if (mlen <= DESMaximumMessageLength) {
            ret = tox_send_message_withid(_connection._core, _peerNumber, mid, (uint8_t*)[message UTF8String], (uint32_t)mlen);
        }
        if (ret == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(conversation:didFailToSendMessageWithID:ofType:)])
                    [self.delegate conversation:(DESConversation*)self didFailToSendMessageWithID:mid ofType:DESMessageTypeText];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(conversation:didReceiveMessage:ofType:fromSender:)])
                [self.delegate conversation:(DESConversation*)self didReceiveMessage:message ofType:DESMessageTypeText fromSender:_connection.me];
        });
    });
    return mid;
}

- (uint32_t)sendAction:(NSString *)action {
    uint32_t mid = ++_cMessageID;
    dispatch_async(_connection._messengerQueue, ^{
        NSUInteger mlen = [action lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        uint32_t ret = 0;
        if (mlen <= DESMaximumMessageLength) {
            ret = tox_send_action_withid(_connection._core, _peerNumber, mid, (uint8_t*)[action UTF8String], (uint32_t)mlen);
        }
        if (ret == 0 || mlen > DESMaximumMessageLength) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(conversation:didFailToSendMessageWithID:ofType:)])
                    [self.delegate conversation:(DESConversation*)self didFailToSendMessageWithID:mid ofType:DESMessageTypeAction];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(conversation:didReceiveMessage:ofType:fromSender:)])
                [self.delegate conversation:(DESConversation*)self didReceiveMessage:action ofType:DESMessageTypeAction fromSender:_connection.me];
        });
    });
    return mid;
}

@end
