#include <stdint.h>
#include <audio_io.h>
#include <uart.h>


int main(void) {

    for(volatile int i = 0; i < 1000000; i++); 

    printuart("init\n");
    
    volatile uint32_t test_buffer[128]; 
    for(int i = 0; i < 128; i++){
        test_buffer[i] = 12;
    }

    printuart("Memory initialized to 12\n");

    audioIO_copy_grain((uint32_t)test_buffer, 256, 1); 
    
    printuart("Memory:\n");
    for(int i = 0; i < 128; i++) {
        printuart("Index [");
        printuart_uint32(i);
        printuart("] = ");
        printuart_uint32(test_buffer[i]);
        printuart("\n");
    }

    printuart("finished\n");

    while(1){
    }
    
    return 0; 
}