#ifndef APU_H
#define APU_H

#include <stdint.h>
#include <bitops.h>

#define APU_SHADER_WORDS 1022
#define APU_PARAM_WORDS 512

typedef struct {
    volatile uint32_t status;
    volatile uint32_t control;
    volatile uint32_t shader_mem[APU_SHADER_WORDS];
    volatile uint32_t param_mem_left[APU_PARAM_WORDS];
    volatile uint32_t param_mem_right[APU_PARAM_WORDS];
} apu_t;


//status register mask
//bit 0 reserved
#define APU_MEM_BUSY_MASK   BIT(1)  //1 if busy
#define APU_NEW_GRAINS_AVAIL_MASK BIT(2) //1 if new grains available

#define APU_CONTROL_START_MASK BIT(0) //1 to start processing the shader
#define APU_SHADER_START_ADDR_MASK GENMASK(11,1)
//#define APU ((apu_t*) 0x0002B000)


//busy check
uint32_t apu_is_busy(apu_t* apu){
    return (apu->status & APU_MEM_BUSY_MASK) != 0;
}

//new grain check
uint32_t apu_has_new_grain(apu_t* apu){
    return (apu->status & APU_NEW_GRAINS_AVAIL_MASK) != 0;
}

//start shader processing
uint32_t apu_start_shader(apu_t* apu, uint32_t shader_start_addr){
    if(apu_is_busy(apu) != 0){ // apu is busy so error
        return 1;
    }
    apu->control = (APU_SHADER_START_ADDR_MASK & (shader_start_addr << 1)) | APU_CONTROL_START_MASK;
    while(apu_is_busy(apu) == 0){}
    apu->control &= ~APU_CONTROL_START_MASK;
    return 0;
}

//load shader
uint32_t apu_load_shader(apu_t* apu, uint32_t shader_start_addr, uint32_t* shader, uint32_t shader_dim){
    if (shader_start_addr + shader_dim > APU_SHADER_WORDS){
        return 1;
    }
    for(uint32_t i = 0; i < shader_dim; i++){
        apu->shader_mem[shader_start_addr+i] = shader[i];
    }
    return 0;
}

//load param
uint32_t apu_load_param(apu_t* apu, uint32_t param_left, uint32_t param_right, uint32_t offset){
    if (offset >= APU_PARAM_WORDS){
        return 1;
    }

    apu->param_mem_left[offset] = param_left;
    apu->param_mem_right[offset] = param_right;

    return 0;
}









 

#endif // APU_H
