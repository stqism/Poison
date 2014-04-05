#include "Copyright.h"

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

uint8_t SCCodeSigningStatus = SCCodeSigningStatusNoSign;
NSString *SCCodeSigningSigner = nil;

int main(int argc, const char * argv[]) {
    /* Get the signature for verification purposes. */
    SecCodeRef sig = NULL;
    SecStaticCodeRef sigi = NULL;
    SecCodeCopySelf(kSecCSDefaultFlags, &sig);
    SecCodeCopyStaticCode(sig, kSecCSDefaultFlags, &sigi);

    OSStatus rv = SecCodeCheckValidity(sig, kSecCSEnforceRevocationChecks, NULL);
    OSStatus rvs = SecStaticCodeCheckValidity(sigi, kSecCSEnforceRevocationChecks, NULL);
    if (rv == errSecSuccess && rvs == errSecSuccess) {
        CFDictionaryRef csInfo = NULL;
        SecCodeCopySigningInformation(sigi, kSecCSSigningInformation, &csInfo);

        /* Copy the first signer certificate. */
        CFArrayRef certs = (CFArrayRef)CFDictionaryGetValue(csInfo, kSecCodeInfoCertificates);
        SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(certs, 0);
        CFStringRef certDesc = SecCertificateCopyLongDescription(kCFAllocatorDefault, cert, NULL);
        NSLog(@"Poison is signed by %@.", (__bridge NSString*)certDesc);
        SCCodeSigningStatus = SCCodeSigningStatusOK;
        SCCodeSigningSigner = [NSString stringWithString:(__bridge NSString*)certDesc];
        CFRelease(certDesc);
        CFRelease(csInfo);
    } else if (rv == errSecCSUnsigned && rvs == errSecCSUnsigned) {
        NSLog(@"Poison is unsigned.");
        SCCodeSigningStatus = SCCodeSigningStatusNoSign;
        #ifdef SC_ENFORCE_SIGNING_RESTRICTIONS_HARD
        NSLog(@"SC_ENFORCE_SIGNING_RESTRICTIONS_HARD is defined, and this copy is not signed.\n"
              @"This normally shouldn't happen, but I'm going to put up the warning for this anyway."
              @"If you didn't expect this to happen, go ahead and remove '-DSC_ENFORCE_SIGNING_RESTRICTIONS_HARD'\n"
              @"from 'Other C Flags' in Xcode's build settings.");
        SCCodeSigningStatus = SCCodeSigningStatusInvalid;
        #endif
    } else {
        NSLog(@"Poison code signature is INVALID. This copy probably has been tampered with!");
        SCCodeSigningStatus = SCCodeSigningStatusInvalid;
    }
    CFRelease(sigi);
    CFRelease(sig);

    return NSApplicationMain(argc, argv);
}
