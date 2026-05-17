#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

typedef struct{
    volatile uint32_t input; //input register 0x0h offset
    volatile uint32_t gpio_separator;
    volatile uint32_t output; //output register 0x4h offset
} gpio_t;

#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral

#define LED_00 0x01
#define LED_01 0x02
#define LED_02 0x04
#define LED_03 0x08
#define LED_04 0x10
#define LED_05 0x20
#define LED_06 0x40
#define LED_07 0x80

#define SW_00 0x01
#define SW_01 0x02
#define SW_02 0x04
#define SW_03 0x08
#define SW_04 0x10
#define SW_05 0x20
#define SW_06 0x40
#define SW_07 0x80
#define BTN_D 0x100
#define BTN_L 0x200
#define BTN_R 0x400
#define BTN_U 0x800


static inline void gpio_set_output(uint8_t mask, uint8_t value)
{
    if (value) {
        GPIO->output |= mask;    
    } else {
        GPIO->output &= ~mask;  
    }
}

static inline uint32_t gpio_get_input(uint16_t mask) {
    return GPIO->input & mask;
}


#endif // GPIO_H
