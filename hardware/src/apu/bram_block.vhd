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
    signal ram_block : logic_aoa(1023 downto 0)(31 downto 0) := (others => (others => '0'));
    signal index_signal : std_logic_vector(7 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            index_signal <= std_logic_vector(to_unsigned(index, 8));

            if (select_a = index_signal) or (select_a = broadcast) then
                -- Port A
                if we_a = '1' then
                    ram_block(to_integer(unsigned(addr_a))) <= data_in_a;
                end if;
                
                if rst = '0' then
                    data_out_a <= (others => '0');
                else
                    data_out_a <= ram_block(to_integer(unsigned(addr_a)));
                end if;
            end if;

            if (select_b = index_signal) or (select_b = broadcast) then
                -- Port B
                if we_b = '1' then
                    ram_block(to_integer(unsigned(addr_b))) <= data_in_b;
                end if;
                
                if rst = '0' then
                    data_out_b <= (others => '0');
                else
                    data_out_b <= ram_block(to_integer(unsigned(addr_b)));
                end if;
            end if;
        end if;
    end process;

end Behavioral;