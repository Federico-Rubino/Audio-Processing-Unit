	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
# GNU C17 (13.2.0-11ubuntu1+12) version 13.2.0 (riscv64-unknown-elf)
#	compiled by GNU C version 13.2.0, GMP version 6.3.0, MPFR version 4.2.1, MPC version 1.3.1, isl version isl-0.26-GMP

# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed: -mabi=ilp32 -misa-spec=20191213 -march=rv32i -O2 -ffreestanding
	.text
	.align	2
	.globl	putchar
	.type	putchar, @function
putchar:
.L2:
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(a0)		# _1, uart_5(D)->status
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp139, _1
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L2	#, tmp139,,
# ../uart/include/uart.h:24:     uart->tx = (uint32_t)c;
	sw	a1,4(a0)	# c, uart_5(D)->tx
# ../uart/include/uart.h:25: }
	ret	
	.size	putchar, .-putchar
	.align	2
	.globl	printuart
	.type	printuart, @function
printuart:
# ../uart/include/uart.h:28:     while (*str) {
	lbu	a4,0(a1)	# _1,* str
	beq	a4,zero,.L15	#, _1,,
.L8:
# ../uart/include/uart.h:29:         putchar(uart, *str++);
	addi	a1,a1,1	#, str, str
.L7:
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(a0)		# _8, uart_7(D)->status
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp140, _8
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L7	#, tmp140,,
# ../uart/include/uart.h:24:     uart->tx = (uint32_t)c;
	sw	a4,4(a0)	# _1, uart_7(D)->tx
# ../uart/include/uart.h:28:     while (*str) {
	lbu	a4,0(a1)	# _1,* str
	bne	a4,zero,.L8	#, _1,,
.L15:
# ../uart/include/uart.h:31: }
	ret	
	.size	printuart, .-printuart
	.align	2
	.globl	getchar
	.type	getchar, @function
getchar:
.L17:
# ../uart/include/uart.h:35:     while (!(uart->status & UART_STATUS_RX_VALID));
	lw	a5,8(a0)		# _1, uart_5(D)->status
# ../uart/include/uart.h:35:     while (!(uart->status & UART_STATUS_RX_VALID));
	andi	a5,a5,1	#, tmp139, _1
# ../uart/include/uart.h:35:     while (!(uart->status & UART_STATUS_RX_VALID));
	beq	a5,zero,.L17	#, tmp139,,
# ../uart/include/uart.h:37:     return (char)(uart->rx & 0xFF);
	lw	a0,0(a0)		# _3, uart_5(D)->rx
# ../uart/include/uart.h:38: }
	andi	a0,a0,0xff	#, _3
	ret	
	.size	getchar, .-getchar
	.align	2
	.globl	uart_read_byte
	.type	uart_read_byte, @function
uart_read_byte:
.L21:
	lw	a5,8(a0)		# _5, uart_2(D)->status
	andi	a5,a5,1	#, tmp139, _5
	beq	a5,zero,.L21	#, tmp139,,
	lw	a0,0(a0)		# _7, uart_2(D)->rx
	andi	a0,a0,0xff	#, _7
	ret	
	.size	uart_read_byte, .-uart_read_byte
	.align	2
	.globl	uart_write_byte
	.type	uart_write_byte, @function
uart_write_byte:
.L25:
	lw	a5,8(a0)		# _5, uart_2(D)->status
	andi	a5,a5,8	#, tmp139, _5
	bne	a5,zero,.L25	#, tmp139,,
	sw	a1,4(a0)	# data, uart_2(D)->tx
	ret	
	.size	uart_write_byte, .-uart_write_byte
	.align	2
	.globl	uart_read_word
	.type	uart_read_word, @function
uart_read_word:
.L28:
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	lw	a5,8(a0)		# _21, uart_7(D)->status
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	andi	a5,a5,1	#, tmp156, _21
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	beq	a5,zero,.L28	#, tmp156,,
# ../uart/include/uart.h:43:     return (uint8_t)(uart->rx & 0xFF);
	lw	a1,0(a0)		# _23, uart_7(D)->rx
	andi	a1,a1,255	#, _24, _23
.L29:
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	lw	a5,8(a0)		# _18, uart_7(D)->status
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	andi	a5,a5,1	#, tmp157, _18
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	beq	a5,zero,.L29	#, tmp157,,
# ../uart/include/uart.h:43:     return (uint8_t)(uart->rx & 0xFF);
	lw	a4,0(a0)		# _20, uart_7(D)->rx
.L30:
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	lw	a5,8(a0)		# _15, uart_7(D)->status
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	andi	a5,a5,1	#, tmp158, _15
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	beq	a5,zero,.L30	#, tmp158,,
# ../uart/include/uart.h:43:     return (uint8_t)(uart->rx & 0xFF);
	lw	a3,0(a0)		# _17, uart_7(D)->rx
.L31:
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	lw	a5,8(a0)		# _12, uart_7(D)->status
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	andi	a5,a5,1	#, tmp159, _12
# ../uart/include/uart.h:42:     while (!(uart->status & UART_STATUS_RX_VALID));
	beq	a5,zero,.L31	#, tmp159,,
# ../uart/include/uart.h:43:     return (uint8_t)(uart->rx & 0xFF);
	lw	a2,0(a0)		# _14, uart_7(D)->rx
# ../uart/include/uart.h:57:     return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
	li	a0,65536		# tmp163,
	slli	a5,a4,8	#, tmp161, _20
	addi	a0,a0,-256	#, tmp163, tmp163
# ../uart/include/uart.h:57:     return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
	slli	a4,a2,24	#, tmp165, _14
	or	a4,a4,a1	# _24, tmp166, tmp165
# ../uart/include/uart.h:57:     return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
	and	a5,a5,a0	# tmp163, tmp162, tmp161
# ../uart/include/uart.h:57:     return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
	or	a5,a5,a4	# tmp166, tmp167, tmp162
# ../uart/include/uart.h:57:     return (b0) | (b1 << 8) | (b2 << 16) | (b3 << 24);
	slli	a0,a3,16	#, tmp168, _17
	li	a4,16711680		# tmp169,
	and	a0,a0,a4	# tmp169, tmp170, tmp168
# ../uart/include/uart.h:58: }
	or	a0,a5,a0	# tmp170,, tmp167
	ret	
	.size	uart_read_word, .-uart_read_word
	.globl	__umodsi3
	.globl	__udivsi3
	.align	2
	.globl	printuart_uint32
	.type	printuart_uint32, @function
printuart_uint32:
	addi	sp,sp,-48	#,,
	sw	s0,40(sp)	#,
	sw	ra,44(sp)	#,
	mv	s0,a0	# uart, tmp170
# ../uart/include/uart.h:66:     if (data == 0) {
	beq	a1,zero,.L42	#, data,,
	sw	s1,36(sp)	#,
	sw	s3,28(sp)	#,
	sw	s4,24(sp)	#,
	sw	s6,16(sp)	#,
	sw	s2,32(sp)	#,
	sw	s5,20(sp)	#,
	mv	s1,a1	# data, tmp171
	li	s3,0		# i,
	addi	s4,sp,4	#, tmp169,
	li	s6,9		# tmp167,
.L41:
# ../uart/include/uart.h:73:         buffer[i++] = (data % 10) + '0';
	li	a1,10		#,
	mv	a0,s1	#, data
	call	__umodsi3		#
# ../uart/include/uart.h:73:         buffer[i++] = (data % 10) + '0';
	addi	s3,s3,1	#, i, i
# ../uart/include/uart.h:73:         buffer[i++] = (data % 10) + '0';
	addi	a5,a0,48	#, tmp162, tmp172
	add	s2,s4,s3	# i, _29, tmp169
# ../uart/include/uart.h:74:         data /= 10;
	mv	a0,s1	#, data
	li	a1,10		#,
# ../uart/include/uart.h:73:         buffer[i++] = (data % 10) + '0';
	sb	a5,-1(s2)	# tmp162, MEM[(char *)_29 + 4294967295B]
	mv	s5,s1	# data, data
# ../uart/include/uart.h:74:         data /= 10;
	call	__udivsi3		#
	mv	s1,a0	# data, tmp173
# ../uart/include/uart.h:72:     while (data > 0) {
	bgtu	s5,s6,.L41	#, data, tmp167,
	mv	a4,s2	# ivtmp.62, _29
.L45:
# ../uart/include/uart.h:79:         uart_write_byte(uart, buffer[--i]);
	lbu	a3,-1(a4)	# _4, MEM[(char *)_7 + 4294967295B]
.L44:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _22, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp168, _22
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L44	#, tmp168,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a3,4(s0)	# _4, uart_15(D)->tx
# ../uart/include/uart.h:78:     while (i > 0) {
	addi	a4,a4,-1	#, ivtmp.62, ivtmp.62
	bne	s4,a4,.L45	#, tmp169, ivtmp.62,
# ../uart/include/uart.h:81: }
	lw	ra,44(sp)		#,
	lw	s0,40(sp)		#,
	lw	s1,36(sp)		#,
	lw	s2,32(sp)		#,
	lw	s3,28(sp)		#,
	lw	s4,24(sp)		#,
	lw	s5,20(sp)		#,
	lw	s6,16(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
.L42:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _20, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp152, _20
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L42	#, tmp152,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	li	a5,48		# tmp153,
# ../uart/include/uart.h:81: }
	lw	ra,44(sp)		#,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a5,4(s0)	# tmp153, uart_15(D)->tx
# ../uart/include/uart.h:81: }
	lw	s0,40(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
	.size	printuart_uint32, .-printuart_uint32
	.align	2
	.globl	printuart_uint16
	.type	printuart_uint16, @function
printuart_uint16:
	addi	sp,sp,-48	#,,
	sw	s0,40(sp)	#,
	sw	ra,44(sp)	#,
	mv	s0,a0	# uart, tmp170
# ../uart/include/uart.h:89:     if (data == 0) {
	beq	a1,zero,.L56	#, data,,
	sw	s1,36(sp)	#,
	sw	s3,28(sp)	#,
	sw	s4,24(sp)	#,
	sw	s6,16(sp)	#,
	sw	s2,32(sp)	#,
	sw	s5,20(sp)	#,
	mv	s1,a1	# data, tmp171
	li	s3,0		# i,
	addi	s4,sp,8	#, tmp169,
	li	s6,9		# tmp167,
.L55:
# ../uart/include/uart.h:96:         buffer[i++] = (data % 10) + '0';
	li	a1,10		#,
	mv	a0,s1	#, data
	call	__umodsi3		#
# ../uart/include/uart.h:96:         buffer[i++] = (data % 10) + '0';
	addi	s3,s3,1	#, i, i
# ../uart/include/uart.h:96:         buffer[i++] = (data % 10) + '0';
	addi	a5,a0,48	#, tmp162, tmp172
	add	s2,s4,s3	# i, _29, tmp169
# ../uart/include/uart.h:97:         data /= 10;
	mv	a0,s1	#, data
	li	a1,10		#,
# ../uart/include/uart.h:96:         buffer[i++] = (data % 10) + '0';
	sb	a5,-1(s2)	# tmp162, MEM[(char *)_29 + 4294967295B]
# ../uart/include/uart.h:97:         data /= 10;
	call	__udivsi3		#
	mv	s5,s1	# data, data
	slli	s1,a0,16	#, data, tmp173
	srli	s1,s1,16	#, data, data
# ../uart/include/uart.h:95:     while (data > 0) {
	bgtu	s5,s6,.L55	#, data, tmp167,
	mv	a4,s2	# ivtmp.76, _29
.L59:
# ../uart/include/uart.h:102:         uart_write_byte(uart, buffer[--i]);
	lbu	a3,-1(a4)	# _4, MEM[(char *)_7 + 4294967295B]
.L58:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _22, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp168, _22
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L58	#, tmp168,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a3,4(s0)	# _4, uart_15(D)->tx
# ../uart/include/uart.h:101:     while (i > 0) {
	addi	a4,a4,-1	#, ivtmp.76, ivtmp.76
	bne	s4,a4,.L59	#, tmp169, ivtmp.76,
# ../uart/include/uart.h:104: }
	lw	ra,44(sp)		#,
	lw	s0,40(sp)		#,
	lw	s1,36(sp)		#,
	lw	s2,32(sp)		#,
	lw	s3,28(sp)		#,
	lw	s4,24(sp)		#,
	lw	s5,20(sp)		#,
	lw	s6,16(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
.L56:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _20, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp152, _20
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L56	#, tmp152,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	li	a5,48		# tmp153,
# ../uart/include/uart.h:104: }
	lw	ra,44(sp)		#,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a5,4(s0)	# tmp153, uart_15(D)->tx
# ../uart/include/uart.h:104: }
	lw	s0,40(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
	.size	printuart_uint16, .-printuart_uint16
	.globl	__modsi3
	.globl	__divsi3
	.align	2
	.globl	printuart_int16
	.type	printuart_int16, @function
printuart_int16:
	addi	sp,sp,-48	#,,
	sw	s0,40(sp)	#,
	sw	s1,36(sp)	#,
	sw	ra,44(sp)	#,
	mv	s1,a1	# data, tmp191
	mv	s0,a0	# uart, tmp190
# ../uart/include/uart.h:109:     if (data < 0) {
	blt	a1,zero,.L70	#, data,,
# ../uart/include/uart.h:118:     if (data == 0) {
	bne	a1,zero,.L71	#, data,,
.L73:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _27, uart_17(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp160, _27
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L73	#, tmp160,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	li	a5,48		# tmp161,
# ../uart/include/uart.h:133: }
	lw	ra,44(sp)		#,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a5,4(s0)	# tmp161, uart_17(D)->tx
# ../uart/include/uart.h:133: }
	lw	s0,40(sp)		#,
	lw	s1,36(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
.L70:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _25, uart_17(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp156, _25
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L70	#, tmp156,,
# ../uart/include/uart.h:111:         data = -data;
	neg	s1,s1	# tmp159, data
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	li	a5,45		# tmp157,
# ../uart/include/uart.h:111:         data = -data;
	slli	s1,s1,16	#, data, tmp159
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a5,4(s0)	# tmp157, uart_17(D)->tx
# ../uart/include/uart.h:111:         data = -data;
	srai	s1,s1,16	#, data, data
# ../uart/include/uart.h:124:     while (data > 0) {
	ble	s1,zero,.L68	#, data,,
.L71:
	sw	s3,28(sp)	#,
	sw	s4,24(sp)	#,
	sw	s6,16(sp)	#,
	sw	s2,32(sp)	#,
	sw	s5,20(sp)	#,
# ../uart/include/uart.h:107: {
	li	s3,0		# i,
	addi	s4,sp,8	#, tmp189,
# ../uart/include/uart.h:124:     while (data > 0) {
	li	s6,9		# tmp187,
.L75:
# ../uart/include/uart.h:125:         buffer[i++] = (data % 10) + '0';
	li	a1,10		#,
	mv	a0,s1	#, data
	call	__modsi3		#
# ../uart/include/uart.h:125:         buffer[i++] = (data % 10) + '0';
	addi	s3,s3,1	#, i, i
# ../uart/include/uart.h:125:         buffer[i++] = (data % 10) + '0';
	addi	a5,a0,48	#, tmp177, tmp192
	add	s2,s4,s3	# i, _10, tmp189
# ../uart/include/uart.h:126:         data /= 10;
	mv	a0,s1	#, data
	li	a1,10		#,
# ../uart/include/uart.h:125:         buffer[i++] = (data % 10) + '0';
	sb	a5,-1(s2)	# tmp177, MEM[(char *)_10 + 4294967295B]
# ../uart/include/uart.h:126:         data /= 10;
	call	__divsi3		#
	mv	s5,s1	# data, data
	slli	s1,a0,16	#, data, tmp193
	srai	s1,s1,16	#, data, data
# ../uart/include/uart.h:124:     while (data > 0) {
	bgt	s5,s6,.L75	#, data, tmp187,
	mv	a4,s2	# ivtmp.90, _10
.L78:
# ../uart/include/uart.h:131:         uart_write_byte(uart, buffer[--i]);
	lbu	a3,-1(a4)	# _6, MEM[(char *)_36 + 4294967295B]
.L77:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _29, uart_17(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp188, _29
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L77	#, tmp188,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a3,4(s0)	# _6, uart_17(D)->tx
# ../uart/include/uart.h:130:     while (i > 0) {
	addi	a4,a4,-1	#, ivtmp.90, ivtmp.90
	bne	s4,a4,.L78	#, tmp189, ivtmp.90,
	lw	s2,32(sp)		#,
	lw	s3,28(sp)		#,
	lw	s4,24(sp)		#,
	lw	s5,20(sp)		#,
	lw	s6,16(sp)		#,
.L68:
# ../uart/include/uart.h:133: }
	lw	ra,44(sp)		#,
	lw	s0,40(sp)		#,
	lw	s1,36(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
	.size	printuart_int16, .-printuart_int16
	.align	2
	.globl	printuart_int32
	.type	printuart_int32, @function
printuart_int32:
	addi	sp,sp,-48	#,,
	sw	s0,40(sp)	#,
	sw	s1,36(sp)	#,
	sw	ra,44(sp)	#,
	mv	s1,a1	# data, tmp183
	mv	s0,a0	# uart, tmp182
# ../uart/include/uart.h:138:     if (data < 0) {
	blt	a1,zero,.L101	#, data,,
# ../uart/include/uart.h:147:     if (data == 0) {
	bne	a1,zero,.L100	#, data,,
.L89:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _25, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp155, _25
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L89	#, tmp155,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	li	a5,48		# tmp156,
# ../uart/include/uart.h:162: }
	lw	ra,44(sp)		#,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a5,4(s0)	# tmp156, uart_15(D)->tx
# ../uart/include/uart.h:162: }
	lw	s0,40(sp)		#,
	lw	s1,36(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
.L101:
	sw	s2,32(sp)	#,
	sw	s3,28(sp)	#,
	sw	s4,24(sp)	#,
.L87:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _23, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp153, _23
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L87	#, tmp153,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	li	a5,45		# tmp154,
	sw	a5,4(s0)	# tmp154, uart_15(D)->tx
# ../uart/include/uart.h:140:         data = -data;
	neg	s1,s1	# data, data
.L88:
# ../uart/include/uart.h:136: {
	li	s3,0		# i,
	addi	s4,sp,4	#, tmp181,
.L91:
# ../uart/include/uart.h:154:         buffer[i++] = (data % 10) + '0';
	li	a1,10		#,
	mv	a0,s1	#, data
	call	__modsi3		#
# ../uart/include/uart.h:154:         buffer[i++] = (data % 10) + '0';
	addi	s3,s3,1	#, i, i
# ../uart/include/uart.h:154:         buffer[i++] = (data % 10) + '0';
	addi	a5,a0,48	#, tmp171, tmp184
	add	s2,s4,s3	# i, _7, tmp181
# ../uart/include/uart.h:155:         data /= 10;
	mv	a0,s1	#, data
	li	a1,10		#,
# ../uart/include/uart.h:154:         buffer[i++] = (data % 10) + '0';
	sb	a5,-1(s2)	# tmp171, MEM[(char *)_7 + 4294967295B]
# ../uart/include/uart.h:155:         data /= 10;
	call	__divsi3		#
	mv	s1,a0	# data, tmp185
# ../uart/include/uart.h:153:     while (data > 0) {
	bne	a0,zero,.L91	#, data,,
	mv	a4,s2	# ivtmp.104, _7
.L93:
# ../uart/include/uart.h:160:         uart_write_byte(uart, buffer[--i]);
	lbu	a3,-1(a4)	# _4, MEM[(char *)_33 + 4294967295B]
.L92:
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s0)		# _27, uart_15(D)->status
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp180, _27
# ../uart/include/uart.h:47:     while(uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L92	#, tmp180,,
# ../uart/include/uart.h:48:     uart->tx = (uint32_t)data;
	sw	a3,4(s0)	# _4, uart_15(D)->tx
# ../uart/include/uart.h:159:     while (i > 0) {
	addi	a4,a4,-1	#, ivtmp.104, ivtmp.104
	bne	s4,a4,.L93	#, tmp181, ivtmp.104,
# ../uart/include/uart.h:162: }
	lw	ra,44(sp)		#,
	lw	s0,40(sp)		#,
	lw	s2,32(sp)		#,
	lw	s3,28(sp)		#,
	lw	s4,24(sp)		#,
	lw	s1,36(sp)		#,
	addi	sp,sp,48	#,,
	jr	ra		#
.L100:
	sw	s2,32(sp)	#,
	sw	s3,28(sp)	#,
	sw	s4,24(sp)	#,
	j	.L88		#
	.size	printuart_int32, .-printuart_int32
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-1072	#,,
	sw	s6,1040(sp)	#,
	sw	s7,1036(sp)	#,
# src/main.c:18:         if(audioIO_get_avail_samples(AUDIO_IO, 0) == 256){
	li	s6,8192		# tmp175,
# src/main.c:40:             audioIO_copy_grain(AUDIO_IO, (uint32_t)sample_buffer_r, 256, AUDIOIO_CHANNEL_RIGHT);
	addi	s7,sp,512	#, _115,
# src/main.c:14: int main(){
	sw	s0,1064(sp)	#,
	sw	s1,1060(sp)	#,
	sw	s3,1052(sp)	#,
	sw	s4,1048(sp)	#,
	sw	s5,1044(sp)	#,
	sw	ra,1068(sp)	#,
	sw	s2,1056(sp)	#,
	sw	s8,1032(sp)	#,
	sw	s9,1028(sp)	#,
	mv	s1,s7	# _26, _115
# ../audioIO/include/audio_io.h:51:         return (audio_io->status & STATUS_AVAIL_SAMPLE_L) >> 3; 
	li	s3,172032		# tmp173,
# src/main.c:18:         if(audioIO_get_avail_samples(AUDIO_IO, 0) == 256){
	addi	s6,s6,-8	#, tmp175, tmp175
# ../audioIO/include/audio_io.h:40:     audio_io->num_samples = num_samples;
	li	s5,256		# tmp276,
# ../audioIO/include/audio_io.h:42:     audio_io->ctrl = ctrl_val | CONTROL_START;
	li	s4,1		# tmp277,
# ../uart/include/uart.h:24:     uart->tx = (uint32_t)c;
	li	s0,10		# tmp279,
.L116:
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	li	s8,163840		# tmp278,
# ../apu/include/apu.h:121:     return !(apu->status & APU_STATUS_READY);
	li	s2,176128		# tmp281,
	j	.L111		#
.L103:
# ../audioIO/include/audio_io.h:53:         return (audio_io->status & STATUS_AVAIL_SAMPLE_R) >> 13;
	lw	a5,0(s3)		# _43, MEM[(struct audio_io_t *)172032B].status
# src/main.c:39:         if(audioIO_get_avail_samples(AUDIO_IO, 1) == 256){
	li	a3,8380416		# tmp231,
	li	a4,2097152		# tmp233,
	and	a5,a5,a3	# tmp231, tmp232, _43
	beq	a5,a4,.L136	#, tmp232, tmp233,
.L111:
# ../audioIO/include/audio_io.h:51:         return (audio_io->status & STATUS_AVAIL_SAMPLE_L) >> 3; 
	lw	a5,0(s3)		# _19, MEM[(struct audio_io_t *)172032B].status
# src/main.c:18:         if(audioIO_get_avail_samples(AUDIO_IO, 0) == 256){
	and	a5,a5,s6	# tmp175, tmp174, _19
	addi	a5,a5,-2048	#, tmp177, tmp174
	bne	a5,zero,.L103	#, tmp177,,
# ../audioIO/include/audio_io.h:39:     audio_io->base_addr = base_address; 
	sw	sp,8(s3)	#, MEM[(struct audio_io_t *)172032B].base_addr
# ../audioIO/include/audio_io.h:40:     audio_io->num_samples = num_samples;
	sw	s5,12(s3)	# tmp276, MEM[(struct audio_io_t *)172032B].num_samples
# ../audioIO/include/audio_io.h:42:     audio_io->ctrl = ctrl_val | CONTROL_START;
	sw	s4,4(s3)	# tmp277, MEM[(struct audio_io_t *)172032B].ctrl
# ../audioIO/include/audio_io.h:44:     audio_io->ctrl = ctrl_val;
	sw	zero,4(s3)	#, MEM[(struct audio_io_t *)172032B].ctrl
.L104:
# ../audioIO/include/audio_io.h:46:     while((audio_io->status & STATUS_FINISHED)){}
	lw	a5,0(s3)		# _21, MEM[(struct audio_io_t *)172032B].status
# ../audioIO/include/audio_io.h:46:     while((audio_io->status & STATUS_FINISHED)){}
	andi	a5,a5,1	#, tmp185, _21
# ../audioIO/include/audio_io.h:46:     while((audio_io->status & STATUS_FINISHED)){}
	bne	a5,zero,.L104	#, tmp185,,
.L105:
# ../audioIO/include/audio_io.h:47:     while(!(audio_io->status & STATUS_FINISHED)){}
	lw	a5,0(s3)		# _23, MEM[(struct audio_io_t *)172032B].status
# ../audioIO/include/audio_io.h:47:     while(!(audio_io->status & STATUS_FINISHED)){}
	andi	a5,a5,1	#, tmp187, _23
# ../audioIO/include/audio_io.h:47:     while(!(audio_io->status & STATUS_FINISHED)){}
	beq	a5,zero,.L105	#, tmp187,,
	mv	s9,sp	# ivtmp.119,
.L107:
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s8)		# _33, MEM[(struct uart_t *)163840B].status
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp189, _33
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L107	#, tmp189,,
# ../uart/include/uart.h:24:     uart->tx = (uint32_t)c;
	sw	s0,4(s8)	# tmp279, MEM[(struct uart_t *)163840B].tx
# src/main.c:22:                 printuart_int16(UART, sample_buffer_l[i]);
	lh	a1,0(s9)		#, MEM[(long unsigned int *)_109]
	li	a0,163840		#,
	call	printuart_int16		#
.L108:
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	lw	a5,8(s8)		# _27, MEM[(struct uart_t *)163840B].status
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	andi	a5,a5,8	#, tmp195, _27
# ../uart/include/uart.h:22:     while (uart->status & UART_STATUS_TX_FULL);
	bne	a5,zero,.L108	#, tmp195,,
# ../uart/include/uart.h:24:     uart->tx = (uint32_t)c;
	sw	s0,4(s8)	# tmp279, MEM[(struct uart_t *)163840B].tx
# src/main.c:24:                 printuart_int16(UART, sample_buffer_l[i] >> 16);
	lh	a1,2(s9)		#, MEM[(long unsigned int *)_109]
	li	a0,163840		#,
# src/main.c:20:             for(int i = 0; i < 128; i++){
	addi	s9,s9,4	#, ivtmp.119, ivtmp.119
# src/main.c:24:                 printuart_int16(UART, sample_buffer_l[i] >> 16);
	call	printuart_int16		#
# src/main.c:20:             for(int i = 0; i < 128; i++){
	bne	s1,s9,.L107	#, _26, ivtmp.119,
.L109:
# ../apu/include/apu.h:121:     return !(apu->status & APU_STATUS_READY);
	lw	a5,0(s2)		# _40, MEM[(struct apu_t *)176128B].status
# ../apu/include/apu.h:133:     while(!apu_ready(apu));
	andi	a5,a5,1	#, tmp203, _40
	bne	a5,zero,.L109	#, tmp203,,
# ../apu/include/apu.h:103:     apu->opcode = APU_OPCODE_COPY;
	sw	zero,4(s2)	#, MEM[(struct apu_t *)176128B].opcode
# ../apu/include/apu.h:104:     apu->start_ram_address = origin_address;
	sw	sp,64(s2)	#, MEM[(struct apu_t *)176128B].start_ram_address
# ../apu/include/apu.h:105:     apu->start = buffer_start;
	sw	zero,72(s2)	#, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:106:     apu->block_size = buffer_size;
	li	a5,2		# tmp208,
	sw	a5,52(s2)	# tmp208, MEM[(struct apu_t *)176128B].block_size
# ../apu/include/apu.h:107:     apu->in_buffer1_offset = operation_size;
	sw	s5,12(s2)	# tmp276, MEM[(struct apu_t *)176128B].in_buffer1_offset
# ../apu/include/apu.h:108:     apu->in_buffer1_start = operation_start;
	sw	zero,8(s2)	#, MEM[(struct apu_t *)176128B].in_buffer1_start
# ../apu/include/apu.h:125:     apu->start = APU_START_BIT;
	sw	s4,72(s2)	# tmp277, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:129:     apu->start = 0;
	sw	zero,72(s2)	#, MEM[(struct apu_t *)176128B].start
.L110:
# ../apu/include/apu.h:121:     return !(apu->status & APU_STATUS_READY);
	lw	a5,0(s2)		# _37, MEM[(struct apu_t *)176128B].status
# ../apu/include/apu.h:133:     while(!apu_ready(apu));
	andi	a5,a5,1	#, tmp217, _37
	bne	a5,zero,.L110	#, tmp217,,
# ../apu/include/apu.h:112:     apu->opcode = APU_OPCODE_AUDIO_OUT;
	sw	s4,4(s2)	# tmp277, MEM[(struct apu_t *)176128B].opcode
# ../apu/include/apu.h:113:     apu->start = buffer_start;
	sw	zero,72(s2)	#, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:114:     apu->block_size = buffer_size;
	li	a5,2		# tmp222,
	sw	a5,52(s2)	# tmp222, MEM[(struct apu_t *)176128B].block_size
# ../apu/include/apu.h:115:     apu->in_buffer1_offset = operation_size;
	sw	s5,12(s2)	# tmp276, MEM[(struct apu_t *)176128B].in_buffer1_offset
# ../apu/include/apu.h:116:     apu->in_buffer1_start = operation_start;
	sw	zero,8(s2)	#, MEM[(struct apu_t *)176128B].in_buffer1_start
# ../apu/include/apu.h:117:     apu->left_right = lr;
	sw	zero,68(s2)	#, MEM[(struct apu_t *)176128B].left_right
# ../apu/include/apu.h:125:     apu->start = APU_START_BIT;
	sw	s4,72(s2)	# tmp277, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:129:     apu->start = 0;
	sw	zero,72(s2)	#, MEM[(struct apu_t *)176128B].start
# ../audioIO/include/audio_io.h:53:         return (audio_io->status & STATUS_AVAIL_SAMPLE_R) >> 13;
	lw	a5,0(s3)		# _43, MEM[(struct audio_io_t *)172032B].status
# src/main.c:39:         if(audioIO_get_avail_samples(AUDIO_IO, 1) == 256){
	li	a3,8380416		# tmp231,
	li	a4,2097152		# tmp233,
	and	a5,a5,a3	# tmp231, tmp232, _43
	bne	a5,a4,.L111	#, tmp232, tmp233,
.L136:
# ../audioIO/include/audio_io.h:39:     audio_io->base_addr = base_address; 
	sw	s7,8(s3)	# _115, MEM[(struct audio_io_t *)172032B].base_addr
# ../audioIO/include/audio_io.h:40:     audio_io->num_samples = num_samples;
	sw	s5,12(s3)	# tmp276, MEM[(struct audio_io_t *)172032B].num_samples
# ../audioIO/include/audio_io.h:42:     audio_io->ctrl = ctrl_val | CONTROL_START;
	li	a5,3		# tmp238,
	sw	a5,4(s3)	# tmp238, MEM[(struct audio_io_t *)172032B].ctrl
# ../audioIO/include/audio_io.h:44:     audio_io->ctrl = ctrl_val;
	li	a5,2		# tmp240,
	sw	a5,4(s3)	# tmp240, MEM[(struct audio_io_t *)172032B].ctrl
.L112:
# ../audioIO/include/audio_io.h:46:     while((audio_io->status & STATUS_FINISHED)){}
	lw	a5,0(s3)		# _50, MEM[(struct audio_io_t *)172032B].status
# ../audioIO/include/audio_io.h:46:     while((audio_io->status & STATUS_FINISHED)){}
	andi	a5,a5,1	#, tmp242, _50
# ../audioIO/include/audio_io.h:46:     while((audio_io->status & STATUS_FINISHED)){}
	bne	a5,zero,.L112	#, tmp242,,
.L113:
# ../audioIO/include/audio_io.h:47:     while(!(audio_io->status & STATUS_FINISHED)){}
	lw	a5,0(s3)		# _52, MEM[(struct audio_io_t *)172032B].status
# ../audioIO/include/audio_io.h:47:     while(!(audio_io->status & STATUS_FINISHED)){}
	andi	a5,a5,1	#, tmp244, _52
# ../audioIO/include/audio_io.h:47:     while(!(audio_io->status & STATUS_FINISHED)){}
	beq	a5,zero,.L113	#, tmp244,,
# ../apu/include/apu.h:121:     return !(apu->status & APU_STATUS_READY);
	li	a5,176128		# tmp245,
.L114:
	lw	a4,0(a5)		# _47, MEM[(struct apu_t *)176128B].status
# ../apu/include/apu.h:133:     while(!apu_ready(apu));
	andi	a4,a4,1	#, tmp247, _47
	bne	a4,zero,.L114	#, tmp247,,
# ../apu/include/apu.h:103:     apu->opcode = APU_OPCODE_COPY;
	sw	zero,4(a5)	#, MEM[(struct apu_t *)176128B].opcode
# ../apu/include/apu.h:104:     apu->start_ram_address = origin_address;
	sw	sp,64(a5)	#, MEM[(struct apu_t *)176128B].start_ram_address
# ../apu/include/apu.h:105:     apu->start = buffer_start;
	sw	zero,72(a5)	#, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:106:     apu->block_size = buffer_size;
	li	a4,2		# tmp252,
	sw	a4,52(a5)	# tmp252, MEM[(struct apu_t *)176128B].block_size
# ../apu/include/apu.h:107:     apu->in_buffer1_offset = operation_size;
	sw	s5,12(a5)	# tmp276, MEM[(struct apu_t *)176128B].in_buffer1_offset
# ../apu/include/apu.h:108:     apu->in_buffer1_start = operation_start;
	sw	zero,8(a5)	#, MEM[(struct apu_t *)176128B].in_buffer1_start
# ../apu/include/apu.h:125:     apu->start = APU_START_BIT;
	sw	s4,72(a5)	# tmp277, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:129:     apu->start = 0;
	sw	zero,72(a5)	#, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:121:     return !(apu->status & APU_STATUS_READY);
	li	a5,176128		# tmp259,
.L115:
	lw	a4,0(a5)		# _44, MEM[(struct apu_t *)176128B].status
# ../apu/include/apu.h:133:     while(!apu_ready(apu));
	andi	a4,a4,1	#, tmp261, _44
	bne	a4,zero,.L115	#, tmp261,,
# ../apu/include/apu.h:112:     apu->opcode = APU_OPCODE_AUDIO_OUT;
	sw	s4,4(a5)	# tmp277, MEM[(struct apu_t *)176128B].opcode
# ../apu/include/apu.h:113:     apu->start = buffer_start;
	sw	zero,72(a5)	#, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:114:     apu->block_size = buffer_size;
	li	a4,2		# tmp266,
	sw	a4,52(a5)	# tmp266, MEM[(struct apu_t *)176128B].block_size
# ../apu/include/apu.h:115:     apu->in_buffer1_offset = operation_size;
	sw	s5,12(a5)	# tmp276, MEM[(struct apu_t *)176128B].in_buffer1_offset
# ../apu/include/apu.h:116:     apu->in_buffer1_start = operation_start;
	sw	zero,8(a5)	#, MEM[(struct apu_t *)176128B].in_buffer1_start
# ../apu/include/apu.h:117:     apu->left_right = lr;
	sw	s4,68(a5)	# tmp277, MEM[(struct apu_t *)176128B].left_right
# ../apu/include/apu.h:125:     apu->start = APU_START_BIT;
	sw	s4,72(a5)	# tmp277, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:129:     apu->start = 0;
	sw	zero,72(a5)	#, MEM[(struct apu_t *)176128B].start
# ../apu/include/apu.h:130: }
	j	.L116		#
	.size	main, .-main
	.ident	"GCC: (13.2.0-11ubuntu1+12) 13.2.0"
