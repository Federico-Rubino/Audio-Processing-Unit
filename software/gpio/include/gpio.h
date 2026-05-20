#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>
#include <bitops.h>

typedef struct{
    volatile uint32_t input; //input register 0x0h offset
    volatile uint32_t gpio_separator;
    volatile uint32_t output; //output register 0x4h offset
} gpio_t;

//#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral

#define LED_00 BIT(0)
#define LED_01 BIT(1)
#define LED_02 BIT(2)
#define LED_03 BIT(3)
#define LED_04 BIT(4)
#define LED_05 BIT(5)
#define LED_06 BIT(6)
#define LED_07 BIT(7)

#define SW_00 BIT(0)
#define SW_01 BIT(1)
#define SW_02 BIT(2)
#define SW_03 BIT(3)
#define SW_04 BIT(4)
#define SW_05 BIT(5)
#define SW_06 BIT(6)
#define SW_07 BIT(7)
#define BTN_D BIT(8)
#define BTN_L BIT(9)
#define BTN_R BIT(10)
#define BTN_U BIT(11)


static inline void gpio_set_output(gpio_t* gpio, uint8_t mask, uint8_t value)
{
    if (value) {
        gpio->output |= mask;    
    } else {
        gpio->output &= ~mask;  
    }
}

static inline uint32_t gpio_get_input(gpio_t* gpio, uint16_t mask) {
    return gpio->input & mask;
}


#endif // GPIO_H
