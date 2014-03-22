#ifndef DESKeyFunctions_h
#define DESKeyFunctions_h

/**
 * Verify whether a string is a 64-character hex string suitable for passing into
 * DeepEndConvertPublicKeyString.
 */
BOOL DESPublicKeyIsValid(NSString *theKey);
BOOL DESPrivateKeyIsValid(NSString *theKey);
BOOL DESFriendAddressIsValid(NSString *theAddr);

/**
 * Convert a Tox public key to byte form suitable for passing to tox_*
 * functions.
 * It will fail if theString is not a valid key.
 * @param theString the Tox public key.
 * @param theOutput a buffer of exactly DESPublicKeySize bytes.
 * @return YES on success, NO on failure.
 */
BOOL DESConvertPublicKeyToData(NSString *theString, uint8_t *theOutput);

/**
 * Convert a Tox private key to byte form suitable for passing to tox_*
 * functions.
 * It will fail if theString is not a valid key.
 * @param theString the Tox private key.
 * @param theOutput a buffer of exactly DESPrivateKeySize bytes.
 * @return YES on success, NO on failure.
 */
BOOL DESConvertPrivateKeyToData(NSString *theString, uint8_t *theOutput);

/**
 * Convert a Tox friend address to byte form suitable for passing to tox_*
 * functions.
 * It will fail if theString is not a valid key.
 * @param theString the Tox friend address.
 * @param theOutput a buffer of exactly DESFriendAddressSize bytes.
 * @return YES on success, NO on failure.
 */
BOOL DESConvertFriendAddressToData(NSString *theString, uint8_t *theOutput);

/**
 * Convert a Tox public key from Core to its hex representation.
 * @param theData the buffer containing the public key.
 * @return theData as a hexadecimal NSString.
 */
NSString *DESConvertPublicKeyToString(const uint8_t *theData);

/**
 * Convert a Tox private key from Core to its hex representation.
 * @param theData the buffer containing the private key.
 * @return theData as a hexadecimal NSString.
 */
NSString *DESConvertPrivateKeyToString(const uint8_t *theData);

/**
 * Convert a Tox friend address from Core to its hex representation.
 * @param theData the buffer containing the address.
 * @return theData as a hexadecimal NSString.
 */
NSString *DESConvertFriendAddressToString(const uint8_t *theData);

/**
 * Verify that the public key publicKey is the counterpart to
 * private key privateKey.
 * @param privateKey the private key.
 * @param publicKey the public key.
 * @return YES if keys are a pair, NO otherwise.
 */
BOOL DESKeyPairIsValid(const uint8_t *privateKey, const uint8_t *publicKey);

#endif
