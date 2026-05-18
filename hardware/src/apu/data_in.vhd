library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DataIn is
    Port (
        data1, data2 : in std_logic_vector(15 downto 0);
        new_data_in : out std_logic_vector(31 downto 0)
    );
end DataIn;

architecture Behavioral of DataIn is
begin
    new_data_in <= data2 & data1;
end Behavioral;
