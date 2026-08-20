library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.apu_internal_pkg.all;

package vpu_internal_pkg is

    -- DSP array
    type data_array_t  is array (0 to 7) of std_logic_vector(15 downto 0);
    type dsp_op_sel_array_t is array (0 to 7) of std_logic_vector(1 downto 0);
    type dsp_p_array_t is array (0 to 7) of std_logic_vector(32 downto 0); --vpu_dsp's P output, 33 bits

    function decode_vec_op(vec_op : in vec_op_t) return dsp_op_sel_array_t;
    
end package;

package body vpu_internal_pkg is
    function decode_vec_op(vec_op : in vec_op_t) return dsp_op_sel_array_t is
        variable result : dsp_op_sel_array_t := (others => "00");    
    begin
        case vec_op is
            when VEC_OP_ADDS | VEC_OP_ADDV => 
                result := (others => "00");

            when VEC_OP_SUBS | VEC_OP_SUBV => 
                result := (others => "01");

            when VEC_OP_MULS | VEC_OP_MULV => 
                result := (others => "10");

            when VEC_OP_MULCV =>
                for i in result'range loop
                    if (i mod 2) = 0 then
                        result(i) := "00";  -- even, add the arguments
                    else
                        result(i) := "10";  -- odd, multiply the magnitude
                    end if;
            end loop;

            when others => return;
        end case;
    end function;

end package body;
