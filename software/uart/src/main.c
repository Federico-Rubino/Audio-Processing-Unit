#include <stdint.h>
#include "uart.h"

void delay(int count) {
    for (volatile int i = 0; i < count; i++);
}

void main() {
    printuart("Hello from UART! \n");
    delay(1000000);
    printuart("This is a test message. \n");
    delay(1000000);
    printuart("UART communication is working! \n");
    while(1);

}