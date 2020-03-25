#ifndef __TX_H
#define __TX_H

#include <stddef.h>
#include <stdint.h>

typedef uint32_t samp_t;
extern const double samp_mult;
typedef uint16_t constraint_t;
typedef uint32_t res_t;

// Ooura Prototype
extern void cdft(int, int, double *, int *, double *);

typedef struct {
  uint8_t *base;
  uint64_t length;
} marray;

typedef struct {
  uint8_t pos;
  double real;
  double imag;
} pilot_tone;

typedef struct {
  uint8_t src;
  uint8_t dst;
  uint16_t time; // TODO necessary?
  uint8_t r0, r1, r2;
  uint8_t cc_length;
  constraint_t *cc_constr;
  uint8_t num_pilots;
  // must be in order of increasing pos
  pilot_tone* pilots;
} tx_info_t;

int pilot_compare(const void* e1, const void* e2);

extern void encode(uint8_t data[20], samp_t samps[222], tx_info_t *info);

extern void encode_linear_seq(uint64_t n, samp_t* samps);

extern void get_stf(uint32_t stf[160]);
extern void get_ltf(uint32_t ltf[160]);

#endif /* __TX_H */
