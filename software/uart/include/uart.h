#include <stdint.h>

typedef struct{
    volatile uint32_t rx; //rx register 0x0h offset
    volatile uint32_t tx; //tx register 0x4h offset
    volatile uint32_t status; //status register 0x8h offset
    volatile uint32_t control; //control register 0xCh offset
} uart_t;

#define UART ((uart_t*) 0x2000) //base address of UART peripheral

#define UART_STATUS_TX_FULL 0x08 //tx full status
#define UART_STATUS_RX_VALID 0x01 //rx valid status

//ASCII
void putchar(char c) {
    // Wait until the transmit buffer is not full
    while (UART->status & UART_STATUS_TX_FULL);
    // Write the character to the transmit register
    UART->tx = (uint32_t)c;
}

void printuart(const char* str) {
    while (*str) {
        putchar(*str++);
    }
}

char getchar() {
    // Wait until there is valid data in the receive buffer
    while (!(UART->status & UART_STATUS_RX_VALID));
    // Read the character from the receive register
    return (char)(UART->rx & 0xFF);
}

//BYTE
uint8_t uart_read_byte(){
    while (!(UART->status & UART_STATUS_RX_VALID));
    return (uint8_t)(UART->rx & 0xFF);
}

void uart_write_byte(uint8_t data){
    while(UART->status & UART_STATUS_TX_FULL);
    UART->tx = (uint32_t)data;
}

