library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity MemoryBlock is
    Port (
        clk, rst   : in  std_logic;
        
        -- Port A Interface
        we_a       : in  std_logic;
        addr_a     : in  std_logic_vector(9 downto 0);
        data_in_a  : in  std_logic_vector(31 downto 0);
        data_out_a : out std_logic_vector(31 downto 0);
        
        -- Port B Interface
        we_b       : in  std_logic;
        addr_b     : in  std_logic_vector(9 downto 0);
        data_in_b  : in  std_logic_vector(31 downto 0);
        data_out_b : out std_logic_vector(31 downto 0)
    );
end MemoryBlock;

architecture Behavioral of MemoryBlock is
    signal ram_block : logic_aoa(1023 downto 0)(31 downto 0) := (others => (others => '0'));
begin

    -- Port A Process
    process(clk, rst)
    begin
        if rst = '0' then
            data_out_a <= (others => '0');
        elsif rising_edge(clk) then
            if we_a = '1' then
                ram_block(to_integer(unsigned(addr_a))) <= data_in_a;
            end if;
            data_out_a <= ram_block(to_integer(unsigned(addr_a)));
        end if;
    end process;

    -- Port B Process
    process(clk, rst)
    begin
        if rst = '0' then
            data_out_b <= (others => '0');
        elsif rising_edge(clk) then
            if we_b = '1' then
                ram_block(to_integer(unsigned(addr_b))) <= data_in_b;
            end if;
            data_out_b <= ram_block(to_integer(unsigned(addr_b)));
        end if;
    end process;

end Behavioral;