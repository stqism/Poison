#import <Foundation/Foundation.h>
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#ifdef KUD_DEBUG
#define NKDebug(fmt, ...) NSLog(@"[Kudryavka] in %s, line %i: " fmt, __func__, __LINE__, ##__VA_ARGS__)
#else
#define NKDebug(fmt, ...)
#endif

/*
 * Kudryavka.framework - Storage and retrieval of Poison data.
 * Technically BSD, but you have to link DeepEnd, which is GPLv3.
 * Damn it.
 */

@class DESToxNetworkConnection;
@interface NKDataSerializer : NSObject

+ (BOOL)isDebugBuild;
- (NSData *)archivedDataWithConnection:(DESToxNetworkConnection *)aConnection;
- (NSData *)encryptedDataWithConnection:(DESToxNetworkConnection *)aConnection password:(NSString *)pass;
- (NSData *)encryptedDataWithConnection:(DESToxNetworkConnection *)aConnection password:(NSString *)pass comment:(NSString *)comment;

- (NSData *)encryptedBlobWithData:(NSData *)data password:(NSString *)pass;
- (NSData *)encryptedBlobWithData:(NSData *)data password:(NSString *)pass comment:(NSString *)comment;

- (NSData *)decryptedDataFromBlob:(NSData *)blob password:(NSString *)pass;
- (NSDictionary *)decryptDataBlob:(NSData *)blob withPassword:(NSString *)pass;
- (NSDictionary *)unarchiveClearData:(NSData *)blob;

- (NSString *)fileCommentFromBlob:(NSData *)blob;

@end
