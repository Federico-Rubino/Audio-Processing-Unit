#include <uart.h>
#include <audio_io.h>
#include <gpio.h>
#include <apu.h>


#define UART ((uart_t*) 0x00028000) //base address of UART peripheral
#define AUDIO_IO ((audio_io_t*) 0x0002A000) //base addres for audioIO
#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral
#define APU ((apu_t*) 0x0002C000) //MODIFICARE BASE ADDRESSSSSSSSSS

int main(){
    uint32_t sample_buffer_l[128];
    uint32_t sample_buffer_r[128];
    while(1){
        if(audioIO_get_avail_samples(AUDIO_IO, 0) == 256){
            audioIO_copy_grain(AUDIO_IO, (uint32_t)sample_buffer_l, 256, 0);
            apu_copy(APU, (uint32_t)sample_buffer_l, 0);
            apu_audio_out(APU, 0, 0);

        }
        if(audioIO_get_avail_samples(AUDIO_IO, 1) == 256){
            audioIO_copy_grain(AUDIO_IO, (uint32_t)sample_buffer_r, 256, 1);
            apu_copy(APU, (uint32_t)sample_buffer_r, 0);
            apu_audio_out(APU, 1, 0);
        }
    }
}