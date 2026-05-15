----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/15/2026 05:42:15 PM
-- Design Name: 
-- Module Name: circular_audio_buffer_out - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.audioIO_types.all;

entity circular_channel_buffer_out is
    Port (
        clk             : in  std_logic;
        rst             : in  std_logic;

        new_pair_in     : in  std_logic; 
        sample_pair_in  : in  std_logic_vector(31 downto 0);

        read_sample     : in  std_logic; 
        sample_out      : out std_logic_vector(15 downto 0)
    );
end circular_channel_buffer_out;

architecture RTL of circular_channel_buffer_out is
    signal circ_reg  : aio_internal_regs_t := (others => (others => '0'));
    signal w_ptr     : integer range 0 to DEPTH-1 := 0;
    signal r_ptr     : integer range 0 to DEPTH-1 := 0;
    signal occupancy : integer range 0 to DEPTH := 0;
begin

    
    sample_out <= circ_reg(r_ptr);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                w_ptr <= 0;
                r_ptr <= 0;
                occupancy <= 0;
            else
                if new_pair_in = '1' and occupancy <= (DEPTH - 2) then

                    circ_reg(w_ptr) <= sample_pair_in(15 downto 0);
                    circ_reg((w_ptr + 1) mod DEPTH) <= sample_pair_in(31 downto 16);
                    
                    w_ptr <= (w_ptr + 2) mod DEPTH;
                    

                    if read_sample = '1' and occupancy > 0 then
                        occupancy <= occupancy + 1; --if concurrent read
                    else
                        occupancy <= occupancy + 2;
                    end if;
                
                elsif read_sample = '1' and occupancy > 0 then
                    r_ptr <= (r_ptr + 1) mod DEPTH;
                    occupancy <= occupancy - 1;
                end if;
            end if;
        end if;
    end process;
end RTL;
