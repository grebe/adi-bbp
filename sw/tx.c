#include <assert.h>
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "tx.h"

const double samp_mult = 32768.0;

// defines for complex values in preambles

// scaled
#define pp (sqrt(13.0 / 6.0) / 64.0)

#define c_zero  0.0,  0.0
#define c_one    pp,  0.0
#define c_pp     pp,  pp
#define c_mm   (-pp), (-pp)

const double stf_freq[8*8*2] = {
    c_zero, c_zero, c_zero, c_zero, c_mm,   c_zero, c_zero, c_zero,
    c_mm,   c_zero, c_zero, c_zero, c_pp,   c_zero, c_zero, c_zero,
    c_pp,   c_zero, c_zero, c_zero, c_pp,   c_zero, c_zero, c_zero,
    c_pp,   c_zero, c_zero, c_zero, c_zero, c_zero, c_zero, c_zero,
    c_zero, c_zero, c_zero, c_zero, c_zero, c_zero, c_zero, c_zero,
    c_pp,   c_zero, c_zero, c_zero, c_mm,   c_zero, c_zero, c_zero,
    c_pp,   c_zero, c_zero, c_zero, c_mm,   c_zero, c_zero, c_zero,
    c_mm,   c_zero, c_zero, c_zero, c_pp,   c_zero, c_zero, c_zero
};

const double ltf_freq[8*8*2] = {
    c_zero,
    c_one, -c_one, -c_one,  c_one,  c_one, -c_one,  c_one, -c_one,
    c_one, -c_one, -c_one, -c_one, -c_one, -c_one, c_one,  c_one,
    -c_one, -c_one,  c_one, -c_one,  c_one, -c_one,  c_one,  c_one,
    c_one,  c_one,

    c_zero, c_zero, c_zero, c_zero, c_zero,
    c_zero, c_zero, c_zero, c_zero, c_zero, c_zero,

    c_one, c_one,
    -c_one, -c_one, c_one, c_one, -c_one, c_one, -c_one, c_one,
    c_one, c_one, c_one, c_one, c_one, -c_one, -c_one, c_one,
    c_one, -c_one, c_one, -c_one, c_one, c_one, c_one, c_one
};

#undef c_zero
#undef c_one
#undef c_pp
#undef c_mm

static inline samp_t double_to_packed_fixed(double r, double i)
{
  int16_t r_int = (int16_t)(r * samp_mult);
  int16_t i_int = (int16_t)(i * samp_mult);
  uint16_t r_uint = ((uint16_t) r_int);
  uint16_t i_uint = ((uint16_t) i_int);
  return ((r_uint) << 16) | i_uint;
}


static void tf64_to_packed_160(const double freq[64*2], samp_t out[160], int time_start_idx)
{
  size_t i;
  double scratch[64*2];
  double w[32];
  int ip[16];
  ip[0] = 0;

  memcpy(scratch, freq, 64 * 2 * sizeof(double));

  cdft(2 * 64, 1, scratch, ip, w);

  for (i = 0; i < 160; i++) {
    size_t ridx = (i + time_start_idx) % 64;
    out[i] = double_to_packed_fixed(scratch[ridx * 2], scratch[ridx * 2 + 1]);
  }
}

void get_stf(samp_t stf[160])
{
  tf64_to_packed_160(stf_freq, stf, 0);
}

void get_ltf(samp_t ltf[160])
{
  tf64_to_packed_160(ltf_freq, ltf, 32);
}

static inline constraint_t update_state(constraint_t state, uint8_t in_byte)
{
  return (state << 1) | (in_byte & 0x1);
}

static inline void
next_in_bit(uint8_t **in, uint8_t *in_byte, uint8_t *in_bit_pos)
{
  (*in_bit_pos)++;
  *in_byte >>= 1;
  if (*in_bit_pos >= 8) {
    (*in)++;
    *in_byte = **in;
    *in_bit_pos = 0;
  }
}

static inline void
next_out_bits(uint8_t **out,
    constraint_t state,
    constraint_t *constrs, uint8_t constr_len,
    uint8_t *out_byte, uint8_t *out_bit_pos)
{
  uint8_t i;
  uint8_t out_bit;
  constraint_t mask = (((constraint_t) 1) << constr_len) - 1;

  assert(*out_bit_pos < 8);

  for (i = 0; i < 2; i++) {
    constraint_t prod = (constrs[i] & state) & mask;
    out_bit = __builtin_parity(prod);
    *out_byte >>= 1;
    *out_byte |= out_bit ? 0x80 : 0x00;
    (*out_bit_pos)++;
    if (*out_bit_pos >= 8) {
      **out = *out_byte;
      (*out)++;
      *out_byte = 0;
      *out_bit_pos = 0;
    }
  }
}

/**
 * Out must have length in_len * 2
 */
static void cc_encode_tb(
    uint8_t *in, size_t in_len,
    uint8_t *out,
    constraint_t *cc_const, uint8_t cc_length)
{
  constraint_t state, init_state;
  uint8_t current_in_byte, current_out_byte;
  uint8_t current_in_bit_pos, current_out_bit_pos;
  size_t i;

  current_in_byte = *in;
  current_in_bit_pos = 0;
  current_out_byte = 0;
  current_out_bit_pos = 0;

  // init state
  state = 0;
  for (i = 0; i < cc_length; i++) {
    state = update_state(state, current_in_byte);
    next_in_bit(&in, &current_in_byte, &current_in_bit_pos);
  }
  // need to remember init state for tail biting at end
  init_state = state;

  assert(in_len * 8 > cc_length);

  for (i = 0; i < in_len * 8 - cc_length; i++) {
    state = update_state(state, current_in_byte);
    next_in_bit(&in, &current_in_byte, &current_in_bit_pos);
    next_out_bits(&out,
        state,
        cc_const, cc_length,
        &current_out_byte, &current_out_bit_pos);
  }

  // output tail biting
  for (i = 0; i < cc_length; i++) {
    next_out_bits(
        &out,
        state,
        cc_const, cc_length,
        &current_out_byte, &current_out_bit_pos);
    state = update_state(state, current_in_byte);

    current_in_bit_pos++;
    current_in_byte >>= 1;
    if (current_in_bit_pos >= 8) {
      current_in_byte = init_state & 0xFF;
      init_state >>= 8;
      current_in_bit_pos = 0;
    }
  }
}

int pilot_compare(const void* e1, const void* e2)
{
  pilot_tone *p1 = (pilot_tone*)e1;
  pilot_tone *p2 = (pilot_tone*)e2;
  if (p1->pos < p2->pos) {
    return -1;
  } else if (p1->pos > p2->pos) {
    return 1;
  } else {
    return 0;
  }
}

static inline void add_pilots(
    double* __restrict__ in,
    double* __restrict__ out,
    uint64_t n_in,
    uint64_t n_out,
    uint64_t n_fft,
    uint8_t num_pilots,
    pilot_tone *pilots)
{
  uint64_t in_idx = 0, out_idx = 0, pilots_idx = 0;
  while (out_idx < n_out) {
    if (pilots_idx < num_pilots && pilots[pilots_idx].pos == (out_idx % n_fft)) {
      out[out_idx * 2] = pilots[pilots_idx].real;
      out[out_idx * 2 + 1] = pilots[pilots_idx].imag;
      pilots_idx += 1;
      if (pilots_idx >= num_pilots) {
        pilots_idx = 0;
      }
    } else if (in_idx < n_in) {
      out[out_idx * 2] = in[in_idx];
      out[out_idx * 2 + 1] = in[in_idx + 1];
      in_idx += 2;
    } else {
      out[out_idx * 2] = 0.0;
      out[out_idx * 2 + 1] = 0.0;
    }

    out_idx++;
  }
}

static void
modulate(uint8_t* __restrict__ in, size_t in_len, double* __restrict__ samps)
{
  size_t i, j;
  uint8_t current, sym;

  for (i = 0; i < in_len; i++) {
    current = in[i];
    for (j = 0; j < 4; j++) {
      sym = current & 0x3;
      current >>= 2;
      size_t idx = ((i << 2) + j) << 1;
      samps[idx] = (sym & 0x2) ? pp : -pp;
      samps[idx + 1] = (sym & 0x1) ? pp : -pp;
    }
  }
}

static inline void double_to_fixed_with_cp(
    double* __restrict__ d, size_t nfft, size_t nsym, size_t ncp,
    samp_t *out)
{
  size_t i;
  size_t cnt_fft;
  size_t widx = 0;

  for (cnt_fft = 0; cnt_fft < nsym; cnt_fft++) {
    size_t ridx = ((cnt_fft + 1) * nfft - ncp) << 1;
    // get cp
    for (i = 0; i < ncp; i++) {
      double r = d[ridx];
      ridx++;
      double i = d[ridx];
      ridx++;
      out[widx] = double_to_packed_fixed(r, i);
      widx++;
    }
    // get rest of symbol
    ridx = (cnt_fft * nfft) << 1;
    for (i = 0; i < nfft; i++) {
      double r = d[ridx];
      ridx++;
      double i = d[ridx];
      ridx++;
      out[widx] = double_to_packed_fixed(r, i);
      widx++;
    }
  }
}

void encode(uint8_t data[20], samp_t samps[222], tx_info_t *info)
{
  uint32_t i;
  uint8_t frame[24];
  uint8_t encoded[48];
  double modulated[192 * 2];
  double mapped[192 * 2];
  double w[32];
  int ip[10];

  ip[0] = 0;

  // build header, concatenate
  frame[0] = (((info->src) & 0x1F) << 3) |
             (((info->dst) & 0x1C) >> 2);
  frame[1] = (((info->dst) & 0x03) << 6) |
             (((info->r0)  & 0x1F) << 1) |
             (((info->r1)  & 0x10) >> 4);
  frame[2] = (((info->r1)  & 0x0F) << 4) |
             (((info->r2)  & 0x1E) >> 1);
  // reserved section is zero
  frame[3] = (((info->r2)  & 0x01) << 7);
  memcpy(&frame[4], data, 20);

  // channel code
  cc_encode_tb(
      frame, 24,
      encoded,
      info->cc_constr, info->cc_length);

  // map (direct mapping)

  // modulate
  modulate(encoded, 48, modulated);

  // add pilots
  add_pilots(modulated, mapped, 48, 64, 64, info->num_pilots, info->pilots);

  // fft
  for (i = 0; i < 3; i++) {
    cdft(2 * 64, -1, mapped + 2 * 64 * i, ip, w);
  }

  // cast double to fixed point, add cp
  double_to_fixed_with_cp(mapped, 64, 3, 10, samps);
}

void encode_linear_seq(uint64_t n, samp_t* samps)
{
  for (uint64_t i = 0; i < n; i++) {
    samps[i] = double_to_packed_fixed(i * 1.0 * pow(2.0, -15), i * -1.0 * pow(2.0, -15));
  }
}
