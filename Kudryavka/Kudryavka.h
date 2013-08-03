#import <Foundation/Foundation.h>
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

/*
 * Q: What is this?
 * A: This is a self-contained framework solely for serializing keys in different
 *    ways.
 * Q: Why?
 * A: To make it easier to re-use.
 * Q: Why doesn't this have a descriptive name?
 * A: Where's the fun in that?
 */

typedef NS_ENUM(NSInteger, NKSerializerType) {
    NKSerializerKeychain,
    NKSerializerCustomFile,
    NKSerializerNoop,
};

@interface NKDataSerializer : NSObject

+ (NKDataSerializer *)serializerUsingMethod:(NKSerializerType)method;

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error;

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error;

@end
