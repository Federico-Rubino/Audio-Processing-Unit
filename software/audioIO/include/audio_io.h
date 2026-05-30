#ifndef AUDIO_IO_H
#define AUDIO_IO_H

#include <stdint.h>
#include <stdbool.h>
#include <bitops.h>

#define AUDIOIO_CHANNEL_LEFT 0
#define AUDIOIO_CHANNEL_RIGHT 1

typedef struct{
    volatile uint32_t status;
    volatile uint32_t ctrl;
    volatile uint32_t base_addr;
    volatile uint32_t num_samples;
} audio_io_t;

//#define AUDIO_IO ((audio_io_t*) 0x0002A000) 

#define STATUS_FINISHED       BIT(0)      // bit 0
#define STATUS_NEW_SAMPLE_L   BIT(1)      // bit 1
#define STATUS_NEW_SAMPLE_R   BIT(2)      // bit 2
#define STATUS_AVAIL_SAMPLE_L GENMASK(12, 3)  // bits 3-12
#define STATUS_AVAIL_SAMPLE_R GENMASK(22, 13)   // bits 13-22

#define CONTROL_START BIT(0) 
#define CONTROL_CHANNEL BIT(1)


static inline void audioIO_copy_grain(audio_io_t* audio_io, uint32_t base_address, uint32_t num_samples, uint8_t channel){
    uint32_t ctrl_val = 0;

    if(channel == 0){
        ctrl_val = 0; // Bit 1 is 0
    } else {
        ctrl_val = CONTROL_CHANNEL; // Bit 1 is 1
    }

    audio_io->base_addr = base_address; 
    audio_io->num_samples = num_samples;

    audio_io->ctrl = ctrl_val | CONTROL_START;

    audio_io->ctrl = ctrl_val;

    while(!(audio_io->status & STATUS_FINISHED)){}
}
static inline uint32_t audioIO_get_avail_samples(audio_io_t* audio_io, uint8_t channel){
    if(channel == 0){
        return (audio_io->status & STATUS_AVAIL_SAMPLE_L) >> 3; 
    }else{
        return (audio_io->status & STATUS_AVAIL_SAMPLE_R) >> 13;
    }
}

static inline bool audioIO_have_new_sample(audio_io_t* audio_io, uint8_t channel){
    if(channel == 0){
        return (audio_io->status & STATUS_NEW_SAMPLE_L);
    }else{
        return (audio_io->status & STATUS_NEW_SAMPLE_R);
    }
}

#endif // AUDIO_IO_H

