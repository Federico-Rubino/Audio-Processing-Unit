#include <stdint.h>
#include <audio_io.h>
#include <uart.h>


void printuart_uint32(uint32_t num) {
    if (num == 0) {
        printuart("0");
        return;
    }
    char buffer[12];
    buffer[11] = '\0';
    int i = 10;
    while (num > 0) {
        buffer[i] = (num % 10) + '0';
        num /= 10;
        i--;
    }
    printuart(&buffer[i + 1]);
}

int main(void) {

    for(volatile int i = 0; i < 10000000; i++); 

    printuart("init\n");
    
    uint32_t test_buffer[4]; 
    for(int i = 0; i < 4; i++){
        test_buffer[i] = 0;
    }

    printuart("Memory initialized to 0. Polling for audio hardware...\n");

    //4 sample test
    uint32_t avail_samples = 0;
    while(avail_samples < 4) {
        avail_samples = audioIO_get_avail_samples(0); 
    
        printuart("Raw Status Reg: ");
        printuart_uint32(AUDIO_IO->status);
        printuart(" | Extracted Avail: ");
        printuart_uint32(avail_samples);
        printuart("\n");
        
        for(volatile int i = 0; i < 5000000; i++); 
    }

    printuart("Samples ready\n");

    audioIO_copy_grain((uint32_t)test_buffer, 4, 0); 
    
    printuart("Memory:\n");
    for(int i = 0; i < 4; i++) {
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