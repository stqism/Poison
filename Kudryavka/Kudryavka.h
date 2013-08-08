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

typedef NS_ENUM(NSInteger, NKSerializerType) {
    NKSerializerKeychain,
    NKSerializerCustomFile,
    NKSerializerNoop,
    NKSerializerKeyserver,
};

@interface NKDataSerializer : NSObject

+ (NKDataSerializer *)serializerUsingMethod:(NKSerializerType)method;
+ (BOOL)isDebugBuild;

- (BOOL)serializePrivateKey:(NSString *)thePrivateKey publicKey:(NSString *)thePublicKey options:(NSDictionary *)aDict error:(NSError **)error;

- (NSDictionary *)loadKeysWithOptions:(NSDictionary *)aDict error:(NSError **)error;

- (BOOL)hasDataForOptions:(NSDictionary *)aDict;

@end
