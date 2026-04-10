----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 03:50:11 PM
-- Design Name: 
-- Module Name: branch_unit - Behavioral
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

entity branch_unit is
  Port (
    branch : in std_logic;
    branch_op : in branch_op_t;
    a : in std_logic_vector(31 downto 0);
    b : in std_logic_vector(31 downto 0);
    take_branch : out std_logic := '0'
   );
end branch_unit;

architecture Behavioral of branch_unit is
begin

process(a, b, branch_op, branch)
begin

    take_branch <= '0';
    if branch = '1' then
        case branch_op is
    
            when OP_BRANCH_BEQ =>
                if a = b then
                    take_branch <= '1';
                end if;
            
            when OP_BRANCH_BNE =>
                if a /= b then
                    take_branch <= '1';
                end if;
            
            when OP_BRANCH_BLT =>
                if signed(a) < signed(b) then
                    take_branch <= '1';
                end if;
       
            when OP_BRANCH_BGE =>
                if signed(a) >= signed(b) then
                    take_branch <= '1';
                end if;
            
            when OP_BRANCH_BLTU =>
                if unsigned(a) < unsigned(b) then
                    take_branch <= '1';
                end if;
            
            when OP_BRANCH_BGEU =>
                if unsigned(a) >= unsigned(b) then
                    take_branch <= '1';
                end if;
            
            when OP_BRANCH_JAL_JALR => take_branch <= '1';
            
            when others => take_branch <= '0';
        

    end case;
end if;

end process;
end Behavioral;
