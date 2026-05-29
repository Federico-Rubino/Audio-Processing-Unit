library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity MemoryBlock is
    Generic (
        index : integer
    );
    Port (
        clk, rst   : in  std_logic;
        
        -- Port A Interface
        we_a       : in  std_logic;
        addr_a     : in  std_logic_vector(9 downto 0);
        data_in_a  : in  std_logic_vector(31 downto 0);
        select_a   : in  std_logic_vector(7 downto 0);
        data_out_a : out std_logic_vector(31 downto 0);
        
        -- Port B Interface
        we_b       : in  std_logic;
        addr_b     : in  std_logic_vector(9 downto 0);
        data_in_b  : in  std_logic_vector(31 downto 0);
        select_b   : in  std_logic_vector(7 downto 0);
        data_out_b : out std_logic_vector(31 downto 0)
    );
end MemoryBlock;

architecture Behavioral of MemoryBlock is
    signal index_signal : std_logic_vector(7 downto 0);
    signal ena : std_logic := '0';
    signal enb : std_logic := '0';
begin
    
    aram_block_inst: entity work.aram_block
    port map(
        clka => clk,
        addra => addr_a,
        dina => data_in_a,
        wea(0) => we_a,
        douta => data_out_a,
        ena => ena,
        
        clkb => clk,
        addrb => addr_b,
        dinb => data_in_b,
        doutb => data_out_b,
        web(0) => we_b,
        enb => enb 
    );
    
    
    process(select_a, select_b)
    begin
        ena <= '0';
        enb <= '0';
        index_signal <= std_logic_vector(to_unsigned(index, 8));

        if (select_a = index_signal) or (select_a = broadcast) then
            -- Port A
            ena <= '1';
        end if;

        if (select_b = index_signal) or (select_b = broadcast) then
            -- Port B
            enb <= '1';
        end if;
    end process;

end Behavioral;