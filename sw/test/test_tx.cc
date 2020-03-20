#include "gtest/gtest.h"

extern "C" {
#include "../tx.c"
};

#include <math.h>

namespace {

TEST(state_update, inputs) {
  constraint_t state = 0;
  EXPECT_EQ(0, update_state(state, 0));
  EXPECT_EQ(1, update_state(state, 1));
  EXPECT_EQ(0, update_state(state, 2));
  EXPECT_EQ(1, update_state(state, 3));

  state = 1;
  EXPECT_EQ(2, update_state(state, 0));
  EXPECT_EQ(3, update_state(state, 1));
  EXPECT_EQ(2, update_state(state, 2));
  EXPECT_EQ(3, update_state(state, 3));
}

TEST(next_in_bit, some_inputs) {
  uint8_t inputs[] = { 0, 1, 2, 3, 4, 0xFF, 0xFE, 0xFC, 0xFB, 0xFA };
  uint8_t *in_ptr = inputs;
  uint8_t byte = 0, pos = 0xFF;
  uint32_t i, j;

  for (i = 0; i < 2; i++) {
    for (j = 0; j < 8; j++) {
      next_in_bit(&in_ptr, &byte, &pos);
      EXPECT_EQ(byte & 0x1, (inputs[i] >> j) & 0x1);
    }
  }
}

TEST(cc_encode_tb, two_bit_constraint) {
  constraint_t constrs[2] = { 1, 3 };
  uint8_t constr_len = 2;
  uint8_t input[] = { 0x36, 0xC9 };
  uint8_t output[4];

  cc_encode_tb(input, 10, output, constrs, constr_len);

  EXPECT_EQ(output[0], 0x79);
  EXPECT_EQ(output[1], 0xB2);
  EXPECT_EQ(output[2], 0x2C);
  EXPECT_EQ(output[3], 0x97);
}

TEST(modulate, qspk) {
  uint8_t inputs[] = { 0xE4, 0x39, 0x4E, 0x93 };
  double outputs[32];

  modulate(inputs, 4, outputs);

  EXPECT_EQ(outputs[ 0], -1.0);
  EXPECT_EQ(outputs[ 1], -1.0);
  EXPECT_EQ(outputs[ 2], -1.0);
  EXPECT_EQ(outputs[ 3],  1.0);
  EXPECT_EQ(outputs[ 4],  1.0);
  EXPECT_EQ(outputs[ 5], -1.0);
  EXPECT_EQ(outputs[ 6],  1.0);
  EXPECT_EQ(outputs[ 7],  1.0);

  EXPECT_EQ(outputs[ 8], -1.0);
  EXPECT_EQ(outputs[ 9],  1.0);
  EXPECT_EQ(outputs[10],  1.0);
  EXPECT_EQ(outputs[11], -1.0);
  EXPECT_EQ(outputs[12],  1.0);
  EXPECT_EQ(outputs[13],  1.0);
  EXPECT_EQ(outputs[14], -1.0);
  EXPECT_EQ(outputs[15], -1.0);

  EXPECT_EQ(outputs[16],  1.0);
  EXPECT_EQ(outputs[17], -1.0);
  EXPECT_EQ(outputs[18],  1.0);
  EXPECT_EQ(outputs[19],  1.0);
  EXPECT_EQ(outputs[20], -1.0);
  EXPECT_EQ(outputs[21], -1.0);
  EXPECT_EQ(outputs[22], -1.0);
  EXPECT_EQ(outputs[23],  1.0);

  EXPECT_EQ(outputs[24],  1.0);
  EXPECT_EQ(outputs[25],  1.0);
  EXPECT_EQ(outputs[26], -1.0);
  EXPECT_EQ(outputs[27], -1.0);
  EXPECT_EQ(outputs[28], -1.0);
  EXPECT_EQ(outputs[29],  1.0);
  EXPECT_EQ(outputs[30],  1.0);
  EXPECT_EQ(outputs[31], -1.0);
}

TEST(double_to_packed_fixed, packing) {
  double one = 1.0 - pow(2.0, -15);
  EXPECT_EQ(double_to_packed_fixed( one,  one), 0x7FFF7FFFU);
  EXPECT_EQ(double_to_packed_fixed(-1.0,  one), 0x80007FFFU);
  EXPECT_EQ(double_to_packed_fixed( one, -1.0), 0x7FFF8000U);
  EXPECT_EQ(double_to_packed_fixed(-1.0, -1.0), 0x80008000U);

  EXPECT_EQ(double_to_packed_fixed( 0.5,  0.5), 0x40004000U);
  EXPECT_EQ(double_to_packed_fixed(-0.5,  0.5), 0xC0004000U);
  EXPECT_EQ(double_to_packed_fixed( 0.5, -0.5), 0x4000C000U);
  EXPECT_EQ(double_to_packed_fixed(-0.5, -0.5), 0xC000C000U);
}

TEST(cfft, inverse_single_tone) {
  double data[64 * 2] = { 0.0 };
  double w[32];
  int ip[10];
  int i;
  ip[0] = 0;

  data[0] = 1.0;
  data[1] = -1.0;

  cdft(2 * 64, -1, data, ip, w);

  for (i = 0; i < 64 * 2; i++) {
    auto expected = (i & 0x1) ? -1.0 : 1.0;
    EXPECT_NEAR(data[i], expected, 0.00001);
  }
}

TEST(cfft, inverse_flat) {
  double data[64 * 2];
  double w[32];
  int ip[10];
  int i;
  auto epsilon = 0.00001;
  ip[0] = 0;

  for (i = 0; i < 64 * 2; i++) {
    data[i] = 1.0;
  }

  cdft(2 * 64, -1, data, ip, w);

  EXPECT_NEAR(data[0], 64.0, epsilon);
  EXPECT_NEAR(data[1], 64.0, epsilon);

  for (i = 2; i < 64 * 2; i++) {
    EXPECT_NEAR(data[i], 0.0, epsilon);
  }
}

TEST(encode, all_zeros) {
  uint8_t data[20] = { 0 };
  samp_t samps[222];
  constraint_t constrs[] = { 0x1, 0x3 };
  tx_info_t info = {
    .src = 0,
    .dst = 1,
    .time = 0,
    .r0 = 2,
    .r1 = 3,
    .r2 = 4,
    .cc_length = 2,
    .cc_constr = constrs,
  };

  encode(data, samps, &info);

  // TODO check output
}

};
