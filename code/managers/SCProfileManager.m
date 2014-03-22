#import "SCProfileManager.h"
#import "data_private.h"
#import "txdplus.h"

NSError *SCLocalizedErrorWithTXDReturnValue(uint32_t retv) {
    NSDictionary *userInfo = nil;
    if (retv == TXD_ERR_BAD_BLOCK || retv == TXD_ERR_SIZE_MISMATCH) {
        userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Profile data is corrupt.", nil),
                     NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Your profile could not be loaded because the data was corrupt.", nil)};
    } else if (retv == TXD_ERR_DECRYPT_FAILED) {
        userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Password incorrect.", nil),
                     NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Your profile could not be loaded because you entered the wrong password.", nil)};
    }
    return [NSError errorWithDomain:@"TXDErrorDomain" code:retv userInfo:userInfo];
}

@implementation SCProfileManager

+ (NSDictionary *)manifest {
    static NSDictionary *manifest = nil;
    static NSDate *modtime = nil;
    NSURL *manifestURL = [self.profileDirectory URLByAppendingPathComponent:@"Manifest.plist" isDirectory:NO];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attrs = [fileManager attributesOfItemAtPath:manifestURL.path error:nil];
    if (!attrs || ![attrs.fileModificationDate isEqualToDate:modtime]) {
        manifest = [NSDictionary dictionaryWithContentsOfURL:manifestURL];
        modtime = attrs.fileModificationDate;
        NSLog(@"note: had to re-read the manifest due to first access; or the modification time changed");
    }
    return manifest;
}

+ (NSURL *)profileDirectory {
    NSURL *profiles = [SCApplicationSupportDirectory() URLByAppendingPathComponent:@"Profiles" isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[profiles path]]) {
        [fileManager createDirectoryAtURL:profiles withIntermediateDirectories:YES attributes:nil error:nil];
        [@{} writeToURL:[profiles URLByAppendingPathComponent:@"Manifest.plist" isDirectory:NO] atomically:YES];
    }
    return profiles;
}

+ (BOOL)profileNameExists:(NSString *)aProfile {
    if (!aProfile)
        return NO;
    if (self.manifest[aProfile]) {
        NSURL *pdirURL = [self.profileDirectory URLByAppendingPathComponent:self.manifest[aProfile]];
        BOOL is_d = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[pdirURL URLByAppendingPathComponent:@"data.txd"].path isDirectory:&is_d] && !is_d)
            return YES;
    }
    return NO;
}

+ (BOOL)deleteProfileName:(NSString *)aProfile {
    if (![self profileNameExists:aProfile])
        return YES;
    NSURL *manifestURL = [[self profileDirectory] URLByAppendingPathComponent:@"Manifest.plist" isDirectory:NO];
    NSMutableDictionary *manifest = [NSMutableDictionary dictionaryWithContentsOfURL:manifestURL];
    NSURL *profileDataURL = [[self profileDirectory] URLByAppendingPathComponent:manifest[aProfile] isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager removeItemAtPath:[profileDataURL path] error:&error];
    if (error) {
        return NO;
    }
    [manifest removeObjectForKey:aProfile];
    [manifest writeToURL:manifestURL atomically:YES];
    return YES;
}

+ (txd_intermediate_t)attemptDecryptionOfProfileName:(NSString *)aProfile password:(NSString *)password error:(NSError **)err {
    NSURL *profiles = [self profileDirectory];
    NSMutableDictionary *manifest = [NSMutableDictionary dictionaryWithContentsOfURL:[profiles URLByAppendingPathComponent:@"Manifest.plist" isDirectory:NO]];
    if (!manifest[aProfile]) {
        return NULL;
    }
    NSURL *datadir = [profiles URLByAppendingPathComponent:manifest[aProfile]];
    NSData *contents = [NSData dataWithContentsOfFile:[datadir.path stringByAppendingPathComponent:@"data.txd"] options:NSDataReadingUncached error:err];
    if (contents) {
        txd_intermediate_t r = NULL;
        uint8_t *decrypted = NULL;
        uint64_t size = 0;
        NSUInteger passLen = [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        uint32_t errc = txd_decrypt_buf((uint8_t*)password.UTF8String, passLen, contents.bytes, contents.length, &decrypted, &size);
        if (errc != TXD_ERR_SUCCESS) {
            if (err)
                *err = SCLocalizedErrorWithTXDReturnValue(errc);
            return NULL;
        }
        errc = txd_intermediate_from_buf(decrypted, size, &r);
        _txd_kill_memory(decrypted, size);
        free(decrypted);
        if (errc != TXD_ERR_SUCCESS) {
            if (err)
                *err = SCLocalizedErrorWithTXDReturnValue(errc);
            return NULL;
        } else {
            return r;
        }
    }
    return NULL;
}

+ (BOOL)saveProfile:(txd_intermediate_t)aProfile name:(NSString *)name password:(NSString *)password {
    NSURL *profiles = [self profileDirectory];
    NSMutableDictionary *manifest = [NSMutableDictionary dictionaryWithContentsOfURL:[profiles URLByAppendingPathComponent:@"Manifest.plist" isDirectory:NO]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *datadir = NULL;
    if (!manifest[name]) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
        manifest[name] = [(__bridge NSString*)uuidString copy];
        CFRelease(uuidString);
        CFRelease(uuid);
        [manifest writeToFile:[profiles URLByAppendingPathComponent:@"Manifest.plist" isDirectory:NO].path atomically:YES];
        datadir = [profiles URLByAppendingPathComponent:manifest[name]];
    } else {
        datadir = [profiles URLByAppendingPathComponent:manifest[name]];
    }
    [fileManager createDirectoryAtURL:datadir withIntermediateDirectories:YES attributes:nil error:nil];
    uint8_t *buf = NULL, *enc = NULL;
    uint64_t size = 0, encsize = 0;
    uint32_t result_code = txd_export_to_buf(aProfile, &buf, &size);
    if (result_code != TXD_ERR_SUCCESS)
        return NO;
    const uint8_t *pass = (const uint8_t*)[password UTF8String];
    const uint64_t passlen = [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSString *comment = [NSString stringWithFormat:@"Name: %@\nExported by %@ %@", name,
                         SCApplicationInfoDictKey(@"CFBundleName"),
                         SCApplicationInfoDictKey(@"CFBundleShortVersionString")];
    txd_encrypt_buf(pass, passlen, buf, size, &enc, &encsize, comment.UTF8String);
    _txd_kill_memory(buf, size);
    free(buf);
    NSData *contents = [[NSData alloc] initWithBytesNoCopy:enc length:encsize freeWhenDone:YES];
    [contents writeToFile:[datadir.path stringByAppendingPathComponent:@"data.txd"] atomically:YES];
    return YES;
}

@end
