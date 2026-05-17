#ifndef AUDIO_IO_H
#define AUDIO_IO_H

#include <stdint.h>
#include <stdbool.h>

typedef struct{
    volatile uint32_t status;
    volatile uint32_t ctrl;
    volatile uint32_t base_addr;
    volatile uint32_t num_samples;
} audio_io_t;

#define AUDIO_IO ((audio_io_t*) 0x0002A000) 

#define STATUS_FINISHED       0x01      // bit 0
#define STATUS_NEW_SAMPLE_L   0x02      // bit 1
#define STATUS_NEW_SAMPLE_R   0x04      // bit 2
#define STATUS_AVAIL_SAMPLE_L 0x07F8    // bits 3-10
#define STATUS_AVAIL_SAMPLE_R 0x7F800   // bits 11-18

#define CONTROL_START 0x01
#define CONTROL_CHANNEL 0x02 

static inline void audioIO_copy_grain(uint32_t base_address, uint32_t num_samples, uint8_t channel){
    if(channel == 0){
        AUDIO_IO->ctrl |= CONTROL_CHANNEL;
    }else{
        AUDIO_IO->ctrl &= ~CONTROL_CHANNEL;
    }

    AUDIO_IO->base_addr = base_address;
    AUDIO_IO->num_samples = num_samples;
    AUDIO_IO->ctrl |= CONTROL_START;

    while(!(AUDIO_IO->status & STATUS_FINISHED)){}
}

static inline uint32_t audioIO_get_avail_samples(uint8_t channel){
    if(channel == 0){
        return (AUDIO_IO->status & STATUS_AVAIL_SAMPLE_L) >> 3; 
    }else{
        return (AUDIO_IO->status & STATUS_AVAIL_SAMPLE_R) >> 11;
    }
}

static inline bool audioIO_have_new_sample(uint8_t channel){
    if(channel == 0){
        return (AUDIO_IO->status & STATUS_NEW_SAMPLE_L);
    }else{
        return (AUDIO_IO->status & STATUS_NEW_SAMPLE_R);
    }
}

#endif // AUDIO_IO_H