#include <string.h>
#include <sodium.h>
#include "scrypt-jane.h"
#include "tox.h"
#include "data.h"
#include "txdplus_private.h"

#define HASHED_LEN (crypto_secretbox_KEYBYTES) // Length of our scrypted key
#define SALT_LEN   (24 + crypto_secretbox_NONCEBYTES) // Half for scrypt, half for NaCl
#define BASE_LEN   (32 + SALT_LEN)
#define FOUR_MEGABYTES (4194304)

const uint32_t TXD_ERR_DECRYPT_FAILED = 2059;

static txd_fourcc_t TXD_ENVELOPE_MAGIC = 'MAKi'; // Defines MAGIC as '0x4D414B69'.
static uint64_t     SCRYPT_N = 13;
static uint32_t     SCRYPT_r = 3;
static uint32_t     SCRYPT_p = 0;

#define TXD_NO_ENCRYPTED_PADDING
#ifndef TXD_NO_ENCRYPTED_PADDING
static inline uint64_t _txd_get_size_of_next_4(uint64_t i) {
    uint64_t ret = FOUR_MEGABYTES;
    while (ret < i)
        ret += FOUR_MEGABYTES;
    return ret;
}
#else
static inline uint64_t _txd_get_size_of_next_4(uint64_t i){
    return i;
}
#endif

/* TXD envelope functions. This is supposedly better than the core
 * tox_save_encrypted. */

int txd_encrypt_buf(const uint8_t *password, uint64_t passlen,
                    const uint8_t *clear_in, uint64_t clear_len,
                    uint8_t **out, uint64_t *out_size,
                    const char *comment) {
    unsigned long comment_size = strlen(comment);
    if (comment_size > UINT32_MAX)
        return 1;
    uint32_t actual_comment_length = (uint32_t)comment_size;
    
    uint64_t encrypted_length = crypto_secretbox_ZEROBYTES + _txd_get_size_of_next_4(clear_len);
    uint64_t eblocklen = BASE_LEN + actual_comment_length + encrypted_length;
    if (out_size)
        *out_size = eblocklen;
    if (!out)
        return 0;
    
    uint8_t *hashed_pass = malloc(HASHED_LEN + SALT_LEN);
    uint8_t *salt = hashed_pass + HASHED_LEN;
    randombytes_buf(salt, SALT_LEN);
    
    uint8_t *encrypt_buffer = calloc(encrypted_length, 1);
    memcpy(encrypt_buffer + crypto_secretbox_ZEROBYTES, clear_in, clear_len);
    
    uint8_t *eblock = calloc(eblocklen, 1);
    uint8_t *eblock_pos = eblock;
    _txd_write_int_32(TXD_ENVELOPE_MAGIC, eblock_pos);    eblock_pos += sizeof(TXD_ENVELOPE_MAGIC);
    
    _txd_write_int_32(actual_comment_length, eblock_pos); eblock_pos += sizeof(actual_comment_length);
    memcpy(eblock_pos, comment,
           actual_comment_length);                        eblock_pos += actual_comment_length;
    
    _txd_write_int_64(SCRYPT_N, eblock_pos);              eblock_pos += sizeof(SCRYPT_N);
    _txd_write_int_32(SCRYPT_r, eblock_pos);              eblock_pos += sizeof(SCRYPT_r);
    _txd_write_int_32(SCRYPT_p, eblock_pos);              eblock_pos += sizeof(SCRYPT_p);
    memcpy(eblock_pos, salt, SALT_LEN);                   eblock_pos += SALT_LEN;
    _txd_write_int_64(encrypted_length, eblock_pos);      eblock_pos += sizeof(encrypted_length);
    
    scrypt(password, passlen, salt, 24, SCRYPT_N, SCRYPT_r, SCRYPT_p, hashed_pass, HASHED_LEN);
    crypto_secretbox(eblock_pos, encrypt_buffer, encrypted_length, salt + 24, hashed_pass);
    _txd_kill_memory(encrypt_buffer, encrypted_length);
    _txd_kill_memory(hashed_pass, HASHED_LEN + SALT_LEN);
    free(encrypt_buffer); free(hashed_pass);
    
    if (out)
        *out = eblock;
    if (out_size)
        *out_size = eblocklen;
    
    return TXD_ERR_SUCCESS;
}

int txd_decrypt_buf(const uint8_t *password, uint64_t passlen,
                    const uint8_t *encr_in, uint64_t encr_len,
                    uint8_t **out, uint64_t *out_size) {
    if (encr_len <= BASE_LEN || _txd_read_int_32(encr_in) != TXD_ENVELOPE_MAGIC)
        return TXD_ERR_BAD_BLOCK;
    
    uint8_t *encr_pos = (uint8_t *)encr_in + sizeof(TXD_ENVELOPE_MAGIC);
    uint32_t comment_len = _txd_read_int_32(encr_pos);  encr_pos += sizeof(uint32_t);
    if (comment_len > encr_len - 8)
        return TXD_ERR_SIZE_MISMATCH;
    encr_pos += comment_len; /* Just skip over the comment */
    
    uint64_t N = _txd_read_int_64(encr_pos);            encr_pos += sizeof(N);
    uint32_t r = _txd_read_int_32(encr_pos);            encr_pos += sizeof(r);
    uint32_t p = _txd_read_int_32(encr_pos);            encr_pos += sizeof(p);
    uint64_t encb_len = _txd_read_int_64(encr_pos + SALT_LEN);
    
    if (encb_len > encr_len - 32 - comment_len)
        return TXD_ERR_SIZE_MISMATCH;
    
    uint8_t *hashed_pass = malloc(HASHED_LEN + SALT_LEN);
    uint8_t *salt = hashed_pass + HASHED_LEN;
    uint8_t *out_buf = calloc(encb_len, 1);
    
    memcpy(salt, encr_pos, SALT_LEN);                   encr_pos += sizeof(encb_len) + SALT_LEN;
    scrypt(password, passlen, salt, 24, N, r, p, hashed_pass, HASHED_LEN);
    int err = crypto_secretbox_open(out_buf, encr_pos, encb_len, salt + 24, hashed_pass);
    if (err == -1) {
        _txd_kill_memory(hashed_pass, HASHED_LEN + SALT_LEN);
        _txd_kill_memory(out_buf, encb_len);
        free(hashed_pass);
        free(out_buf);
        return TXD_ERR_DECRYPT_FAILED;
    }
    if (out) {
        uint8_t *actual_out_buf = calloc(encb_len - crypto_secretbox_ZEROBYTES, 1);
        memcpy(actual_out_buf, out_buf + crypto_secretbox_ZEROBYTES, encb_len - crypto_secretbox_ZEROBYTES);
        *out = actual_out_buf;
    }
    if (out_size)
        *out_size = encb_len - crypto_secretbox_ZEROBYTES;
    return TXD_ERR_SUCCESS;
}