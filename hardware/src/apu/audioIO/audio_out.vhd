----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/15/2026 05:35:50 PM
-- Design Name: 
-- Module Name: audio_out - Behavioral
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

entity audio_out is
 Port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    new_sample      : in  std_logic; --from adau
    sample_out_l    : out std_logic_vector(15 downto 0);
    sample_out_r    : out std_logic_vector(15 downto 0);
    
    new_sample_pair : in  std_logic;
    sample_pair     : in  std_logic_vector(31 downto 0);
    channel_sel     : in  std_logic
 );
end audio_out;

architecture Behavioral of audio_out is
    signal new_pair_l : std_logic := '0';
    signal new_pair_r : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                new_pair_l <= '0';
                new_pair_r <= '0';
            else
                new_pair_l <= '0';
                new_pair_r <= '0';

                if new_sample_pair = '1' then
                    if channel_sel = '0' then --0 left, 1 right
                        new_pair_l <= '1';
                    else
                        new_pair_r <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    left_channel_buffer_out: entity work.circular_channel_buffer_out
        port map(
            clk            => clk,
            rst            => rst,
            new_pair_in    => new_pair_l,
            sample_pair_in => sample_pair, -- Data is shared, write pulse is unique
            read_sample    => new_sample,
            sample_out     => sample_out_l
        );
        
    right_channel_buffer_out: entity work.circular_channel_buffer_out
        port map(
            clk            => clk,
            rst            => rst,
            new_pair_in    => new_pair_r,
            sample_pair_in => sample_pair,
            read_sample    => new_sample,
            sample_out     => sample_out_r
        );

end Behavioral;
