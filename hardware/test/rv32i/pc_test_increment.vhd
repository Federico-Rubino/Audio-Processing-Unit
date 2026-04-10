----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2026 03:17:10 PM
-- Design Name: 
-- Module Name: pc_test_increment - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pc_test_increment is
--  Port ( );
end pc_test_increment;

architecture test of pc_test_increment is
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';
    signal pc_out: unsigned(31 downto 0);
    signal pc_in: unsigned(31 downto 0):= (others => '0');
    signal dout: std_logic_vector(31 downto 0);
    signal pc_write_enable: std_logic := '1';
begin
    --instance PC
    pc: entity work.program_counter
        port map(
            clk => clk,
            pc_reset => reset,
            pc_in => pc_in,
            pc_write_enable => '1',
            pc_out => pc_out 
        );
        
     U_BRAM: entity work.instruction_memory
        port map (
            clka => clk,
            ena => '1',
            addra => std_logic_vector(pc_out(11 downto 2)),
            douta => dout
        );
        
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;
    
    pc_in <= pc_out + 4;

    
    stim_process: process
    begin
        reset <= '1';
        wait for 20ns;
        reset <= '0';
        wait;
        
    end process;


end test;
