#include <apu.h>
#include <gpio.h>
#include <uart.h>

#define UART ((uart_t*) 0x00028000) //base address of UART peripheral
#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral
#define APU  ((apu_t*)  0x0002C000) //TODO: update once the shared BRAM is mapped in the block design

// Shader upload wire protocol (host-tools/shader_upload.py is the other end).
// FPGA -> host: SHADER_REQUEST, on BTN_U press.
// host -> FPGA: SHADER_NONE (nothing queued) or SHADER_DATA followed by:
//   shader_start_addr, word_count, word_count words,
//   param_count, param_count * (offset, left_value, right_value)
// FPGA -> host: SHADER_ACK once loaded.
#define SHADER_REQUEST 0xC0
#define SHADER_NONE    0xC1
#define SHADER_DATA    0xC2
#define SHADER_ACK     0xC3

// no hardware timer on this core -- bounded by spin count, not real time
#define SHADER_REQUEST_TIMEOUT_SPINS 10000000u

static uint32_t shader_buf[APU_SHADER_WORDS];

// Polls BTN_U for a rising edge; on press, asks the host for a shader and
// loads/runs whatever comes back. Never blocks unless the host actually
// answers the request (see SHADER_REQUEST_TIMEOUT_SPINS).
static void check_shader_button(apu_t *apu, uart_t *uart, gpio_t *gpio) {
    static uint32_t was_pressed = 0;

    uint32_t pressed = gpio_get_input(gpio, BTN_U) != 0;
    uint32_t rising_edge = pressed && !was_pressed;
    was_pressed = pressed;
    if (!rising_edge) {
        return;
    }

    uart_write_byte(uart, SHADER_REQUEST);

    if (!uart_wait_data(uart, SHADER_REQUEST_TIMEOUT_SPINS)) {
        printuart(uart, "shader request timed out (no host listening?)\n");
        return;
    }

    uint8_t reply = uart_read_byte(uart);
    if (reply == SHADER_NONE) {
        printuart(uart, "host: no shader queued\n");
        return;
    }
    if (reply != SHADER_DATA) {
        printuart(uart, "shader request: unexpected reply byte\n");
        return;
    }

    uint32_t shader_start_addr = uart_read_word(uart);
    uint32_t word_count = uart_read_word(uart);
    if (word_count > APU_SHADER_WORDS) {
        printuart(uart, "shader too large, aborting\n");
        return;
    }
    for (uint32_t i = 0; i < word_count; i++) {
        shader_buf[i] = uart_read_word(uart);
    }

    uint32_t param_count = uart_read_word(uart);
    for (uint32_t i = 0; i < param_count; i++) {
        uint32_t offset = uart_read_word(uart);
        uint32_t left = uart_read_word(uart);
        uint32_t right = uart_read_word(uart);
        apu_load_param(apu, left, right, offset);
    }

    apu_load_shader(apu, shader_start_addr, shader_buf, word_count);
    uart_write_byte(uart, SHADER_ACK);
    printuart(uart, "shader loaded\n");

    // demonstrates the load actually worked; real audio-triggered runs
    // (driven by grain_ready signals) aren't wired up yet
    apu_start_shader(apu, shader_start_addr);
}

int main() {
    printuart(UART, "APU busy: ");
    printuart_uint32(UART, apu_is_busy(APU));
    printuart(UART, "\n");

    while (1) {
        check_shader_button(APU, UART, GPIO);
    }
}
