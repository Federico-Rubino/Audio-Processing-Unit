library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package apu_internal_pkg is
    type logic_aoa is array (natural range <>) of std_logic_vector;
    type datapath_config is (double_read, mixed, double_write);
end package;
