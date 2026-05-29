library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.apu_internal_pkg.all;

entity MemorySamplesMux is
    Port (
        samples : in logic_aoa(109 downto 0)(31 downto 0);
        index : in std_logic_vector(7 downto 0);
        sample1 : out std_logic_vector(15 downto 0);
        sample2 : out std_logic_vector(15 downto 0)
    );
end MemorySamplesMux;

architecture Behavioral of MemorySamplesMux is
begin

    process(samples, index)
    begin
        sample1 <= samples(to_integer(unsigned(index)))(15 downto 0);
        sample2 <= samples(to_integer(unsigned(index)))(31 downto 16);
    end process;

end Behavioral;