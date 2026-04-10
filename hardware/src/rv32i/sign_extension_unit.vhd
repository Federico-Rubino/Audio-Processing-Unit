----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 09:05:47 PM
-- Design Name: 
-- Module Name: sign_extension_unit - Behavioral
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

entity sign_extension_unit is
  Port (
    instr :  in std_logic_vector(31 downto 0);
    opcode : in std_logic_vector(6 downto 0);
    immediate_extended : out std_logic_vector(31 downto 0)
  );
end sign_extension_unit;

architecture Behavioral of sign_extension_unit is
begin
process(instr, opcode)
begin
    if opcode = OP_LUI or opcode = OP_AUIPC then  -- U-type
        immediate_extended <= instr(31 downto 12) & x"000";
        
    elsif opcode = OP_ALUI then
        if instr(14 downto 20) = "001" or instr(14 downto 20) = "101" then -- SLLI, SRLI, SRAI
            immediate_extended <= x"000000" & "000" & instr(24 downto 20);
        else -- I-type standard
            immediate_extended <= std_logic_vector(resize(signed(instr(31 downto 20)), 32));
        end if; 
    
    elsif opcode = OP_LOAD or opcode = OP_JALR then  -- I-type
        immediate_extended <= std_logic_vector(resize(signed(instr(31 downto 20)), 32));
        
    elsif opcode = OP_STORE then  -- S-type
        immediate_extended <= std_logic_vector(resize(signed(instr(31 downto 25)&instr(11 downto 7)),32));
        
    elsif opcode = OP_JAL then    -- J-type
        immediate_extended <= std_logic_vector(resize(signed(instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0'), 32));
        
    elsif opcode = OP_BRANCH then -- B-type
        immediate_extended <= std_logic_vector(resize(signed(instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0'), 32));
    else
        immediate_extended <= (others => '0');
    end if;
        


end process;


end Behavioral;
