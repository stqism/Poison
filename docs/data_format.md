**Updated 2013-10-01 (YYYY/MM/DD)**:
* NaCl is good.

**Updated 2013-08-09 (YYYY/MM/DD)**:
* ``USERSTATUS_KIND`` was renamed to ``USERSTATUS``. The user status string is now referred to as the *[user] status message*.

**Updated 2013-08-08 (YYYY/MM/DD)**:
* Added MAC and blocklen fields to format.
* Use scrypt for encryption.

## TL;DR: ##

The file format is
``[MAGIC1][COMMENTLEN][COMMENT][SCRYPTHEAD][SALT][BLOCKLEN][ENCRYPTEDBLOCK:[MAGIC2][PUBLIC_KEY][PRIVATE_KEY][SELFDATA][FRIENDDATA]][MAC]``

## Definitions ##

**MAGIC1**:
*(4 bytes)* Constant value ``0x6B75646F``.

**COMMENTLEN**:
*(4 bytes)* Unsigned 32-bit integer containing the length of COMMENT.

**COMMENT**:
Arbitrary data whose length is equal to COMMENTLEN. Not required to be null-terminated.

**SCRYPTHEAD**:
*(16 bytes)* scrypt's N, r, p variables, in that order.

**SALT**:
*(24 bytes)* Salt for scrypt AND a nonce for NaCl. I reuse it because I am lazy.

**BLOCKLEN**:
*(8 bytes)* Unsigned 64-bit integer containing the length of ``ENCRYPTEDBLOCK``.

**ENCRYPTEDBLOCK**:
The contents within are encrypted with NaCl ``crypto_secretbox`` using the user's password run through scrypt.

**MAGIC2**:
*(4 bytes)* Constant value ``0x61766B61``.
It is used to verify successful decryption of **ENCRYPTEDBLOCK**.

**PUBLIC_KEY**:
The Tox public key in 32-byte binary format.

**PRIVATE_KEY**:
The Tox private key in 32-byte binary format.

**MAC**:
A MAC calculated from the *ciphertext* of **ENCRYPTEDBLOCK**, using NaCl ``crypto_auth`` with the same key used to encrypt **ENCRYPTEDBLOCK**.

*Use a key validation routine at runtime to verify the keypair. This is important.*
*If the keys do not match, it implies that the entire file is also invalid.*
*It is up to the client to purge the data from the server in case of validation failure.*

--------------------------------------------------------------------------------

**Special considerations for SELFDATA and FRIENDDATA blocks**:
This block will likely be updated over and over again
as client state changes. It would do us good to keep
it as small as possible, for quick sync.

The minimum size of the SELFDATA block is 16 bytes.
A client could wait a few seconds after nickname
or user status is updated before serializing and
uploading, as the user may be updating both.

The minimum size of the FRIENDDATA block is 8 bytes.

**Integers are stored big-endian. This is important.**

--------------------------------------------------------------------------------

**SELFDATA**:

**timestamp**:
*(8 bytes)* A 64-bit unsigned integer due to Y2K38. A Unix timestamp **IN UTC**
containing the time the block was last synced. A file with a larger timestamp
will take precedence over local data with a smaller one.

**name**:
*(4 bytes + length of name)*
Our display name. It should be trimmed of whitespace[1] both before
encrypting and after decrypting. The first 4 bytes are the length
as an unsigned integer.

* [1]: Whitespace includes newlines, in this context.

**status message**:
*(4 + 1 bytes + length of user status message)*
Our status message, and its type[1]. Like display name, it should
be trimmed of whitespace. The first 4 bytes are the length
as an unsigned integer. The first byte after the length [5th]
is a value of enum ``USERSTATUS``. If the kind is invalid,
it shall be assumed to be ``USERSTATUS_NONE`` (the default).

* [1]: Only if applicable. If there is no type, i.e. the ``USERSTATUS`` is ``USERSTATUS_NONE``, the byte shall be 0. Do not omit the byte.

**FRIENDDATA**:

**timestamp**
*(8 bytes)* 64-bit unsigned integer due to Y2K38. A Unix timestamp **IN UTC**
containing the time the block was last synced. A file with a larger timestamp
will take precedence over local data with a smaller one.

* A merging sync method can be used instead of clobbering local
  data outright. It's up to the client.

**count**
*(4 bytes)* Unsigned integer representing the number of friends stored
in this block. This puts the limit of stored friends at 4294967296.

**blocks**: *(size of __FRIENDBLOCK__ x __count__ bytes)* An array of **FRIENDBLOCK**.

**FRIENDBLOCK**:

**public key**: *(32 bytes)* I don't need to explain this.

**last known name**: *(4 bytes + length of name)* Last known name of the friend.
The first four bytes is the length of the remaining bytes.
Used to display in the client while we wait for them to be
connected again.

--------------------------------------------------------------------------------

Discussion:

- Maybe use push notifications to alert clients to updated sync data (ex. APNS)?
- Have different methods for loading just the [self data, friend data, keys, etc]
  to save bandwidth. This would be easiet using multiple encrypted blocks.
- Since the timestamps are encrypted, how can we handle misconfigured clocks
  on the server-side?
- Someone good with encryption should decide on a standard algorithm.
  **<-- HIGH PRIORITY.**
