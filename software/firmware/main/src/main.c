#include <apu.h>
#include <gpio.h>
#include <uart.h>
#include "volume_up.h"

#define Q8_8(x) ((int16_t)((x) * 256.0f))

#define UART ((uart_t*) 0x00028000) //base address of UART peripheral
#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral
#define APU  ((apu_t*)  0x00030000) //base address of APU peripheral

#define NUM_SWITCHES 8
#define GAIN_STEP 0.25f


int16_t select_gain() {
    float gain = 0.0f;
    for (int i = 0; i < NUM_SWITCHES; i++) {
        if (gpio_get_input(GPIO, BIT(i))) {
            gain += GAIN_STEP * (float)(i + 1);
        }
    }
    return Q8_8(gain);
}

int main() {
    apu_load_param(APU, GRAIN_START, 0, 128);
    apu_load_param(APU, GRAIN_LEN, 128, 128);
    apu_load_param(APU, OP_START, 0, 0);
    apu_load_param(APU, OP_LEN, 128, 128);

    while (1)
    {
        if(apu_has_new_grain(APU)){
            int16_t gain = select_gain();
            apu_load_param(APU, GAIN, gain, gain);
            apu_start_shader(APU, 0);
        }
    }
}
