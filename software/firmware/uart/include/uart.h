#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <bitops.h>

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

//non-blocking: 1 if a byte is waiting, 0 otherwise
uint32_t uart_has_data(uart_t* uart){
    return (uart->status & UART_STATUS_RX_VALID) != 0;
}

//bounded wait: 1 if a byte showed up within max_spins, 0 on timeout.
//spin-count based -- this core has no hardware timer to measure real time.
uint32_t uart_wait_data(uart_t* uart, uint32_t max_spins){
    uint32_t spins = 0;
    while (!uart_has_data(uart)) {
        if (++spins > max_spins) {
            return 0;
        }
    }
    return 1;
}

void uart_write_byte(uart_t* uart, uint8_t data){
    while(uart->status & UART_STATUS_TX_FULL);
    uart->tx = (uint32_t)data;
}

uint32_t uart_read_word(uart_t* uart){
    uint32_t b0 = (uint32_t)uart_read_byte(uart);
    uint32_t b1 = (uint32_t)uart_read_byte(uart);
    uint32_t b2 = (uint32_t)uart_read_byte(uart);
    uint32_t b3 = (uint32_t)uart_read_byte(uart);

    return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
}

void printuart_uint32(uart_t* uart, uint32_t data)
{
    char buffer[11]; // max "4294967295" + '\0'
    int i = 0;

    // Special case for 0
    if (data == 0) {
        uart_write_byte(uart, '0');
        return;
    }

    // Convert number to ASCII (reversed)
    while (data > 0) {
        buffer[i++] = (data % 10) + '0';
        data /= 10;
    }

    // Send in correct order
    while (i > 0) {
        uart_write_byte(uart, buffer[--i]);
    }
}

void printuart_uint16(uart_t* uart, uint16_t data)
{
    char buffer[6]; // max "65535" + '\0'
    int i = 0;

    // Special case for 0
    if (data == 0) {
        uart_write_byte(uart, '0');
        return;
    }

    // Convert number to string (reversed)
    while (data > 0) {
        buffer[i++] = (data % 10) + '0';
        data /= 10;
    }

    // Send characters in correct order
    while (i > 0) {
        uart_write_byte(uart, buffer[--i]);
    }
}

void printuart_int16(uart_t* uart, int16_t data)
{
    // Handle negative numbers
    if (data < 0) {
        uart_write_byte(uart, '-');
        data = -data;
    }

    char buffer[6]; // max "-32768" + '\0'
    int i = 0;

    // Special case for 0
    if (data == 0) {
        uart_write_byte(uart, '0');
        return;
    }

    // Convert to ASCII
    while (data > 0) {
        buffer[i++] = (data % 10) + '0';
        data /= 10;
    }

    // Send in correct order
    while (i > 0) {
        uart_write_byte(uart, buffer[--i]);
    }
}

void printuart_int32(uart_t* uart, int32_t data)
{
    // Handle negative numbers
    if (data < 0) {
        uart_write_byte(uart, '-');
        data = -data;
    }

    char buffer[11]; // max "-2147483648" + '\0'
    int i = 0;

    // Special case for 0
    if (data == 0) {
        uart_write_byte(uart, '0');
        return;
    }

    // Convert to ASCII
    while (data > 0) {
        buffer[i++] = (data % 10) + '0';
        data /= 10;
    }

    // Send in correct order
    while (i > 0) {
        uart_write_byte(uart, buffer[--i]);
    }
}
#endif // UART_H
