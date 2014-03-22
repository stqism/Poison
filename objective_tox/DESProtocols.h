#ifndef DESProtocols_h
#define DESProtocols_h
#import "DESConstants.h"

@class DESToxConnection, DESConversation, DESFriend;

@protocol DESConversationDelegate <NSObject>
@optional
- (void)conversation:(DESConversation *)con
   didReceiveMessage:(NSString *)message
              ofType:(DESMessageType)type_
          fromSender:(DESFriend *)sender;

- (void)conversation:(DESConversation *)con
        didFailToSendMessageWithID:(uint32_t)messageID
              ofType:(DESMessageType)type_;

- (void)conversation:(DESConversation *)con
        didReceiveDeliveryNotificationForMessageID:(uint32_t)messageID;

@end

@protocol DESConversation <NSObject>
@property (readonly) NSString *presentableTitle;
@property (readonly) NSString *presentableSubtitle;
@property (readonly) NSSet *participants;
@property (readonly) NSString *publicKey;
@property (readonly) int32_t peerNumber;
@property (weak) id<DESConversationDelegate> delegate;

- (uint32_t)sendMessage:(NSString *)message;
- (uint32_t)sendAction:(NSString *)action;
@end

@protocol DESFriend <NSObject>
@property (readonly) NSString *name;
@property (readonly) NSString *statusMessage;
@property (readonly) NSString *publicKey;
@property (readonly) DESConversation *conversation;
@property (readonly) DESToxConnection *connection;
@property (readonly) int32_t peerNumber;
@property (readonly) BOOL isTyping;
@end

#endif
