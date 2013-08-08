#import <Foundation/Foundation.h>
#import <DeepEnd/DeepEnd.h>

@interface NKToxDataWriter : NSObject

/* Initialize with a DES data source. */
- (instancetype)initWithConnection:(DESToxNetworkConnection *)aConnection;

/* Returns YES on success, NO on failure. */
- (BOOL)encodeDataIntoBuffer:(uint8_t **)bufPtr outputLength:(size_t *)bufLen;
- (BOOL)encodeDataIntoEncryptedBuffer:(uint8_t **)bufPtr withPassword:(NSString *)aPass outputLength:(size_t *)bufLen;
@end
