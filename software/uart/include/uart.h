#ifndef UART_H
#define UART_H

#include <stdint.h>

typedef struct{
    volatile uint32_t rx; //rx register 0x0h offset
    volatile uint32_t tx; //tx register 0x4h offset
    volatile uint32_t status; //status register 0x8h offset
    volatile uint32_t control; //control register 0xCh offset
} uart_t;

//#define UART ((uart_t*) 0x00028000) //base address of UART peripheral

#define UART_STATUS_TX_FULL BIT(3) //tx full status
#define UART_STATUS_RX_VALID BIT(0) //rx valid status

//ASCII
void putchar(uart_t* uart, char c) {
    //wait transmit buffer not full
    while (uart->status & UART_STATUS_TX_FULL);
    // Write the character to the transmit register
    uart->tx = (uint32_t)c;
}

void printuart(uart_t* uart, const char* str) {
    while (*str) {
        putchar(uart, *str++);
    }
}

char getchar(uart_t* uart) {
    // wait until valid data in receive buffer
    while (!(uart->status & UART_STATUS_RX_VALID));
    //read char receive register
    return (char)(uart->rx & 0xFF);
}

//BYTE
uint8_t uart_read_byte(uart_t* uart){
    while (!(uart->status & UART_STATUS_RX_VALID));
    return (uint8_t)(uart->rx & 0xFF);
}

void uart_write_byte(uart_t* uart, uint8_t data){
    while(uart->status & UART_STATUS_TX_FULL);
    uart->tx = (uint32_t)data;
}

#endif // UART_H
