#ifndef BITOPS_H
#define BITOPS_H
#include <stdint.h>

#define BIT(n) (1U << (n))
#define GENMASK(h, l) (((~0u) << (l)) & (~0u >> (31 - (h))))

#endif //BITOPS_H