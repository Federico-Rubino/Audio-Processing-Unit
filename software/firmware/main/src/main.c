#include <apu.h>
#include <gpio.h>
#include <uart.h>
#include "passthrough.h"

#define UART ((uart_t*) 0x00028000) //base address of UART peripheral
#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral
#define APU  ((apu_t*)  0x00030000) //base address of APU peripheral

int main() {
    apu_load_param(APU, GRAIN_START, 0, 256);
    apu_load_param(APU, GRAIN_LEN, 256, 256);
    apu_load_param(APU, OP_START, 0, 0);
    apu_load_param(APU, OP_LEN, 256, 256);

    while (1)
    {
        if(apu_has_new_grain(APU)){
            apu_start_shader(APU, &(APU->shader_mem));
        }
    }
}
