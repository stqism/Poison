#import "Kudryavka.h"
#import "NKToxDataWriter.h"
#import "scryptenc.h"

@implementation NKToxDataWriter {
    DESToxNetworkConnection *source;
}

- (instancetype)initWithConnection:(DESToxNetworkConnection *)aConnection {
    self = [super init];
    if (self) {
        source = aConnection;
    }
    return self;
}

- (BOOL)encodeDataIntoEncryptedBuffer:(uint8_t **)bufPtr withPassword:(NSString *)aPass outputLength:(size_t *)bufLen {
    uint8_t *clearText = NULL;
    size_t srcSize = 0;
    BOOL success = [self encodeDataIntoBuffer:&clearText outputLength:&srcSize];
    if (!success)
        return NO;
    size_t passLen = [aPass lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    uint8_t *encrypted = calloc(12 + srcSize + 128, 1);
    /* Prepare the header. */
    uint8_t magic1[4] = {0x6B, 0x75, 0x64, 0x6F};
    memcpy(encrypted, magic1, 4);
    uint64_t eblocksize = srcSize + 128;
    [self writeInt64:eblocksize toBuffer:encrypted + 4];
    /* End header */
    uint8_t *password = calloc(passLen, 1);
    memcpy(password, [aPass UTF8String], passLen);
    int fail = scryptenc_buf(clearText, srcSize, encrypted + 12, password, passLen, 0, 0.5, 2.0);
    memset(password, 0, passLen);
    free(password);
    memset(clearText, 0, srcSize); /* quick, erase it before it's picked up by the NSA pooper-scooper! */
    free(clearText);
    if (!fail) {
        if (bufPtr) {
            *bufPtr = encrypted;
        } else {
            memset(encrypted, 0, 12 + srcSize + 128);
            free(encrypted);
        }
        if (bufLen)
            *bufLen = 12 + srcSize + 128;
        return YES;
    } else {
        memset(encrypted, 0, 12 + srcSize + 128);
        free(encrypted);
        NKDebug(@"scrypt failed with result: %d", fail);
        return NO;
    }
}

- (BOOL)encodeDataIntoBuffer:(uint8_t **)bufPtr outputLength:(size_t *)bufLen {
    size_t bBlockSize = 4 + DESPublicKeySize + DESPrivateKeySize;
    /* The size of the base block (before encryption). MAGIC2 + size of public and private keys. */
    size_t sBlockSize = 17;
    /* The size of SELFDATA before applying string lengths.
     * Count a NUL too because NSStrings don't have them. */
    sBlockSize += source.me.displayName.length + source.me.userStatus.length + 2;
    /* Add our strings. */
    size_t fBlockSize = 12;
    NSArray *friendArray = [source.friendManager.friends copy];
    for (DESFriend *theFriend in friendArray) {
        /* Again, count our NULs. */
        fBlockSize += DESPublicKeySize + theFriend.displayName.length + 5;
    }
    if (bufLen)
        *bufLen = (bBlockSize + sBlockSize + fBlockSize);
        /* Total size goes in here. */
    if (bufPtr) {
        size_t offset = 0;
        uint8_t *localBlock = calloc(bBlockSize + sBlockSize + fBlockSize, 1);
        *bufPtr = localBlock;
        /* Base block begin */
        /* The second magic number. */
        uint8_t magic2[4] = {0x61, 0x76, 0x6B, 0x61};
        memcpy(localBlock, magic2, 4);
        offset = 4;
        DESConvertPublicKeyToData(source.me.publicKey, localBlock + offset);
        offset += DESPublicKeySize;
        DESConvertPrivateKeyToData(source.me.privateKey, localBlock + offset);
        offset += DESPrivateKeySize;
        /* Base block done */
        /* Self block begin */
        uint8_t *selfBlockTimestamp = localBlock + offset;
        offset += 8;
        uint32_t nickLength = (uint32_t)[source.me.displayName lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
        /* Write nickname */
        [self writeInt32:nickLength toBuffer:localBlock + offset];
        offset += 4;
        memcpy(localBlock + offset, [source.me.displayName UTF8String], nickLength);
        offset += nickLength;
        /* Write status */
        uint32_t statusLength = (uint32_t)[source.me.userStatus lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
        [self writeInt32:statusLength toBuffer:localBlock + offset];
        offset += 4;
        localBlock[offset] = (uint8_t)source.me.statusType;
        memcpy(localBlock + offset + 1, [source.me.userStatus UTF8String], statusLength);
        offset += statusLength + 1;
        [self writeInt64:(uint64_t)floor([[NSDate date] timeIntervalSince1970]) toBuffer:selfBlockTimestamp];
        /* Self block done */
        /* Friend block begin */
        uint8_t *friendBlockTimestamp = localBlock + offset;
        offset += 8;
        [self writeInt32:(uint32_t)[friendArray count] toBuffer:localBlock + offset];
        offset += 4;
        for (DESFriend *theFriend in friendArray) {
            DESConvertPublicKeyToData(theFriend.publicKey, localBlock + offset);
            offset += DESPublicKeySize;
            uint32_t nl = (uint32_t)[theFriend.displayName lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
            /* Write nickname */
            [self writeInt32:nl toBuffer:localBlock + offset];
            offset += 4;
            memcpy(localBlock + offset, [theFriend.displayName UTF8String], nl);
            offset += nl;
        }
        [self writeInt64:(uint64_t)floor([[NSDate date] timeIntervalSince1970]) toBuffer:friendBlockTimestamp];
        /* Friend block end */
        if (bufLen)
            NSAssert(offset == *bufLen, @"Block is too large. Rethink size calculation.");
        return YES;
    }
    return YES;
}

- (void)writeInt32:(uint32_t)theInt toBuffer:(uint8_t *)buf {
    /* This could probably be done better. */
    buf[0] = theInt >> 24;
    buf[1] = theInt >> 16;
    buf[2] = theInt >> 8;
    buf[3] = theInt;
}

- (void)writeInt64:(uint64_t)theInt toBuffer:(uint8_t *)buf {
    /* This could probably be done better. */
    buf[0] = theInt >> 56;
    buf[1] = theInt >> 48;
    buf[2] = theInt >> 40;
    buf[3] = theInt >> 32;
    buf[4] = theInt >> 24;
    buf[5] = theInt >> 16;
    buf[6] = theInt >> 8;
    buf[7] = theInt;
}

@end
