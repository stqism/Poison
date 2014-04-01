#ifndef DESUserDiscovery_h
#define DESUserDiscovery_h
#import <Foundation/Foundation.h>

extern NSString *const DESUserDiscoveryCallbackDomain;
extern NSString *const DNSSDErrorDomain;
#define DESUserDiscoveryErrorBadInput (-1)
#define DESUserDiscoveryErrorBadReply (-2)

typedef void(^DESUserDiscoveryCallback)(NSString *result, NSError *error);

/**
 * Find a user's Tox ID using DNS service discovery.
 * This function returns immediately, callback will be
 * called when the resolution is complete.
 * @param shouldBeAnEmailAddress the user's address.
 *                               Example: "stqism\@unglinux.org"
 * @param callback func(NSString *result, NSError *error).
 *                 One of the parameters will be valid depending on how
 *                 the resolution turned out.
 */
void DESDiscoverUser(NSString *shouldBeAnEmailAddress,
                     DESUserDiscoveryCallback callback);
#endif
