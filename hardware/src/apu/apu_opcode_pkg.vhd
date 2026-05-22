library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package apu_opcode_pkg is
    subtype apu_opcode_t is std_logic_vector(3 downto 0);
    
    constant APU_OP_COPY      : apu_opcode_t := "0000";
    constant APU_OP_AUDIO_OUT : apu_opcode_t := "0001";
    
end package;
