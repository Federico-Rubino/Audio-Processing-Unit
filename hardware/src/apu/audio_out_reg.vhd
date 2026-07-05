library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AudioOutReg is
    Port (
        clk, enable : in std_logic;
        sample1, sample2 : in std_logic_vector(15 downto 0);
        lr : in std_logic;
        audio_out : out std_logic_vector(31 downto 0);
        lr_out : out std_logic;
        enable_out : out std_logic
    );
end AudioOutReg;

architecture Behavioral of AudioOutReg is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            audio_out <= sample2 & sample1;
            lr_out <= lr;
            enable_out <= enable;
        end if;
    end process;

end Behavioral;
