----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 11:10:10 AM
-- Design Name: 
-- Module Name: alu - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.opcode_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alu is
    Port ( 
        alu_op : in alu_op_t;
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        result : out std_logic_vector(31 downto 0)
        );
end alu;

architecture Behavioral of alu is

begin

process(a,b, alu_op)
begin
    case alu_op is
        when OP_ALU_ADD => result <= std_logic_vector(signed(a)+signed(b));
        when OP_ALU_SUB => result <= std_logic_vector(signed(a)-signed(b));
        when OP_ALU_AND => result <= a and b;
        when OP_ALU_OR => result <=a or b;
        when OP_ALU_XOR => result <= a xor b;
        when OP_ALU_SLT => 
            if (signed(a) < signed(b)) then
                result <= (31 downto 1 => '0') & '1';
            else 
                result <= (others => '0');
            end if;
        when OP_ALU_SLTU =>
            if (unsigned(a) < unsigned(b)) then
                result <= (31 downto 1 => '0') & '1';
            else 
                result <= (others => '0');
            end if;
        when OP_ALU_SLL => result <= std_logic_vector(shift_left(unsigned(a), to_integer(unsigned(b(4 downto 0)))));
        when OP_ALU_SRL => result <= std_logic_vector(shift_right(unsigned(a), to_integer(unsigned(b(4 downto 0)))));
        when OP_ALU_SRA => result <= std_logic_vector(shift_right(signed(a), to_integer(unsigned(b(4 downto 0)))));
        when others =>
            result <= (others => '0');
    end case;
end process;

end Behavioral;
