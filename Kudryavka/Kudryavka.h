#import <Foundation/Foundation.h>
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

/*
 * Kudryavka.framework - Storage and retrieval of Poison data.
 * Technically BSD, but you have to link DeepEnd, which is GPLv3.
 * Damn it.
 */

typedef NS_ENUM(NSInteger, NKSerializerType) {
    NKSerializerKeychain,
    NKSerializerCustomFile,
    NKSerializerNoop,
    NKSerializerKeyserver,
};

@interface NKDataSerializer : NSObject

+ (NKDataSerializer *)serializerUsingMethod:(NKSerializerType)method;

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error;

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error;

- (BOOL)hasDataForOptions:(NSDictionary *)aDict;

@end
