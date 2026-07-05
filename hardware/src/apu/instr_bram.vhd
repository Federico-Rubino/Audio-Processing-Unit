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
        
        -- Port A Interface
        we, en   : in  std_logic;
        addr     : in  std_logic_vector(10 downto 0);
        data_in  : in  std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        
        -- Port B Interface (TODO use it to increase bandwidth?)
        -- we_b       : in  std_logic;
        -- addr_b     : in  std_logic_vector(9 downto 0);
        -- data_in_b  : in  std_logic_vector(31 downto 0);
        -- select_b   : in  std_logic_vector(7 downto 0);
        -- data_out_b : out std_logic_vector(31 downto 0)
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
        ena => en,
        
        -- clkb => clk,
        -- addrb => addr_b,
        -- dinb => data_in_b,
        -- doutb => data_out_b,
        -- web(0) => we_b,
        -- enb => enb 
    );

end Behavioral;
