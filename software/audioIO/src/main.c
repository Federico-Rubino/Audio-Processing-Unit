#include <stdint.h>
#include <audio_io.h>
#include <uart.h>


#define UART ((uart_t*) 0x00028000)
#define AUDIO_IO ((audio_io_t*) 0x0002A000) 

int main(void) {

    for(volatile int i = 0; i < 1000000; i++); 

    printuart(UART,"init\n");
    
    volatile uint32_t test_buffer[128]; 
    for(int i = 0; i < 128; i++){
        test_buffer[i] = 12;
    }

    printuart(UART,"Memory initialized to 12\n");

    audioIO_copy_grain(AUDIO_IO,(uint32_t)test_buffer, 256, 1); 
    
    printuart(UART,"Memory:\n");
    for(int i = 0; i < 128; i++) {
        printuart(UART,"Index [");
        printuart_uint32(i);
        printuart(UART,"] = ");
        printuart_uint32(test_buffer[i]);
        printuart(UART,"\n");
    }

    printuart(UART,"finished\n");

    while(1){
    }
    
    return 0; 
}