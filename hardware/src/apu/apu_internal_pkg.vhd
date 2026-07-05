library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package apu_internal_pkg is
    type logic_aoa is array (natural range <>) of std_logic_vector;
    constant broadcast : std_logic_vector(7 downto 0) := (others => '1');
    
end package;
