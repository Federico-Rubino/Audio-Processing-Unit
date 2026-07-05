MEMORY
{
    /*intruction memory*/
    ROM (rx) : ORIGIN = 0x00010000, LENGTH = 64K
    
    /* data memory */
    RAM (rw) : ORIGIN = 0x000200F0, LENGTH = 32K - 240
}

SECTIONS
{
    .text : {
        KEEP(*(.text.init))
        *(.text)
        *(.text.*)
    } > ROM

    .data : {
        . = ALIGN(4);
        _sdata = .;
        /* Add this line right here */
        PROVIDE(__global_pointer$ = . + 0x800);
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
        . = ALIGN(4);        /* Ensure we start on a word boundary */
        _bss_start = .;      /* Capture the start address AFTER alignment */
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4);        /* Ensure we end on a word boundary */
        _bss_end = .;        /* Capture the end address */
    } > RAM

    _stack_top = 0x00027FF0;
}
