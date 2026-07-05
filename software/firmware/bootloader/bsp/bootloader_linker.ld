MEMORY
{
    /*intruction memory*/
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    
    /* data memory */
    RAM (rw) : ORIGIN = 0x00020000, LENGTH = 32K
}

SECTIONS
{
    .text : {
        KEEP(*(.text.init))
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
