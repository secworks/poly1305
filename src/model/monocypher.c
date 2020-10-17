#include "monocypher.h"
#include <stdio.h>

/////////////////
/// Utilities ///
/////////////////

#define FOR(i, start, end)   for (size_t (i) = (start); (i) < (end); (i)++)
#define WIPE_CTX(ctx)        crypto_wipe(ctx   , sizeof(*(ctx)))
#define WIPE_BUFFER(buffer)  crypto_wipe(buffer, sizeof(buffer))
#define MIN(a, b)            ((a) <= (b) ? (a) : (b))
#define ALIGN(x, block_size) ((~(x) + 1) & ((block_size) - 1))

typedef int8_t   i8;
typedef uint8_t  u8;
typedef uint32_t u32;
typedef int32_t  i32;
typedef int64_t  i64;
typedef uint64_t u64;

static u32 load32_le(u8 s[4])
{
    return (u32)s[0]
        | ((u32)s[1] <<  8)
        | ((u32)s[2] << 16)
        | ((u32)s[3] << 24);
}

static void store32_le(u8 out[4], u32 in)
{
    out[0] =  in        & 0xff;
    out[1] = (in >>  8) & 0xff;
    out[2] = (in >> 16) & 0xff;
    out[3] = (in >> 24) & 0xff;
}

void crypto_wipe(void *secret, size_t size)
{
    volatile u8 *v_secret = (u8*)secret;
    FOR (i, 0, size) {
        v_secret[i] = 0;
    }
}


//------------------------------------------------------------------
// print_hexdata()
// Dump hex data
//------------------------------------------------------------------
void print_hexdata(uint8_t *data, uint32_t len) {
  printf("Length: 0x%08x\n", len);

  for (uint32_t i = 0 ; i < len ; i += 1) {
    printf("0x%02x ", data[i]);
    if ((i > 0) && ((i + 1) % 8 == 0))
      printf("\n");
  }

  printf("\n");
}


//------------------------------------------------------------------
// print_context()
//
// Print the poly1305 context.
//------------------------------------------------------------------
void print_context(crypto_poly1305_ctx *ctx) {
  printf("r:     0x%08x_%08x_%08x_%08x\n",
         ctx->r[0], ctx->r[1], ctx->r[2], ctx->r[3]);
  printf("h:     0x%08x_%08x_%08x_%08x_%08x\n",
         ctx->h[0], ctx->h[1], ctx->h[2], ctx->h[3], ctx->h[4]);
  printf("c:     0x%08x_%08x_%08x_%08x_%08x\n",
         ctx->c[0], ctx->c[1], ctx->c[2], ctx->c[3], ctx->c[4]);
  printf("s:     0x%08x_%08x_%08x_%08x\n",
         ctx->s[0], ctx->s[1], ctx->s[2], ctx->s[3]);
  printf("c_idx: 0x%08zx\n", ctx->c_idx);
  printf("\n");
}


//------------------------------------------------------------------
// poly_block()
// h = (h + c) * r
// preconditions:
//   ctx->h <= 4_ffffffff_ffffffff_ffffffff_ffffffff
//   ctx->c <= 1_ffffffff_ffffffff_ffffffff_ffffffff
//   ctx->r <=   0ffffffc_0ffffffc_0ffffffc_0fffffff
// Postcondition:
//   ctx->h <= 4_ffffffff_ffffffff_ffffffff_ffffffff
//------------------------------------------------------------------
static void poly_block(crypto_poly1305_ctx *ctx)
{
  printf("\n");
  printf("poly_block started\n");
  printf("------------------\n");
  printf("poly_block: Context before processing:\n");
  print_context(ctx);

  printf("poly_block: Intermediate results during processing:\n");
  // s = h + c, without carry propagation
  u64 s0 = ctx->h[0] + (u64)ctx->c[0]; // s0 <= 1_fffffffe
  u64 s1 = ctx->h[1] + (u64)ctx->c[1]; // s1 <= 1_fffffffe
  u64 s2 = ctx->h[2] + (u64)ctx->c[2]; // s2 <= 1_fffffffe
  u64 s3 = ctx->h[3] + (u64)ctx->c[3]; // s3 <= 1_fffffffe
  u32 s4 = ctx->h[4] +      ctx->c[4]; // s4 <=          5

  printf("s0  = 0x%016llx, s1  = 0x%016llx, s2  = 0x%016llx\n", s0, s1, s2);
  printf("s3  = 0x%016llx, s4  = 0x%016x\n", s3, s4);
  printf("\n");

  // Local all the things!
  u32 r0 = ctx->r[0];       // r0  <= 0fffffff
  u32 r1 = ctx->r[1];       // r1  <= 0ffffffc
  u32 r2 = ctx->r[2];       // r2  <= 0ffffffc
  u32 r3 = ctx->r[3];       // r3  <= 0ffffffc
  u32 rr0 = (r0 >> 2) * 5;  // rr0 <= 13fffffb // lose 2 bits...
  u32 rr1 = (r1 >> 2) + r1; // rr1 <= 13fffffb // rr1 == (r1 >> 2) * 5
  u32 rr2 = (r2 >> 2) + r2; // rr2 <= 13fffffb // rr1 == (r2 >> 2) * 5
  u32 rr3 = (r3 >> 2) + r3; // rr3 <= 13fffffb // rr1 == (r3 >> 2) * 5

  printf("rr0 = 0x%016x, rr1 = 0x%016x, rr2 = 0x%016x, rr3 = 0x%016x\n",
         rr0, rr1, rr2, rr3);
  printf("\n");

  // (h + c) * r, without carry propagation
  u64 x0 = s0*r0 + s1*rr3 + s2*rr2 + s3*rr1 + s4*rr0; // <= 97ffffe007fffff8
  u64 x1 = s0*r1 + s1*r0  + s2*rr3 + s3*rr2 + s4*rr1; // <= 8fffffe20ffffff6
  u64 x2 = s0*r2 + s1*r1  + s2*r0  + s3*rr3 + s4*rr2; // <= 87ffffe417fffff4
  u64 x3 = s0*r3 + s1*r2  + s2*r1  + s3*r0  + s4*rr3; // <= 7fffffe61ffffff2
  u32 x4 = s4 * (r0 & 3); // ...recover 2 bits        // <=                f

  printf("x0  = 0x%016llx, x1  = 0x%016llx, x2  = 0x%016llx\n", x0, x1, x2);
  printf("x3  = 0x%016llx, x4  = 0x%016x\n", x3, x4);
  printf("\n");

  // partial reduction modulo 2^130 - 5
  u32 u5 = x4 + (x3 >> 32); // u5 <= 7ffffff5
  u64 u0 = (u5 >>  2) * 5 + (x0 & 0xffffffff);
  u64 u1 = (u0 >> 32)     + (x1 & 0xffffffff) + (x0 >> 32);
  u64 u2 = (u1 >> 32)     + (x2 & 0xffffffff) + (x1 >> 32);
  u64 u3 = (u2 >> 32)     + (x3 & 0xffffffff) + (x2 >> 32);
  u64 u4 = (u3 >> 32)     + (u5 & 3);

  printf("u0  = 0x%016llx, u1  = 0x%016llx, u2  = 0x%016llx\n", u0, u1, u2);
  printf("u3  = 0x%016llx, u4  = 0x%016llx, u5  = 0x%016x\n", u3, u4, u5);
  printf("\n");

  // Update the hash
  ctx->h[0] = u0 & 0xffffffff; // u0 <= 1_9ffffff0
  ctx->h[1] = u1 & 0xffffffff; // u1 <= 1_97ffffe0
  ctx->h[2] = u2 & 0xffffffff; // u2 <= 1_8fffffe2
  ctx->h[3] = u3 & 0xffffffff; // u3 <= 1_87ffffe4
  ctx->h[4] = (u32)u4;         // u4 <=          4

  printf("\n");
  printf("poly_block: Context after processing:\n");
  print_context(ctx);
  printf("poly_block completed\n");
  printf("--------------------\n");
  printf("\n");
}


//------------------------------------------------------------------
// (re-)initializes the input counter and input buffer
//------------------------------------------------------------------
static void poly_clear_c(crypto_poly1305_ctx *ctx)
{
  printf("\n");
  printf("poly_clear_c called\n");

  ctx->c[0]  = 0;
  ctx->c[1]  = 0;
  ctx->c[2]  = 0;
  ctx->c[3]  = 0;
  ctx->c_idx = 0;

  printf("poly_clear_c completed.\n");
  printf("-----------------------\n\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
static void poly_take_input(crypto_poly1305_ctx *ctx, u8 input)
{
  printf("poly_take_input() called with input: 0x%02x: \n", input);
  printf("poly_take_input: Context before poly_take_input():\n");
  print_context(ctx);

  size_t word = ctx->c_idx >> 2;
  size_t byte = ctx->c_idx & 3;
  ctx->c[word] |= (u32)input << (byte * 8);
  ctx->c_idx++;
  printf("poly_take_input: calculated word: %0zu, calculated byte: %0zu\n", word, byte);
  printf("poly_take_input: ctx->c[word] = 0x%08x\n", ctx->c[word]);

  printf("Context after poly_take_input():\n");
  print_context(ctx);

  printf("poly_take_input() done.\n\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
static void poly_update(crypto_poly1305_ctx *ctx,
                        u8 *message, size_t message_size)

{
  printf("poly_update called.\n");
  printf("poly_update: Message given:\n");
  print_hexdata(&message[0], message_size);

  if (message_size == 0) {
    printf("poly_update: message_size == 0. No processing in poly_update done.\n");
    printf("poly_update completed.\n\n");
    return;
  }

  // We loop over the bytes in the message, calling poly_take_input.
  FOR (i, 0, message_size) {
    printf("poly_update: Calling poly_take_input\n");
    poly_take_input(ctx, message[i]);

    if (ctx->c_idx == 16) {
      printf("poly_update: ctx->c_idx == 16, we thus do some magic calling poly_block() and then poly_clear_c()\n");
      poly_block(ctx);
      poly_clear_c(ctx);
    }
  }
  printf("poly_update completed.\n\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
void crypto_poly1305_init(crypto_poly1305_ctx *ctx, u8 key[32])
{
  printf("crypto_poly1305_init called.\n");
  printf("----------------------------\n");
  printf("crypto_poly1305_init: Key given:\n");
  print_hexdata(&key[0], 32);

  printf("crypto_poly1305_init: Context before processing:\n");
  print_context(ctx);

  // Initial hash is zero
  FOR (i, 0, 5) {
    ctx->h[i] = 0;
  }

  // add 2^130 to every input block
  ctx->c[4] = 1;
  poly_clear_c(ctx);

  // load r and s (r has some of its bits cleared)
  FOR (i, 0, 1) { ctx->r[0] = load32_le(key           ) & 0x0fffffff; }
  FOR (i, 1, 4) { ctx->r[i] = load32_le(key + i*4     ) & 0x0ffffffc; }
  FOR (i, 0, 4) { ctx->s[i] = load32_le(key + i*4 + 16);              }

  printf("crypto_poly1305_init: Context after processing:\n");
  print_context(ctx);
  printf("crypto_poly1305_init completed.\n");
  printf("-------------------------------\n\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
void crypto_poly1305_update(crypto_poly1305_ctx *ctx,
                            u8 *message, size_t message_size)
{
  printf("crypto_poly1305_update called.\n");
  printf("------------------------------\n");
  printf("Message given:\n");
  print_hexdata(&message[0], message_size);

  printf("Context before crypto_poly1305_update:\n");
  print_context(ctx);

  // Align ourselves with block boundaries
  size_t align = MIN(ALIGN(ctx->c_idx, 16), message_size);
  printf("crypto_poly1305_update: Calculated align: 0x%08zx\n", align);

  printf("crypto_poly1305_update: Calling poly_update with align as message size:\n");
  poly_update(ctx, message, align);

  message      += align;
  message_size -= align;
  printf("crypto_poly1305_update: Message efter alignment:\n");
  print_hexdata(&message[0], message_size);


  // Process the message block by block
  printf("crypto_poly1305_update: Alignment completed. Time for block processing.\n");
  size_t nb_blocks = message_size >> 4;
  printf("crypto_poly1305_update: Calculated number of blocks: %lu\n", nb_blocks);

  printf("crypto_poly1305_update: Looping over all blocks\n");
  FOR (i, 0, nb_blocks) {
    printf("crypto_poly1305_update: Processing block %lu\n", i);
    FOR (j, 0, 4) {
      ctx->c[j] = load32_le(message +  j*4);
    }
    printf("crypto_poly1305_update: Calling poly_block with block le32-loaded into ctx->c:\n");
    poly_block(ctx);
    message += 16;
  }
    printf("crypto_poly1305_update: All blocks processed.\n");

  if (nb_blocks > 0) {
    printf("crypto_poly1305_update: Clearing ctx->c after processing message blocks\n");
    poly_clear_c(ctx);
  }
  message_size &= 15;
  printf("crypto_poly1305_update: Message size after final adjustment: %zu\n", message_size);

  // remaining bytes
  printf("crypto_poly1305_update: Calling poly_update a final time.\n");
  poly_update(ctx, message, message_size);

  printf("crypto_poly1305_update completed.\n");
  printf("---------------------------------\n\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
void crypto_poly1305_final(crypto_poly1305_ctx *ctx, u8 mac[16])
{
  printf("\n");
  printf("crypto_poly1305_final started\n");
  printf("-----------------------------\n");

  printf("crypto_poly1305_final: Handling last block and updating ctx->c based on c_idx.\n");
  // Process the last block (if any)
  if (ctx->c_idx != 0) {
    printf("crypto_poly1305_final: ctx->c_idx != 0.\n");
    // move the final 1 according to remaining input length
    // (We may add less than 2^130 to the last input block)
    ctx->c[4] = 0;
    printf("crypto_poly1305_final: Adjusted ctx->c[4] = 0.\n");
    printf("crypto_poly1305_final: Calling poly_take_input with message length 1.\n");
    poly_take_input(ctx, 1);
    // one last hash update
    printf("crypto_poly1305_final: Calling poly_block once more.\n");
    poly_block(ctx);
  }
  printf("crypto_poly1305_final: Final block handling done.\n");

  printf("crypto_poly1305_final: Context before final processing:\n");
  print_context(ctx);

  // check if we should subtract 2^130-5 by performing the
  // corresponding carry propagation.
  u64 u0 = (u64)5     + ctx->h[0]; // <= 1_00000004
  u64 u1 = (u0 >> 32) + ctx->h[1]; // <= 1_00000000
  u64 u2 = (u1 >> 32) + ctx->h[2]; // <= 1_00000000
  u64 u3 = (u2 >> 32) + ctx->h[3]; // <= 1_00000000
  u64 u4 = (u3 >> 32) + ctx->h[4]; // <=          5
  // u4 indicates how many times we should subtract 2^130-5 (0 or 1)

  // h + s, minus 2^130-5 if u4 exceeds 3
  u64 uu0 = (u4 >> 2) * 5 + ctx->h[0] + ctx->s[0]; // <= 2_00000003
  u64 uu1 = (uu0 >> 32)   + ctx->h[1] + ctx->s[1]; // <= 2_00000000
  u64 uu2 = (uu1 >> 32)   + ctx->h[2] + ctx->s[2]; // <= 2_00000000
  u64 uu3 = (uu2 >> 32)   + ctx->h[3] + ctx->s[3]; // <= 2_00000000

  printf("crypto_poly1305_final: Intermediate results during final processing:\n");
  printf("u0  = 0x%016llx, u1  = 0x%016llx, u2  = 0x%016llx\n", u0, u1, u2);
  printf("u3  = 0x%016llx, u4  = 0x%016llx\n", u3, u4);
  printf("\n");

  printf("uu0 = 0x%016llx, uu1 = 0x%016llx\n", uu0, uu1);
  printf("uu2 = 0x%016llx, uu3 = 0x%016llx\n", uu2, uu3);
  printf("\n");

  u32 m0 = (u32)uu0;
  u32 m1 = (u32)uu1;
  u32 m2 = (u32)uu2;
  u32 m3 = (u32)uu3;

  printf("m0 = 0x%08x, m1 = 0x%08x\n", m0, m1);
  printf("m2 = 0x%08x, m3 = 0x%08x\n", m2, m3);
  printf("\n\n");
  printf("crypto_poly1305_final: Final processing done.\n");

  printf("crypto_poly1305_final: Assembling the mac by applying le32 on m0..m3:\n");
  store32_le(mac     , (u32)m0);
  store32_le(mac +  4, (u32)m1);
  store32_le(mac +  8, (u32)m2);
  store32_le(mac + 12, (u32)m3);

  printf("crypto_poly1305_final: The resulting mac:\n");
  print_hexdata(&mac[0], 16);
  printf("\n");

  printf("crypto_poly1305_final: Context before wiping:\n");
  print_context(ctx);
  WIPE_CTX(ctx);
  printf("crypto_poly1305_final: Context after wiping:\n");
  print_context(ctx);

  printf("crypto_poly1305_final completed\n");
  printf("-------------------------------\n");
  printf("\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
void crypto_poly1305(u8 mac[16], u8 *message, size_t message_size, u8 key[32])
{
  crypto_poly1305_ctx ctx;
  crypto_poly1305_init  (&ctx, key);
  crypto_poly1305_update(&ctx, message, message_size);
  crypto_poly1305_final (&ctx, mac);
}
