library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity MemorySamplesMux is
    Port (
        clk, enable : in std_logic;
        samples : in logic_aoa(7 downto 0)(31 downto 0);
        index : in std_logic_vector(6 downto 0);
        sample1 : out std_logic_vector(15 downto 0);
        sample2 : out std_logic_vector(15 downto 0)
    );
end MemorySamplesMux;

architecture Behavioral of MemorySamplesMux is
begin

    process(clk)
    begin
        if rising_edge(clk) and enable = '1' then
            sample1 <= samples(to_integer(unsigned(index)))(15 downto 0);
            sample2 <= samples(to_integer(unsigned(index)))(31 downto 16);
        end if;
    end process;

end Behavioral;