----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2026 05:40:03 PM
-- Design Name: 
-- Module Name: register_bank - Behavioral
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
use work.types_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity register_file is
    Port ( 
           clk : in std_logic;
           rst : in std_logic;
           
           raddr1 : in unsigned (4 downto 0);
           rdata1 : out std_logic_vector (31 downto 0);
           
           raddr2 : in unsigned (4 downto 0);
           rdata2 : out std_logic_vector (31 downto 0);
           
           waddr  : in unsigned (4 downto 0);
           wdata  : in std_logic_vector (31 downto 0);
           debug_regs : out std_logic_vector(1023 downto 0);
           regwrite : in std_logic
           
           
           );
end register_file;

architecture Behavioral of register_file is
    signal regs : reg_array_t := (others => (others => '0'));
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others =>(others => '0'));
            elsif regwrite = '1' and waddr /= "00000" then
                regs(TO_INTEGER(waddr)) <= wdata;
            end if;
        end if;
    end process;

    rdata1 <= regs(TO_INTEGER(raddr1));
    rdata2 <= regs(TO_INTEGER(raddr2));
    
    debug_regs <= regs(31) & regs(30) & regs(29) & regs(28) &
              regs(27) & regs(26) & regs(25) & regs(24) &
              regs(23) & regs(22) & regs(21) & regs(20) &
              regs(19) & regs(18) & regs(17) & regs(16) &
              regs(15) & regs(14) & regs(13) & regs(12) &
              regs(11) & regs(10) & regs(9)  & regs(8)  &
              regs(7)  & regs(6)  & regs(5)  & regs(4)  &
              regs(3)  & regs(2)  & regs(1)  & regs(0);

end Behavioral;
