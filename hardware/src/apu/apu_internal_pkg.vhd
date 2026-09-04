library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package apu_internal_pkg is

    -- Vector Unit Operations
    constant VEC_OP_WIDTH : integer := 3;
    subtype vec_op_t is std_logic_vector(VEC_OP_WIDTH-1 downto 0);

    constant VEC_OP_ADDS  : vec_op_t := "000";  -- Addition with scalar
    constant VEC_OP_ADDV  : vec_op_t := "001";  -- Addition with vector
    constant VEC_OP_SUBS  : vec_op_t := "010";  -- Subtraction with scalar
    constant VEC_OP_SUBV  : vec_op_t := "011";  -- Subtraction with vector
    constant VEC_OP_MULS  : vec_op_t := "100";  -- Multiplication with scalar
    constant VEC_OP_MULV  : vec_op_t := "101";  -- Multiplication with vector
    constant VEC_OP_MULCV : vec_op_t := "110";  -- Complex multiplication with vector

    -- Unit Selection
    constant APU_UNIT_WIDTH : integer := 3;
    subtype apu_unit_t is std_logic_vector(APU_UNIT_WIDTH-1 downto 0);

    constant APU_UNIT_NONE      : apu_unit_t := "000";
    constant APU_UNIT_AUDIO_IN  : apu_unit_t := "001";
    constant APU_UNIT_AUDIO_OUT : apu_unit_t := "010";
    constant APU_UNIT_FFT       : apu_unit_t := "011";
    constant APU_UNIT_VEC       : apu_unit_t := "100";
    constant APU_UNIT_PITCH     : apu_unit_t := "101";
    constant APU_UNIT_LOAD      : apu_unit_t := "110";

    -- Utilities
    type logic_aoa is array (natural range <>) of std_logic_vector;
    constant broadcast : std_logic_vector(7 downto 0) := (others => '1');
    
end package;
