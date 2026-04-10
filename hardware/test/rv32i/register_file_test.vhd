----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2026 06:04:25 PM
-- Design Name: 
-- Module Name: register_file_test - Behavioral
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

entity register_file_test is
--  Port ( );
end register_file_test;

architecture test of register_file_test is
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';
    signal wea: std_logic := '0';
    
    signal raddr1: unsigned (4 downto 0);
    signal rdata1: std_logic_vector (31 downto 0);
    
    signal raddr2: unsigned (4 downto 0);
    signal rdata2: std_logic_vector (31 downto 0);
    
    signal waddr: unsigned (4 downto 0);
    signal wdata: std_logic_vector (31 downto 0);
   
begin
    -- Instantiate the register file
    reg_instance: entity work.register_file
        port map(
            clk => clk,
            rst => reset,
            regwrite => wea,
            
            raddr1 => raddr1,
            rdata1 => rdata1,
            
            raddr2 => raddr2,
            rdata2 => rdata2,
            
            waddr => waddr,
            wdata => wdata
        );

    -- Clock generator
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;
    

    stim_process: process
    begin
        --reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;
        
        -- write 42 to register 1 (x1)
        wea <= '1';
        waddr <= "00001";   --x1
        wdata <= std_logic_vector(to_unsigned(42, 32));
        wait for 20 ns;
        
        -- try to write to x0
        waddr <= "00000"; --x0
        wdata <= std_logic_vector(to_unsigned(1234, 32));
        wait for 20 ns;
        
        -- write 99 to register 2 (x2)
        waddr <= "00010"; --x2
        wdata <= std_logic_vector(to_unsigned(99, 32));
        wait for 20 ns;
        
        wea <= '0';
        
        -- read back x0, x1, x2
        raddr1 <= "00000";  -- x0
        raddr2 <= "00001";  -- x1
        wait for 20 ns;
        
        raddr1 <= "00010";  -- x2
        raddr2 <= "00001";  -- x1 
        wait for 20 ns;
        
        -- write in x1 77
        wea <= '1';
        waddr <= "00001";
        wdata <= std_logic_vector(to_unsigned(77, 32));
        wait for 20 ns;
        wea <= '0';
        
        -- read x1
        raddr1 <= "00001";
        raddr2 <= "00010";
        wait for 20 ns;
        
        wait;
    end process;

end test;
