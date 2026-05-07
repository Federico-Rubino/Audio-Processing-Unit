MEMORY
{
    /*intruction memory*/
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    
    /* data memory */
    RAM (rw) : ORIGIN = 0x00001000, LENGTH = 4K
}

SECTIONS
{
    .text : {
        *(.text)
        *(.text.*)
    } > ROM

    .data : {
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        *(.rodata)    
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
    } > RAM

    /* non init var */
    .bss : {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
