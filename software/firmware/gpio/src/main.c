#include <gpio.h>
#include <stdbool.h>

void delay(volatile uint32_t count) {
    while (count--) {
        __asm__ volatile ("nop");
    }
}

int main() {
    int i = 0;
    bool direction = true;

    while (1) {

        gpio_set_output(1 << i, 1);
        delay(150000);
        gpio_set_output(1 << i, 0);

        if (direction) {
            i++;
        } else {
            i--;
        }

        if (i == 7) {
            direction = false;
        }

        if (i == 0) {
            direction = true;
        }
    }

    return 0;
}