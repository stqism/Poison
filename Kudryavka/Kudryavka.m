#import "Kudryavka.h"
#import "crypto_scrypt.h"
#import "scryptenc_cpuperf.h"
#import "memlimit.h"
#import <sodium.h>
#import <DeepEnd/DeepEnd.h>

#define KUDRYAVKA_SALT_LENGTH crypto_secretbox_NONCEBYTES
#define KUDRYAVKA_KEY_LENGTH crypto_secretbox_KEYBYTES
#define LENGTH_CHECK(data, len) if ([data length] < len) { \
                                    NKDebug(@"Data blob is too short. (expected at least %llu bytes, but it was %li bytes)", (uint64_t)len, (long)[data length]); \
                                    return nil; \
                                }

@interface NSDate (TimeZone)
- (NSDate *)toLocalTime;
- (NSDate *)toGlobalTime;
@end

@implementation NSDate (TimeZone)

/* Code from http://agilewarrior.wordpress.com/2012/06/27/how-to-convert-nsdate-to-different-time-zones/ */

- (NSDate *)toLocalTime {
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:self];
    return [NSDate dateWithTimeInterval:seconds sinceDate:self];
}

- (NSDate *)toGlobalTime{
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate:self];
    return [NSDate dateWithTimeInterval:seconds sinceDate:self];
}

@end

@implementation NKDataSerializer

+ (BOOL)isDebugBuild {
    #ifdef KUD_DEBUG
    return YES;
    #else
    return NO;
    #endif
}

- (NSData *)archivedDataWithConnection:(DESToxNetworkConnection *)aConnection {
    uint8_t *buf = NULL;
    size_t len = 0;
    [self encodeDataIntoBuffer:&buf outputLength:&len source:aConnection];
    if (buf)
        return [NSData dataWithBytes:buf length:len];
    else
        return nil;
}

- (NSData *)encryptedDataWithConnection:(DESToxNetworkConnection *)aConnection password:(NSString *)pass {
    return [self encryptedDataWithConnection:aConnection password:pass comment:nil];
}

- (NSData *)encryptedDataWithConnection:(DESToxNetworkConnection *)aConnection password:(NSString *)pass comment:(NSString *)comment {
    /* Compute key using scrypt. */
    uint8_t salt[KUDRYAVKA_SALT_LENGTH];
	int logN = 0;
	uint64_t N = 0;
	uint32_t r = 0;
	uint32_t p = 0;
    randombytes(salt, KUDRYAVKA_SALT_LENGTH);
    NKDebug(@"salt:%@", DESConvertPrivateKeyToString(salt));
	/* Pick values for N, r, p. */
	if (pickparams(0, 0.5, 2.0, &logN, &r, &p) != 0)
		return nil;
	N = (uint64_t)(1) << logN;
    NKDebug(@"%llu, %u, %u", N, r, p);
    const char *passwd = [pass UTF8String];
    size_t pass_sz = [pass lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	/* Generate the derived keys. */
    uint8_t *key = malloc(KUDRYAVKA_KEY_LENGTH);
	if (crypto_scrypt((uint8_t*)passwd, pass_sz, salt, KUDRYAVKA_SALT_LENGTH, N, r, p, key, KUDRYAVKA_KEY_LENGTH)) {
        free(key);
        return nil;
    }
    NKDebug(@"%@", DESConvertPrivateKeyToString(key));
    const char *cc = NULL;
    uint32_t cclen = 0;
    if (comment) {
         cc = [comment UTF8String];
         cclen = (uint32_t)[comment lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    }
    /* Get the cleartext from aConnection */
    uint8_t *buf = NULL;
    size_t len = 0;
    [self encodeDataIntoBuffer:&buf outputLength:&len source:aConnection];
    if (!buf) {
        free(key);
        return nil;
    }
    size_t mlen = crypto_secretbox_ZEROBYTES + len;
    uint8_t *cleartext = calloc(mlen, 1);
    memcpy(cleartext + crypto_secretbox_ZEROBYTES, buf, len);
    size_t eblocklen = 32 + cclen + KUDRYAVKA_SALT_LENGTH + mlen + crypto_auth_BYTES;
    uint8_t *eblock = calloc(eblocklen, 1);
    uint8_t *cp = eblock + 4;
    uint8_t magic1[4] = {0x6B, 0x75, 0x64, 0x6F};
    memcpy(eblock, magic1, 4);
    [self writeInt32:cclen toBuffer:cp];
    cp += 4;
    if (cc)
        memcpy(cp, cc, cclen);
    cp += cclen;
    [self writeInt64:N toBuffer:cp];
    cp += 8;
    [self writeInt32:r toBuffer:cp];
    cp += 4;
    [self writeInt32:p toBuffer:cp];
    cp += 4;
    memcpy(cp, salt, KUDRYAVKA_SALT_LENGTH);
    cp += KUDRYAVKA_SALT_LENGTH;
    [self writeInt64:mlen toBuffer:cp];
    cp += 8;
    int ret = crypto_secretbox(cp, cleartext, mlen, salt, key);
    if (ret == -1) {
        free(cleartext);
        free(buf);
        free(eblock);
        free(key);
        return nil;
    }
    cp += mlen;
    NKDebug(@"%ld", cp - eblock - mlen);
    ret = crypto_auth(cp, cp - mlen, mlen, key);
    NKDebug(@"%i", crypto_auth_verify(cp, cp - mlen, mlen, key));
    NKDebug(@"%@", DESConvertPrivateKeyToString(cp));
    if (ret == -1) {
        free(cleartext);
        free(buf);
        free(eblock);
        free(key);
        return nil;
    }
    NSData *d = [NSData dataWithBytes:eblock length:eblocklen];
    free(cleartext);
    free(buf);
    free(eblock);
    free(key);
    return d;
}

- (BOOL)encodeDataIntoBuffer:(uint8_t **)bufPtr outputLength:(size_t *)bufLen source:(DESToxNetworkConnection *)source {
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
        [self writeInt64:(uint64_t)floor([[[NSDate date] toGlobalTime] timeIntervalSince1970]) toBuffer:selfBlockTimestamp];
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
        [self writeInt64:(uint64_t)floor([[[NSDate date] toGlobalTime] timeIntervalSince1970]) toBuffer:friendBlockTimestamp];
        /* Friend block end */
        if (bufLen)
            NSAssert(offset == *bufLen, @"Block is too large. Rethink size calculation.");
        return YES;
    }
    return YES;
}

- (NSDictionary *)decryptDataBlob:(NSData *)blob withPassword:(NSString *)pass {
    const uint8_t *b = [blob bytes];
    uint8_t *cp = (uint8_t*)b + 4;
    uint8_t magic1[4] = {0x6B, 0x75, 0x64, 0x6F};
    if (memcmp(b, magic1, 4)) {
        NKDebug(@"Data blob failed MAGIC1 check. (expected 0x6B75646F)");
        return nil;
    }
    uint32_t comment_size = [self readInt32FromBuffer:cp];
    cp += 4;
    LENGTH_CHECK(blob, 4 + comment_size);
    if (comment_size) {
        uint8_t *comment = malloc(comment_size);
        memcpy(comment, cp, comment_size);
        NKDebug(@"Comment: %@", [[NSString alloc] initWithBytes:comment length:comment_size encoding:NSUTF8StringEncoding]);
        free(comment);
    }
    cp += comment_size;
    LENGTH_CHECK(blob, 8 + comment_size);
    /* Compute key using scrypt. */
	uint64_t N = [self readInt64FromBuffer:cp];
	uint32_t r = [self readInt32FromBuffer:cp + 8];
	uint32_t p = [self readInt32FromBuffer:cp + 12];
    cp += 16;
    NKDebug(@"%llu, %u, %u", N, r, p);
    LENGTH_CHECK(blob, 24 + comment_size + KUDRYAVKA_SALT_LENGTH);
    uint8_t salt[KUDRYAVKA_SALT_LENGTH];
    memcpy(salt, cp, KUDRYAVKA_SALT_LENGTH);
    cp += KUDRYAVKA_SALT_LENGTH;
    NKDebug(@"salt:%@", DESConvertPrivateKeyToString(salt));
	/* Pick values for N, r, p. */
    const char *passwd = [pass UTF8String];
    size_t pass_sz = [pass lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	/* Generate the derived keys. */
    uint8_t key[KUDRYAVKA_KEY_LENGTH];
	if (crypto_scrypt((uint8_t*)passwd, pass_sz, salt, KUDRYAVKA_SALT_LENGTH, N, r, p, key, KUDRYAVKA_KEY_LENGTH)) {
        return nil;
    }
    NKDebug(@"%@", DESConvertPrivateKeyToString(key));
    LENGTH_CHECK(blob, 32 + KUDRYAVKA_SALT_LENGTH + comment_size);
    uint64_t blocklen = [self readInt64FromBuffer:cp];
    cp += 8;
    LENGTH_CHECK(blob, 32 + comment_size + blocklen + crypto_auth_BYTES);
    NKDebug(@"%ld", cp - b);
    NKDebug(@"blocklen: %lu", (unsigned long)blocklen);
    NKDebug(@"%@", DESConvertPrivateKeyToString(cp + blocklen));
    cp += blocklen;
    int ret = crypto_auth_verify(cp, cp - blocklen, blocklen, key);
    cp -= blocklen;
    //int ret = 0;
    if (ret == -1) {
        NKDebug(@"MAC check failed.");
        return nil;
    } else {
        uint8_t *zero[crypto_secretbox_BOXZEROBYTES] = {0}; /* This creates an array of all zeros */
        if (memcmp(zero, cp, crypto_secretbox_BOXZEROBYTES)) {
            NKDebug(@"Zero check failed.");
            return nil;
        }
        uint8_t *ciphertext = malloc(blocklen);
        memcpy(ciphertext, cp, blocklen);
        uint8_t *cleartext = malloc(crypto_secretbox_ZEROBYTES + blocklen);
        if (crypto_secretbox_open(cleartext, ciphertext, blocklen, salt, key) != 0) {
            free(ciphertext);
            free(cleartext);
            NKDebug(@"crypto_secretbox_open failed.");
            return nil;
        }
        free(ciphertext);
        NSData *clearblob = [NSData dataWithBytes:cleartext + crypto_secretbox_ZEROBYTES length:blocklen];
        free(cleartext);
        return [self unarchiveClearData:clearblob];
    }
}

- (NSDictionary *)unarchiveClearData:(NSData *)blob {
    const uint8_t *b = [blob bytes];
    uint8_t *cp = (uint8_t*)b + 4;
    uint8_t magic2[4] = {0x61, 0x76, 0x6B, 0x61};
    if (memcmp(b, magic2, 4)) {
        NKDebug(@"Data blob failed MAGIC2 check. (expected 0x61766B61)");
        return nil;
    }
    LENGTH_CHECK(blob, 97); /* 4 + 64 + 17 + 12 */
    NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithCapacity:6];
    uint8_t *public = malloc(DESPublicKeySize);
    memcpy(public, cp, DESPublicKeySize);
    cp += DESPublicKeySize;
    uint8_t *private = malloc(DESPrivateKeySize);
    memcpy(private, cp, DESPrivateKeySize);
    cp += DESPrivateKeySize;
    BOOL ok = DESValidateKeyPair(private, public);
    if (!ok) {
        NKDebug(@"Keypair integrity check failed.");
        free(public);
        free(private);
        return nil;
    }
    d[@"publicKey"] = DESConvertPublicKeyToString(public);
    d[@"privateKey"] = DESConvertPrivateKeyToString(private);
    free(public);
    free(private);
    uint64_t timestamp = [self readInt64FromBuffer:cp];
    cp += 8;
    NSDate *selfdate = [[NSDate dateWithTimeIntervalSince1970:timestamp] toLocalTime];
    NKDebug(@"Self block saved date: %@", selfdate);
    d[@"selfBlockSaveTime"] = selfdate;
    uint32_t namelen = [self readInt32FromBuffer:cp];
    if (namelen == 0) {
        NKDebug(@"Failed status length check > 0.");
        return nil;
    }
    cp += 4;
    LENGTH_CHECK(blob, 97 + namelen);
    NSString *name = [[NSString alloc] initWithBytes:cp length:namelen - 1 encoding:NSUTF8StringEncoding];
    cp += namelen;
    NKDebug(@"Self name: %@", name);
    d[@"displayName"] = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    uint32_t statuslen = [self readInt32FromBuffer:cp];
    if (statuslen == 0) {
        NKDebug(@"Failed status length check > 0.");
        return nil;
    }
    uint8_t statustype = cp[4];
    cp += 5;
    LENGTH_CHECK(blob, 97 + namelen + statuslen);
    NSString *status = [[NSString alloc] initWithBytes:cp length:statuslen - 1 encoding:NSUTF8StringEncoding];
    NKDebug(@"Self status: %@", status);
    d[@"userStatus"] = [status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    d[@"statusType"] = @(statustype);
    cp += statuslen;
    /* Begin friend block */
    timestamp = [self readInt64FromBuffer:cp];
    cp += 8;
    NSDate *frienddate = [[NSDate dateWithTimeIntervalSince1970:timestamp] toLocalTime];
    NKDebug(@"Friend block saved date: %@", frienddate);
    d[@"friendBlockSaveTime"] = frienddate;
    uint32_t friendcount = [self readInt32FromBuffer:cp];
    cp += 4;
    NKDebug(@"Friend count: %u", friendcount);
    if (!friendcount) {
        d[@"friends"] = @[];
        return d;
    }
    LENGTH_CHECK(blob, 97 + namelen + statuslen + ((DESPublicKeySize + 4) * friendcount));
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    uint64_t combinednlen = 0;
    for (int i = 0; i < friendcount; ++i) {
        NSMutableDictionary *fr = [[NSMutableDictionary alloc] initWithCapacity:2];
        fr[@"publicKey"] = DESConvertPublicKeyToString(cp);
        cp += 32;
        uint32_t nl = [self readInt32FromBuffer:cp];
        if (nl == 0) {
            NKDebug(@"Failed friend name length check > 0.");
            return nil;
        }
        combinednlen += nl;
        LENGTH_CHECK(blob, 97 + namelen + statuslen + ((DESPublicKeySize + 4) * friendcount) + combinednlen);
        fr[@"displayName"] = [[NSString alloc] initWithBytes:cp + 4 length:nl encoding:NSUTF8StringEncoding];
        cp += 4 + nl;
        [friends addObject:fr];
    }
    d[@"friends"] = friends;
    return d;
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

- (uint32_t)readInt32FromBuffer:(const uint8_t *)buf {
    return (((uint32_t)buf[0] << 24) + ((uint32_t)buf[1] << 16) + ((uint32_t)buf[2] << 8) +
            (uint32_t)buf[3]);
}

- (uint64_t)readInt64FromBuffer:(const uint8_t *)buf {
    return (((uint64_t)buf[0] << 56) + ((uint64_t)buf[1] << 48) + ((uint64_t)buf[2] << 40) +
            ((uint64_t)buf[3] << 32) + ((uint64_t)buf[4] << 24) + ((uint64_t)buf[5] << 16) +
            ((uint64_t)buf[6] << 8) + (uint64_t)buf[7]);
}

static int
pickparams(size_t maxmem, double maxmemfrac, double maxtime,
           int * logN, uint32_t * r, uint32_t * p)
{
	size_t memlimit;
	double opps;
	double opslimit;
	double maxN, maxrp;
	int rc;
    
	/* Figure out how much memory to use. */
	if (memtouse(maxmem, maxmemfrac, &memlimit))
		return (1);
    
	/* Figure out how fast the CPU is. */
	if ((rc = scryptenc_cpuperf(&opps)) != 0)
		return (rc);
	opslimit = opps * maxtime;
    
	/* Allow a minimum of 2^15 salsa20/8 cores. */
	if (opslimit < 32768)
		opslimit = 32768;
    
	/* Fix r = 8 for now. */
	*r = 8;
    
	/*
	 * The memory limit requires that 128Nr <= memlimit, while the CPU
	 * limit requires that 4Nrp <= opslimit.  If opslimit < memlimit/32,
	 * opslimit imposes the stronger limit on N.
	 */
#ifdef DEBUG
	fprintf(stderr, "Requiring 128Nr <= %zu, 4Nrp <= %f\n",
            memlimit, opslimit);
#endif
	if (opslimit < memlimit/32) {
		/* Set p = 1 and choose N based on the CPU limit. */
		*p = 1;
		maxN = opslimit / (*r * 4);
		for (*logN = 1; *logN < 63; *logN += 1) {
			if ((uint64_t)(1) << *logN > maxN / 2)
				break;
		}
	} else {
		/* Set N based on the memory limit. */
		maxN = memlimit / (*r * 128);
		for (*logN = 1; *logN < 63; *logN += 1) {
			if ((uint64_t)(1) << *logN > maxN / 2)
				break;
		}
        
		/* Choose p based on the CPU limit. */
		maxrp = (opslimit / 4) / ((uint64_t)(1) << *logN);
		if (maxrp > 0x3fffffff)
			maxrp = 0x3fffffff;
		*p = (uint32_t)(maxrp) / *r;
	}
    
#ifdef DEBUG
	fprintf(stderr, "N = %zu r = %d p = %d\n",
            (size_t)(1) << *logN, (int)(*r), (int)(*p));
#endif
    
	/* Success! */
	return (0);
}

@end