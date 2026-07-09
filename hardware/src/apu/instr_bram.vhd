library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

-- Typically used with this addresses
-- 0-1023: shader code
-- 1024-1535: left channels values
-- 1536-2047: right channel values
entity InstrMemory is
    Port (
        clk, rst   : in  std_logic;
        
        we, en   : in  std_logic;
        addr     : in  std_logic_vector(10 downto 0);
        data_in  : in  std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
    );
end MemoryBlock;

architecture Behavioral of InstrMemory is
begin
    
    aram_block_inst: entity work.aram_instr_block
    port map(
        clka => clk,
        addra => addr,
        dina => data_in,
        wea(0) => we,
        douta => data_out,
        ena => en
    );

end Behavioral;
