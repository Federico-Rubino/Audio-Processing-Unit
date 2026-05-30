#include <uart.h>
#include <audio_io.h>
#include <gpio.h>
#include <apu.h>


#define UART ((uart_t*) 0x00028000) //base address of UART peripheral
#define AUDIO_IO ((audio_io_t*) 0x0002A000) //base addres for audioIO
#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral
#define APU ((apu_t*) 0x0002B000) 



int main(){
    uint32_t sample_buffer_l[128];
    uint32_t sample_buffer_r[128];
    uint32_t state;
    uint32_t en;
    state = apu_status_state(APU);
    printuart(UART, "APU State: ");
    printuart_uint32(UART, state);
    printuart(UART, "\n");
    while(1){
        if(audioIO_get_avail_samples(AUDIO_IO, 0) == 256){
            audioIO_copy_grain(AUDIO_IO, (uint32_t)sample_buffer_l, 128, AUDIOIO_CHANNEL_LEFT);
            //for(int i = 0; i < 128; i++){
                //printuart(UART, "\n");
                //printuart_int16(UART, sample_buffer_l[i]);
                //printuart(UART, "\n");
                //printuart_int16(UART, sample_buffer_l[i] >> 16);
            //}
            //COPY
            apu_wait(APU);
            apu_copy(APU, (uint32_t)sample_buffer_l, 0, 2, 0, 128);
            apu_start(APU);
            apu_start_rst(APU);

            //AUDIO OUT
            apu_wait(APU);
            apu_audio_out(APU, 0, 2, 0, 128, APU_CHANNEL_LEFT);
            apu_start(APU);
            apu_start_rst(APU);
            en = apu_status_out_en(APU);
            printuart(UART, "APU ena: ");
            printuart_uint32(UART, en);
            printuart(UART, "\n");

        }
        if(audioIO_get_avail_samples(AUDIO_IO, 1) == 256){
            audioIO_copy_grain(AUDIO_IO, (uint32_t)sample_buffer_r, 256, AUDIOIO_CHANNEL_RIGHT);
            //COPY
            apu_wait(APU);
            apu_copy(APU, (uint32_t)sample_buffer_l, 0, 2, 0, 256);
            apu_start(APU);
            apu_start_rst(APU);

            //AUDIO OUT
            apu_wait(APU);
            apu_audio_out(APU, 0, 2, 0, 256, APU_CHANNEL_RIGHT);
            apu_start(APU);
            apu_start_rst(APU);
        }
    }
}