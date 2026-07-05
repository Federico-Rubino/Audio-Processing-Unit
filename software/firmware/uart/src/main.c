#include <stdint.h>
#include "uart.h"

#define UART ((uart_t*) 0x00028000)
void delay(int count) {
    for (volatile int i = 0; i < count; i++);
}

void main() {
    printuart(UART, "Hello from UART! \n");
    delay(1000000);
    printuart(UART, "This is a test message. \n");
    delay(1000000);
    printuart(UART, "UART communication is working! \n");
    while(1);

}