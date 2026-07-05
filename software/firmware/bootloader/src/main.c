#include <stdint.h>
#include "uart.h"

#define READY_SIGNAL 0xAA
#define ACK_SIGNAL 0xAB
#define CMD_LOAD_CHUNK 0x01
#define CMD_FINISHED 0x02


uint32_t uart_read_word(){
    uint32_t b0 = (uint32_t)uart_read_byte();
    uint32_t b1 = (uint32_t)uart_read_byte();
    uint32_t b2 = (uint32_t)uart_read_byte();
    uint32_t b3 = (uint32_t)uart_read_byte();

    return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
}

void jump_to_main(){
    __asm__ volatile (
        "li t0, 0x00010000 \n"
        "jr t0 \n"
    );
}

void bootloader(){
    
    uart_write_byte(READY_SIGNAL); //bootloader ready signal

    while(1){
        uint8_t cmd = uart_read_byte();
        
        if(cmd == CMD_FINISHED){
            break;
        } else if (cmd == CMD_LOAD_CHUNK){

            uint32_t destination_address = uart_read_word();
            uint32_t offset = uart_read_word();

            volatile uint32_t *mem_ptr = (volatile uint32_t *)destination_address;

            for (uint32_t i = 0; i < offset; i++){
                mem_ptr[i] = uart_read_word();
            }

            uart_write_byte(ACK_SIGNAL);
        }
    }

    printuart("Exit bootloader \n");

    jump_to_main();

    printuart("ERROR: cannot jump to main \n");
    while(1);

}

