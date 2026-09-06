#ifndef DELAY_H
#define DELAY_H
/* generated from delay.shader -- do not hand-edit */

#include <stdint.h>

static const uint32_t delay_words[] = {
    0xc0000000, 0x00000000, 0x00000000, 0x00040001,
    0x80000000, 0x00040101, 0x01000000, 0x18040601,
    0x30000000, 0x00060101, 0x80802020, 0x00040001,
    0x80000000, 0x000a0102, 0x81800000, 0x18040601,
    0xd0000000, 0x00000000, 0x00000000, 0x28040a01,
    0xf0000000, 0x00000000, 0x00000000, 0x00000000,
};

#define D_IN_START 0
#define D_LEN 1
#define D_TEMP_START 2
#define D_DELAY_START 3
#define D_FEEDBACK 4
#define D_OUT_START 5
#define D_VOLUME 6

#endif // DELAY_H
