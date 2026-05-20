#ifndef APU_H
#define APU_H

#include <stdint.h>
#include <bitops.h>

typedef struct {
    volatile uint32_t status;
    volatile uint32_t opcode;
    volatile uint32_t in_buffer1_start;
    volatile uint32_t in_buffer1_offset;
    volatile uint32_t in_buffer2_start;
    volatile uint32_t in_buffer2_offset;
    volatile uint32_t in_buffer3_start;
    volatile uint32_t in_buffer3_offset;
    volatile uint32_t out_buffer1_start;
    volatile uint32_t out_buffer1_offset;
    volatile uint32_t out_buffer2_start;
    volatile uint32_t out_buffer2_offset;
    volatile uint32_t action_size;
    volatile uint32_t block_size;
    volatile uint32_t param;
    volatile uint32_t start_ram_address;
    volatile uint32_t left_right;
    volatile uint32_t start;
} apu_t;

typedef struct {
    uint32_t sample_select; //0 for sample 15:0; 1 for sample 31:16
    uint32_t block_select; 
    uint32_t address; //0-1023

} apu_buffer_offset_t;

typedef struct {
    uint32_t opcode;
    uint32_t in1_start;
    apu_buffer_offset_t in1_offset;
    uint32_t in2_start;
    apu_buffer_offset_t in2_offset;
    uint32_t in3_start;
    apu_buffer_offset_t in3_offset;
    uint32_t out1_start;
    apu_buffer_offset_t out1_offset;
    uint32_t out2_start;
    apu_buffer_offset_t out2_offset;
    uint32_t action_size;
    uint32_t block_size;

    uint32_t param1;
    uint32_t param2;
    uint32_t start_ram_address;
    uint32_t left_right;
} apu_cmd_t;


//status register mask
#define APU_STATUS_READY   BIT(0)  //1 if ready 0 if running
#define APU_STATUS_RESULT GENMASK(31, 16)
#define APU_STATUS_RESERVED GENMASK(15, 1) //future use

//opcode register mask
#define APU_OPCODE GENMASK(3,0)

//buffer offset register mask
#define APU_BUFFER_OFFSET_SAMPLE BIT(17) //0 for sample 15:0; 1 for sample 31:16
#define APU_BUFFER_OFFSET_BLOCK_SELECT GENMASK(16, 10)
#define APU_BUFFER_OFFSET_ADDRESS GENMASK(9, 0)

//action size register mask
#define APU_ACTION_SIZE GENMASK(17, 0)

//block size register mask
#define APU_BLOCK_SIZE GENMASK(9, 0)

//param register mask
#define APU_PARAM_1 GENMASK(15, 0)
#define APU_PARAM_2 GENMASK(31, 16)

//left right register mask
#define APU_LEFT_RIGHT_LEFT BIT(0) //0 left; 1 right

//start register mask
#define APU_START_BIT BIT(0) //1 to start

//opcode
#define APU_OPCODE_COPY 0x0
#define APU_OPCODE_AUDIO_OUT 0x1

//#define APU ((apu_t*) 0x0002C000) //MODIFICARE BASE ADDRESSSSSSSSSS

static inline int apu_ready(apu_t* apu) {
    return (apu->status & APU_STATUS_READY) != 0;
}

static inline void apu_start(apu_t* apu){
    apu->start = APU_START_BIT;
}

static inline void apu_start_rst(apu_t* apu){
    apu->start = 0;
}

static inline void apu_wait(apu_t* apu){
    while(!apu_ready(apu));
}

static inline uint32_t apu_result(apu_t* apu){
    return (apu->status & APU_STATUS_RESULT) >> 16;
}

static inline uint32_t apu_buffer_offset_composer(apu_buffer_offset_t offset){
    return (offset.sample_select << 17) | (offset.block_select << 10) | offset.address;
}

int apu_execute(apu_t* apu, const apu_cmd_t *cmd){
    apu_wait(apu);

    apu->opcode = cmd->opcode;
    apu->in_buffer1_start = cmd->in1_start;
    apu->in_buffer1_offset = apu_buffer_offset_composer(cmd->in1_offset);
    apu->in_buffer2_start = cmd->in2_start;
    apu->in_buffer2_offset = apu_buffer_offset_composer(cmd->in2_offset);
    apu->in_buffer3_start = cmd->in3_start;
    apu->in_buffer3_offset = apu_buffer_offset_composer(cmd->in3_offset);

    apu->out_buffer1_start = cmd->out1_start;
    apu->out_buffer1_offset = apu_buffer_offset_composer(cmd->out1_offset);
    apu->out_buffer2_start = cmd->out2_start;
    apu->out_buffer2_offset = apu_buffer_offset_composer(cmd->out2_offset);

    apu->action_size=cmd->action_size;
    apu->block_size=cmd->block_size;
    apu->param=cmd->param1;

    apu->start_ram_address=cmd->start_ram_address;
    apu->left_right=cmd->left_right;

    apu_start(apu);
    apu_start_rst(apu);

    return 0;
}

int apu_copy(apu_t* apu, uint32_t mem_addr_start, uint32_t offset){}

int apu_audio_out(apu_t* apu, uint32_t channel, uint32_t offset){}









 

#endif // APU_H
