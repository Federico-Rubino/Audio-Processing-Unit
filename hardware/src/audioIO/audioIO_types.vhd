library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package audioIO_types is
    constant DEPTH : integer := 256;
    type aio_internal_regs_t is array (0 to DEPTH-1) of std_logic_vector(15 downto 0);
end package;

