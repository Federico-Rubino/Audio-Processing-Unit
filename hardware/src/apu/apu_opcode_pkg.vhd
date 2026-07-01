library IEEE;
use IEEE.STD_LOGIC_1164.all;

package apu_opcode_pkg is

    constant APU_OP_WIDTH : integer := 4;
    subtype apu_code_t is std_logic_vector(APU_OP_WIDTH-1 downto 0);

    constant APU_NOP            : apu_code_t := "0000";
    constant APU_OP_FFT         : apu_code_t := "0001";
    constant APU_OP_IFFT        : apu_code_t := "0010";
    constant APU_OP_ADD_VECTOR  : apu_code_t := "0011";
    constant APU_OP_ADD_SCALAR  : apu_code_t := "0100";
    constant APU_OP_SUB_VECTOR  : apu_code_t := "0101";
    constant APU_OP_SUB_SCALAR  : apu_code_t := "0110";
    constant APU_OP_MUL_VECTOR  : apu_code_t := "0111";
    constant APU_OP_MUL_SCALAR  : apu_code_t := "1000";
    constant APU_OP_PITCH_SHIFT : apu_code_t := "1001";
    constant APU_OP_FOND_FREQ   : apu_code_t := "1010";
    constant APU_OP_LOAD        : apu_code_t := "1011";
    constant APU_OP_AUDIO_IN    : apu_code_t := "1100";
    constant APU_OP_AUDIO_OUT   : apu_code_t := "1101";
    constant APU_OP_MULC_VECTOR : apu_code_t := "1110";
    constant APU_OP_STOP        : apu_code_t := "1111";
    
end package apu_opcode_pkg;