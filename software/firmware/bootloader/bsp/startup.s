.section .text.init
.global _start
.global bootloader

_start:
    # stack pointer init (x2)
    # _stack_top from linker.ld
    la sp, _stack_top

    # put 0 in all global non init var
    la t0, _bss_start
    la t1, _bss_end
    bge t0, t1, end_init_bss
loop_init_bss:
    sw x0, 0(t0)
    addi t0, t0, 4
    blt t0, t1, loop_init_bss
end_init_bss:

    call bootloader

_exit:
    j _exit
