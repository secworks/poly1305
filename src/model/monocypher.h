#ifndef MONOCYPHER_H
#define MONOCYPHER_H

#include <inttypes.h>
#include <stddef.h>

////////////////////////
/// Type definitions ///
////////////////////////

// Poly1305
typedef struct {
    uint32_t r[4];   // constant multiplier (from the secret key)
    uint32_t h[5];   // accumulated hash
    uint32_t c[5];   // chunk of the message
    uint32_t s[4];   // random nonce added at the end (from the secret key)
    size_t   c_idx;  // How many bytes are there in the chunk.
} crypto_poly1305_ctx;


// Utility functions.
void print_hexdata(uint8_t *data, uint32_t len);
void print_context(crypto_poly1305_ctx *ctx);


// Poly 1305
// ---------

// Direct interface
void crypto_poly1305(uint8_t mac[16],
                     uint8_t *message, size_t message_size,
                     uint8_t  key[32]);

// Incremental interface
void crypto_poly1305_init  (crypto_poly1305_ctx *ctx, uint8_t key[32]);
void crypto_poly1305_update(crypto_poly1305_ctx *ctx,
                            uint8_t *message, size_t message_size);
void crypto_poly1305_final (crypto_poly1305_ctx *ctx, uint8_t mac[16]);


#endif // MONOCYPHER_H
